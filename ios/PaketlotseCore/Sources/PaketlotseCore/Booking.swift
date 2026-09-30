import Foundation

public enum BookingStatus: String, Codable, Sendable {
    case open
    case numberCaptured
    case dismissed
    case expired
}

/// Entsteht, wenn der Nutzer auf „Jetzt buchen“ tippt. Löst die Abfrage der Sendungsnummer aus.
public struct PendingBooking: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public var tariffID: String
    public var carrier: Carrier
    public var product: String
    /// Gesamtpreis zum Zeitpunkt der Buchung (für Versandverlauf und Kostenübersicht).
    public var priceCents: Int?
    public var clickedAt: Date
    public var status: BookingStatus
    /// Die Abfrage erscheint nur einmal automatisch; danach übernehmen Erinnerungen.
    public var promptShownAt: Date?

    public init(
        id: UUID = UUID(), tariffID: String, carrier: Carrier, product: String, priceCents: Int? = nil,
        clickedAt: Date = Date(), status: BookingStatus = .open, promptShownAt: Date? = nil
    ) {
        self.id = id
        self.tariffID = tariffID
        self.carrier = carrier
        self.product = product
        self.priceCents = priceCents
        self.clickedAt = clickedAt
        self.status = status
        self.promptShownAt = promptShownAt
    }
}

/// Regeln aus dem App-Konzept, Abschnitt 4.2.
public struct TrackingPromptPolicy: Sendable {
    /// Frühestens 60 s nach dem Klick fragen (kein versehentlicher Klick).
    public var minimumAway: TimeInterval = 60
    /// Nach 48 h verfällt die offene Buchung still.
    public var maximumAge: TimeInterval = 48 * 3600
    public var firstReminderDelay: TimeInterval = 2 * 3600
    public var morningReminderHour = 9

    public init() {}

    public func shouldPrompt(_ booking: PendingBooking, now: Date) -> Bool {
        let age = now.timeIntervalSince(booking.clickedAt)
        return booking.status == .open
            && booking.promptShownAt == nil
            && age >= minimumAway
            && age <= maximumAge
    }

    public func isExpired(_ booking: PendingBooking, now: Date) -> Bool {
        booking.status == .open && now.timeIntervalSince(booking.clickedAt) > maximumAge
    }

    /// Erinnerung nach 2 Stunden und am nächsten Morgen um 9 Uhr – danach keine mehr.
    public func reminderDates(for booking: PendingBooking, calendar: Calendar) -> [Date] {
        let first = booking.clickedAt.addingTimeInterval(firstReminderDelay)
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: booking.clickedAt),
              let morning = calendar.date(bySettingHour: morningReminderHour, minute: 0, second: 0, of: nextDay)
        else { return [first] }
        return morning > first ? [first, morning] : [first]
    }
}
