import SwiftUI
import StoreKit

/// Premium-Angebot (Einmalkauf). Wird aus dem Profil und von gesperrten Premium-Funktionen geöffnet.
struct PaywallView: View {
    /// Optionaler Hinweis, welche Funktion den Aufruf ausgelöst hat.
    var reason: String?

    @Environment(PurchaseManager.self) private var purchases
    @Environment(\.dismiss) private var dismiss

    private let benefits: [(icon: String, title: String, text: String)] = [
        ("nosign", "Werbefrei", "Keine Banner – nur Vergleich, Karte und Sendungen."),
        ("bookmark.fill", "Gespeicherte Paketgrößen", "Deine Kartons mit einem Tipp wieder auswählen."),
        ("chart.bar.fill", "Versandverlauf & Kosten", "Alle Sendungen und was du pro Jahr für Porto ausgibst."),
        ("clock.arrow.circlepath", "Unbegrenzter Sendungsverlauf", "Zugestellte Sendungen bleiben erhalten statt nach 30 Tagen zu verschwinden."),
        ("bell.badge.fill", "Preisalarm (bald)", "Nachricht, wenn Paketdienste ihre Preise ändern."),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                if let reason {
                    Label(reason, systemImage: "lock.fill")
                        .font(.lotse(13, .semibold))
                        .foregroundStyle(Theme.primaryDark)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.chip, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 16) {
                    ForEach(benefits, id: \.title) { benefit in
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: benefit.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Theme.primary)
                                .frame(width: 40, height: 40)
                                .background(Theme.chip, in: Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(benefit.title)
                                    .font(.lotse(16, .bold))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(benefit.text)
                                    .font(.lotse(13))
                                    .foregroundStyle(Theme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .card()

                Text("Vergleich, Kamera-Vermessung, Sendungsverfolgung und Karte bleiben für alle kostenlos.")
                    .font(.lotse(12))
                    .foregroundStyle(Theme.textSecondary)

                purchaseSection
            }
            .padding(Theme.padding)
        }
        .background(Theme.background.ignoresSafeArea())
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 34, height: 34)
                    .background(Theme.surface, in: Circle())
            }
            .padding(16)
            .accessibilityLabel("Schließen")
        }
        .task { await purchases.loadProduct() }
        .onChange(of: purchases.isPremium) { _, isPremium in
            if isPremium { dismiss() }
        }
        .alert("Hinweis", isPresented: Binding(
            get: { purchases.errorMessage != nil },
            set: { if !$0 { purchases.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(purchases.errorMessage ?? "")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(Theme.accent)
            Text("Paketlotse Premium")
                .font(.lotse(28, .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Einmal kaufen, für immer nutzen – kein Abo.")
                .font(.lotse(15))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.top, 24)
    }

    @ViewBuilder
    private var purchaseSection: some View {
        VStack(spacing: 12) {
            if let product = purchases.premiumProduct {
                Button {
                    Task { await purchases.purchasePremium() }
                } label: {
                    HStack(spacing: 8) {
                        if purchases.isPurchasing { ProgressView().tint(.white) }
                        Text("Für \(product.displayPrice) freischalten")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(purchases.isPurchasing)
            } else if purchases.isLoadingProduct {
                ProgressView("Lade Angebot …")
                    .font(.lotse(13))
            } else {
                Text("Premium ist gerade nicht verfügbar. Prüfe deine Internetverbindung.")
                    .font(.lotse(13))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button("Käufe wiederherstellen") {
                Task { await purchases.restorePurchases() }
            }
            .font(.lotse(14, .semibold))
            .foregroundStyle(Theme.primary)

            Text("Einmalige Zahlung über deine Apple-ID. Mit Familienfreigabe teilbar.")
                .font(.lotse(11))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
