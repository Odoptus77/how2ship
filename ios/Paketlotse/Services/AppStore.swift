import Foundation
import UIKit
import Observation
import PaketlotseCore

@MainActor
@Observable
final class AppStore {
    private(set) var catalog: TariffCatalog
    private(set) var catalogError: String?
    private(set) var bookings: [PendingBooking] = []
    private(set) var shipments: [Shipment] = []
    private(set) var savedParcels: [SavedParcel] = []

    /// Offene Buchung, für die gerade die Abfrage der Sendungsnummer angezeigt wird.
    var promptBooking: PendingBooking?

    let policy = TrackingPromptPolicy()
    @ObservationIgnored private let persistence = Persistence()
    @ObservationIgnored private let notifications = NotificationService()
    /// Tracking-Backend (deaktiviert, solange `API_BASE_URL` leer ist).
    @ObservationIgnored let api = TrackingAPI.fromInfoPlist()
    @ObservationIgnored private var isSyncing = false
    /// Letzter Fehler beim Abgleich mit dem Server (für einen dezenten Hinweis in der Liste).
    private(set) var syncError: String?
    @ObservationIgnored private var lastPromptedBookingID: UUID?

    init() {
        do {
            catalog = try TariffCatalog.bundledCurrent()
        } catch {
            catalog = TariffCatalog(version: "leer", validFrom: "–", isSample: true, tariffs: [])
            catalogError = "Tarifdaten konnten nicht geladen werden."
        }
        let stored = persistence.load()
        bookings = stored.bookings
        shipments = stored.shipments
        savedParcels = stored.savedParcels
    }

    // MARK: - Vergleich

    var engine: TariffEngine { TariffEngine(catalog: catalog) }

    /// Partnerlinks (Affiliate). Ohne eingetragene Partner-IDs bleiben alle Links normale Links.
    @ObservationIgnored let partnerLinks = PartnerLinkBuilder(
        config: (try? PartnerLinkConfig.bundled()) ?? PartnerLinkConfig(programs: [])
    )
    var advisor: SavingsAdvisor { SavingsAdvisor(engine: engine) }

    // MARK: - Listen

    var openBookings: [PendingBooking] {
        bookings.filter { $0.status == .open }.sorted { $0.clickedAt > $1.clickedAt }
    }

    var activeShipments: [Shipment] {
        shipments.filter { $0.status != .delivered }.sorted { $0.createdAt > $1.createdAt }
    }

    var deliveredShipments: [Shipment] {
        shipments.filter { $0.status == .delivered }.sorted { ($0.deliveredAt ?? $0.createdAt) > ($1.deliveredAt ?? $1.createdAt) }
    }

    // MARK: - Buchung → Abfrage der Sendungsnummer

    /// „Jetzt buchen“ getippt: Buchung merken und den Link (ggf. Partnerlink mit Klick-Referenz) liefern.
    /// Die Buchung selbst läuft extern (Carrier-App / Standardbrowser).
    func startBooking(for offer: Offer) -> URL? {
        let bookingID = UUID()
        guard let link = partnerLinks.bookingLink(for: offer.tariff, clickRef: Self.clickRef(for: bookingID)) else { return nil }
        let booking = PendingBooking(
            id: bookingID,
            tariffID: offer.tariff.id,
            carrier: offer.tariff.carrier,
            product: offer.tariff.product,
            priceCents: offer.priceCents,
            partnerProgramID: link.programID
        )
        bookings.append(booking)
        save()
        let policy = self.policy
        Task { await notifications.scheduleRemindersIfAuthorized(for: booking, policy: policy) }
        return link.url
    }

    /// Kurze, nicht personenbezogene Klick-Referenz, z. B. „pl-3F2A9C1B“.
    static func clickRef(for bookingID: UUID) -> String {
        "pl-" + bookingID.uuidString.prefix(8)
    }

    /// Aufruf, wenn die App in den Vordergrund kommt.
    func sceneDidBecomeActive(now: Date = .now) {
        expireOldBookings(now: now)
        guard promptBooking == nil,
              let candidate = openBookings.first(where: { policy.shouldPrompt($0, now: now) })
        else { return }
        update(candidate.id) { $0.promptShownAt = now }
        save()
        lastPromptedBookingID = candidate.id
        promptBooking = bookings.first { $0.id == candidate.id }
    }

    /// Aus Erinnerung oder Liste „Offene Buchungen“.
    func openPrompt(forBookingID id: UUID) {
        guard let booking = bookings.first(where: { $0.id == id && $0.status == .open }) else { return }
        lastPromptedBookingID = id
        promptBooking = booking
    }

    /// Abfrage geschlossen (wegwischen oder „Später erinnern“): Erinnerungen planen, falls noch offen.
    func promptDismissed() {
        guard let id = lastPromptedBookingID,
              let booking = bookings.first(where: { $0.id == id }),
              booking.status == .open
        else { return }
        let policy = self.policy
        Task {
            if await notifications.requestAuthorizationIfNeeded() {
                await notifications.scheduleReminders(for: booking, policy: policy)
            }
        }
    }

    /// Offene Buchung per Wischgeste entfernen (inkl. geplanter Erinnerungen).
    func deleteBooking(_ booking: PendingBooking) {
        bookings.removeAll { $0.id == booking.id }
        notifications.cancelReminders(for: booking.id)
        if promptBooking?.id == booking.id { promptBooking = nil }
        save()
    }

    func markNotBooked(_ booking: PendingBooking) {
        update(booking.id) { $0.status = .dismissed }
        notifications.cancelReminders(for: booking.id)
        promptBooking = nil
        save()
    }

    func captureTrackingNumber(_ raw: String, carrier: Carrier, name: String, booking: PendingBooking?) {
        let number = TrackingNumberDetector.normalize(raw)
        guard !number.isEmpty else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let shipment = Shipment(
            number: number,
            carrier: carrier,
            name: trimmedName.isEmpty ? nil : trimmedName,
            direction: booking == nil ? .incoming : .outgoing,
            bookingID: booking?.id
        )
        shipments.insert(shipment, at: 0)
        if let booking {
            update(booking.id) { $0.status = .numberCaptured }
            notifications.cancelReminders(for: booking.id)
        }
        promptBooking = nil
        save()
        Task {
            await registerOnServer(shipment.id)
            // Erst nach der ersten Sendung nach Push-Erlaubnis fragen (Konzept 4.2).
            if await notifications.requestAuthorizationIfNeeded() {
                await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }
            }
        }
    }

    func delete(_ shipment: Shipment) {
        shipments.removeAll { $0.id == shipment.id }
        save()
        if let serverID = shipment.serverID, api.isConfigured {
            Task { try? await api.delete(id: serverID) }
        }
    }

    // MARK: - Tracking-Backend

    /// Sendung beim Server anmelden und ersten Stand übernehmen. Fehler sind nicht fatal –
    /// beim nächsten Abgleich wird es erneut versucht.
    func registerOnServer(_ shipmentID: UUID) async {
        guard api.isConfigured,
              let shipment = shipments.first(where: { $0.id == shipmentID }),
              shipment.serverID == nil else { return }
        do {
            let dto = try await api.register(number: shipment.number, carrier: shipment.carrier, name: shipment.name)
            updateShipment(shipmentID) { $0.apply(dto) }
            syncError = nil
        } catch {
            syncError = error.localizedDescription
        }
    }

    /// Abgleich beim App-Start, bei Push und per „Ziehen zum Aktualisieren“.
    func syncWithServer() async {
        guard api.isConfigured, !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        // Noch nicht angemeldete Sendungen nachholen (z. B. offline erfasst).
        for shipment in shipments where shipment.serverID == nil && shipment.status != .delivered {
            await registerOnServer(shipment.id)
        }
        do {
            let remote = try await api.list()
            let byID = Dictionary(remote.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            for index in shipments.indices {
                guard let serverID = shipments[index].serverID else { continue }
                if let dto = byID[serverID] {
                    shipments[index].apply(dto)
                }
                // Fehlt die Sendung auf dem Server (dort nach 30 Tagen gelöscht), bleibt sie lokal erhalten.
            }
            save()
            syncError = nil
        } catch {
            syncError = error.localizedDescription
        }
    }

    /// Einzelne Sendung sofort beim Paketdienst nachfragen.
    func refresh(_ shipment: Shipment) async {
        guard api.isConfigured else { return }
        if shipment.serverID == nil { await registerOnServer(shipment.id) }
        guard let serverID = shipments.first(where: { $0.id == shipment.id })?.serverID else { return }
        do {
            let dto = try await api.refresh(id: serverID)
            updateShipment(shipment.id) { $0.apply(dto) }
            syncError = nil
        } catch {
            syncError = error.localizedDescription
        }
    }

    /// DSGVO: alle Daten dieses Geräts auf dem Server löschen. Lokale Sendungen bleiben erhalten,
    /// werden aber nicht mehr automatisch aktualisiert.
    func deleteServerData() async -> Bool {
        guard api.isConfigured else { return true }
        do {
            try await api.deleteDevice()
            DeviceCredentials.reset()
            for index in shipments.indices { shipments[index].serverID = nil }
            save()
            return true
        } catch {
            syncError = error.localizedDescription
            return false
        }
    }

    /// Push-Token von APNs an den Server melden.
    func updatePushToken(_ deviceToken: Data) {
        guard api.isConfigured else { return }
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        #if DEBUG
        let sandbox = true
        #else
        let sandbox = false
        #endif
        Task { try? await api.setPushToken(token, sandbox: sandbox) }
    }

    private func updateShipment(_ id: UUID, _ change: (inout Shipment) -> Void) {
        guard let index = shipments.firstIndex(where: { $0.id == id }) else { return }
        change(&shipments[index])
        save()
    }

    // MARK: - Premium: gespeicherte Größen, Versandverlauf

    func saveParcel(named name: String, _ parcel: ParcelDimensions) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        savedParcels.append(SavedParcel(name: trimmed.isEmpty ? "Meine Größe" : trimmed, parcel: parcel))
        save()
    }

    func deleteSavedParcel(_ saved: SavedParcel) {
        savedParcels.removeAll { $0.id == saved.id }
        save()
    }

    /// Gebuchte Sendungen mit erfasster Sendungsnummer, neueste zuerst.
    var shippingHistory: [PendingBooking] {
        bookings.filter { $0.status == .numberCaptured }.sorted { $0.clickedAt > $1.clickedAt }
    }

    /// Kostenübersicht je Jahr: (Jahr, Anzahl Pakete, Summe in Cent).
    func yearlyCosts(calendar: Calendar = .current) -> [(year: Int, count: Int, totalCents: Int)] {
        let grouped = Dictionary(grouping: shippingHistory) { calendar.component(.year, from: $0.clickedAt) }
        return grouped
            .map { year, items in (year: year, count: items.count, totalCents: items.compactMap(\.priceCents).reduce(0, +)) }
            .sorted { $0.year > $1.year }
    }

    /// Kostenlose Version: zugestellte Sendungen 30 Tage nach Zustellung entfernen. Premium behält alles.
    func purgeExpiredShipments(keepHistory: Bool, now: Date = .now) {
        guard !keepHistory else { return }
        let before = shipments.count
        shipments.removeAll { shipment in
            guard let deletion = shipment.deletionDate() else { return false }
            return deletion < now
        }
        if shipments.count != before { save() }
    }

    // MARK: - Intern

    private func expireOldBookings(now: Date) {
        var changed = false
        for index in bookings.indices where policy.isExpired(bookings[index], now: now) {
            bookings[index].status = .expired
            notifications.cancelReminders(for: bookings[index].id)
            changed = true
        }
        if changed { save() }
    }

    private func update(_ id: UUID, _ change: (inout PendingBooking) -> Void) {
        guard let index = bookings.firstIndex(where: { $0.id == id }) else { return }
        change(&bookings[index])
    }

    private func save() {
        persistence.save(AppData(bookings: bookings, shipments: shipments, savedParcels: savedParcels))
    }
}
