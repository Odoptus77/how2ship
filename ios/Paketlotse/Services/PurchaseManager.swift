import Foundation
import Observation
import StoreKit

/// Premium als Einmalkauf (Non-Consumable) über StoreKit 2.
///
/// - Produkt-ID muss mit App Store Connect bzw. `StoreKit/Paketlotse.storekit` übereinstimmen.
/// - Die Berechtigung wird aus `Transaction.currentEntitlements` gelesen (funktioniert auch offline,
///   StoreKit prüft die Signatur lokal). Der Cache in UserDefaults verhindert nur ein kurzes „Flackern“
///   beim App-Start und wird sofort durch die echte Prüfung ersetzt.
@MainActor
@Observable
final class PurchaseManager {
    static let premiumProductID = "de.paketlotse.app.premium"
    private static let cacheKey = "isPremiumCached"

    private(set) var premiumProduct: Product?
    private(set) var isPremium: Bool = UserDefaults.standard.bool(forKey: PurchaseManager.cacheKey)
    private(set) var isPurchasing = false
    private(set) var isLoadingProduct = false
    var errorMessage: String?

    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    /// Werbung nur in der kostenlosen Version (Werbe-SDK folgt).
    var showsAds: Bool { !isPremium }

    init() {
        // Käufe, die außerhalb der App abgeschlossen werden (anderes Gerät, Familienfreigabe,
        // „Ask to Buy“, Erstattungen), kommen über Transaction.updates.
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update)
            }
        }
        Task { await refresh() }
    }

    func refresh() async {
        await loadProduct()
        await updateEntitlements()
    }

    func loadProduct() async {
        guard premiumProduct == nil else { return }
        isLoadingProduct = true
        defer { isLoadingProduct = false }
        do {
            premiumProduct = try await Product.products(for: [Self.premiumProductID]).first
        } catch {
            premiumProduct = nil
        }
    }

    func purchasePremium() async {
        guard let product = premiumProduct else {
            errorMessage = "Premium ist gerade nicht verfügbar. Bitte versuche es später erneut."
            return
        }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    errorMessage = "Der Kauf konnte nicht bestätigt werden."
                    return
                }
                await transaction.finish()
                await updateEntitlements()
            case .pending:
                errorMessage = "Der Kauf wartet noch auf Bestätigung (z. B. „Kaufen anfragen“ in der Familienfreigabe)."
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = "Der Kauf ist fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    /// „Käufe wiederherstellen“ – synchronisiert mit dem App Store (fragt ggf. nach der Apple-ID).
    func restorePurchases() async {
        do {
            try await StoreKit.AppStore.sync()
        } catch {
            errorMessage = "Wiederherstellen fehlgeschlagen: \(error.localizedDescription)"
        }
        await updateEntitlements()
        if !isPremium && errorMessage == nil {
            errorMessage = "Es wurde kein Premium-Kauf zu deiner Apple-ID gefunden."
        }
    }

    func updateEntitlements() async {
        var hasPremium = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.premiumProductID,
               transaction.revocationDate == nil {
                hasPremium = true
            }
        }
        isPremium = hasPremium
        UserDefaults.standard.set(hasPremium, forKey: Self.cacheKey)
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        if case .verified(let transaction) = result {
            await transaction.finish()
        }
        await updateEntitlements()
    }
}
