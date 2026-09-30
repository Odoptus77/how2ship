import SwiftUI
import PaketlotseCore

struct ProfileView: View {
    @Environment(AppStore.self) private var store
    @Environment(PurchaseManager.self) private var purchases
    @State private var showMethodology = false
    @State private var paywallReason: PaywallReason?
    @State private var showHistory = false
    @State private var showSavedParcels = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if purchases.isPremium {
                        premiumActiveCard
                    } else {
                        HeroCard(
                            title: "Paketlotse Premium",
                            subtitle: "Werbefrei, gespeicherte Paketgrößen, Versandverlauf mit Kostenübersicht – einmalig\(purchases.premiumProduct.map { " " + $0.displayPrice } ?? ""), kein Abo.",
                            buttonTitle: "JETZT FREISCHALTEN",
                            systemImage: "star.circle"
                        ) { paywallReason = PaywallReason(text: nil) }
                    }

                    VStack(spacing: 0) {
                        ProfileRow(
                            title: "Versandverlauf & Kosten",
                            systemImage: "chart.bar",
                            badge: purchases.isPremium ? nil : "Premium"
                        ) {
                            if purchases.isPremium { showHistory = true }
                            else { paywallReason = PaywallReason(text: "Der Versandverlauf ist Teil von Premium.") }
                        }
                        Divider().padding(.leading, 52)
                        ProfileRow(
                            title: "Gespeicherte Paketgrößen (\(store.savedParcels.count))",
                            systemImage: "bookmark",
                            badge: purchases.isPremium ? nil : "Premium"
                        ) {
                            if purchases.isPremium { showSavedParcels = true }
                            else { paywallReason = PaywallReason(text: "Gespeicherte Paketgrößen sind Teil von Premium.") }
                        }
                        Divider().padding(.leading, 52)
                        ProfileRow(title: "Käufe wiederherstellen", systemImage: "arrow.clockwise") {
                            Task { await purchases.restorePurchases() }
                        }
                    }
                    .card()

                    VStack(spacing: 0) {
                        ProfileRow(title: "So vergleichen wir", systemImage: "list.number") { showMethodology = true }
                        Divider().padding(.leading, 52)
                        ProfileRow(
                            title: "Tarifstand: \(store.catalog.validFrom)\(store.catalog.isSample ? " (Beispieldaten)" : "")",
                            systemImage: "calendar",
                            action: nil
                        )
                        Divider().padding(.leading, 52)
                        ProfileRow(title: "Datenschutz", systemImage: "hand.raised", action: nil)
                        Divider().padding(.leading, 52)
                        ProfileRow(title: "Impressum", systemImage: "info.circle", action: nil)
                    }
                    .card()

                    Text("Paketlotse ist ein unabhängiger Vergleichsdienst und nicht mit den Paketdiensten verbunden.")
                        .font(.lotse(12))
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(Theme.padding)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Profil")
            .navigationDestination(isPresented: $showHistory) { ShippingHistoryView() }
            .navigationDestination(isPresented: $showSavedParcels) { SavedParcelsView() }
            .sheet(isPresented: $showMethodology) { MethodologyView() }
            .sheet(item: $paywallReason) { reason in PaywallView(reason: reason.text) }
            .alert("Hinweis", isPresented: Binding(
                get: { purchases.errorMessage != nil && paywallReason == nil },
                set: { if !$0 { purchases.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(purchases.errorMessage ?? "")
            }
        }
    }

    private var premiumActiveCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(Theme.accent)
            VStack(alignment: .leading, spacing: 3) {
                Text("Premium aktiv")
                    .font(.lotse(18, .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Danke für deine Unterstützung!")
                    .font(.lotse(13))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
        .card()
    }
}

/// Anlass für die Paywall (als `Identifiable` für `.sheet(item:)`).
struct PaywallReason: Identifiable {
    let id = UUID()
    let text: String?
}

/// Verwaltung der gespeicherten Paketgrößen (Premium).
struct SavedParcelsView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        List {
            if store.savedParcels.isEmpty {
                Text("Noch keine Größen gespeichert. Tippe auf dem Startbildschirm unter den Maßen auf „Größe speichern“.")
                    .font(.lotse(14))
                    .foregroundStyle(Theme.textSecondary)
            }
            ForEach(store.savedParcels) { saved in
                VStack(alignment: .leading, spacing: 3) {
                    Text(saved.name)
                        .font(.lotse(16, .bold))
                    Text(saved.parcel.summary)
                        .font(.lotse(13))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .onDelete { offsets in
                offsets.map { store.savedParcels[$0] }.forEach(store.deleteSavedParcel)
            }
        }
        .navigationTitle("Gespeicherte Größen")
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension ParcelDimensions {
    /// z. B. „33 × 20 × 12 cm · 1 kg“
    var summary: String {
        let locale = Locale(identifier: "de_DE")
        func format(_ value: Double) -> String {
            value.formatted(.number.precision(.fractionLength(0...1)).locale(locale))
        }
        return "\(format(lengthCm)) × \(format(widthCm)) × \(format(heightCm)) cm · \(format(weightKg)) kg"
    }
}

struct ProfileRow: View {
    let title: String
    let systemImage: String
    var badge: String? = nil
    let action: (() -> Void)?

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .foregroundStyle(Theme.primary)
                    .frame(width: 38, height: 38)
                    .background(Theme.chip, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                Text(title)
                    .font(.lotse(15, .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                if let badge {
                    Tag(text: badge, systemImage: "lock.fill", tint: Theme.accent, background: Theme.accentSoft)
                }
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}
