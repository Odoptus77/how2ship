import Foundation
import UserNotifications
import PaketlotseCore

/// Lokale Erinnerungen zur offenen Buchung (Konzept 4.2).
/// Die Erlaubnis wird erst angefragt, wenn sie gebraucht wird: bei „Später erinnern“
/// oder nach der ersten erfassten Sendungsnummer.
final class NotificationService {
    static let bookingIDKey = "bookingID"
    private static let maxReminders = 2

    private let center = UNUserNotificationCenter.current()

    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        default:
            return false
        }
    }

    func scheduleRemindersIfAuthorized(for booking: PendingBooking, policy: TrackingPromptPolicy) async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
        await scheduleReminders(for: booking, policy: policy)
    }

    /// Gleiche Kennungen je Buchung → erneutes Planen ersetzt statt zu verdoppeln.
    func scheduleReminders(for booking: PendingBooking, policy: TrackingPromptPolicy, now: Date = .now) async {
        let calendar = Calendar.current
        for (index, date) in policy.reminderDates(for: booking, calendar: calendar).enumerated() where date > now {
            let content = UNMutableNotificationContent()
            content.title = "Sendungsnummer hinzufügen?"
            content.body = "Dein \(booking.carrier.displayName)-Paket (\(booking.product)): Füge die Sendungsnummer hinzu und wir halten dich auf dem Laufenden."
            content.sound = .default
            content.userInfo = [Self.bookingIDKey: booking.id.uuidString]

            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: Self.identifier(booking.id, index), content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    func cancelReminders(for bookingID: UUID) {
        let identifiers = (0..<Self.maxReminders).map { Self.identifier(bookingID, $0) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private static func identifier(_ bookingID: UUID, _ index: Int) -> String {
        "booking-\(bookingID.uuidString)-\(index)"
    }
}
