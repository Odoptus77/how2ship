import Foundation
import Observation
import PaketlotseCore

@MainActor
@Observable
final class AppStore {
    private(set) var catalog: TariffCatalog
    private(set) var catalogError: String?
    private(set) var bookings: [PendingBooking] = []
    private(set) var shipments: [Shipment] = []

    /// Offene Buchung, für die gerade die Abfrage der Sendungsnummer angezeigt wird.
    var promptBooking: PendingBooking?

    let policy = TrackingPromptPolicy()
    @ObservationIgnored private let persistence = Persistence()
    @ObservationIgnored private let notifications = NotificationService()
    @ObservationIgnored private var lastPromptedBookingID: UUID?

    init() {
        do {
            catalog = try TariffCatalog.bundledSample()
        } catch {
            catalog = TariffCatalog(version: "leer", validFrom: "–", isSample: true, tariffs: [])
            catalogError = "Tarifdaten konnten nicht geladen werden."
        }
        let stored = persistence.load()
        bookings = stored.bookings
        shipments = stored.shipments
    }

    // MARK: - Vergleich

    var engine: TariffEngine { TariffEngine(catalog: catalog) }
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

    /// „Jetzt buchen“ getippt: Buchung merken. Die Buchung selbst läuft extern (Carrier-App / Standardbrowser).
    func startBooking(for offer: Offer) {
        let booking = PendingBooking(tariffID: offer.tariff.id, carrier: offer.tariff.carrier, product: offer.tariff.product)
        bookings.append(booking)
        save()
        let policy = self.policy
        Task { await notifications.scheduleRemindersIfAuthorized(for: booking, policy: policy) }
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
        // TODO: Sendung beim Paketlotse-Server registrieren (Tracking-Anbieter, Webhooks, Push).
        Task { await notifications.requestAuthorizationIfNeeded() }
    }

    func delete(_ shipment: Shipment) {
        shipments.removeAll { $0.id == shipment.id }
        save()
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
        persistence.save(AppData(bookings: bookings, shipments: shipments))
    }
}
