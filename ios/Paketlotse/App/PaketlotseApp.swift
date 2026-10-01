import SwiftUI
import UserNotifications

@main
struct PaketlotseApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appDelegate.store)
                .environment(appDelegate.purchases)
        }
    }
}

/// Hält den App-Zustand und öffnet die Abfrage der Sendungsnummer, wenn eine Erinnerung angetippt wird.
@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    let store = AppStore()
    let purchases = PurchaseManager()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        // Push-Token erneuern, falls Mitteilungen schon erlaubt sind (Token kann sich ändern).
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
            DispatchQueue.main.async { application.registerForRemoteNotifications() }
        }
        return true
    }

    private func syncFromPush() async {
        await store.syncWithServer()
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        store.updatePushToken(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Ohne Push-Entitlement (kostenloser Apple-Account) oder im Simulator – App funktioniert weiter ohne Push.
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        if userInfo["shipmentId"] != nil {
            // Push vom Tracking-Server angetippt → aktuellen Stand holen.
            await syncFromPush()
            return
        }
        guard let idString = userInfo[NotificationService.bookingIDKey] as? String,
              let bookingID = UUID(uuidString: idString) else { return }
        await MainActor.run {
            store.openPrompt(forBookingID: bookingID)
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        if notification.request.content.userInfo["shipmentId"] != nil {
            await syncFromPush()
        }
        return [.banner, .sound]
    }
}
