import SwiftUI

struct ProfileView: View {
    @Environment(AppStore.self) private var store
    @State private var showMethodology = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HeroCard(
                        title: "Paketlotse Premium",
                        subtitle: "Werbefrei, gespeicherte Paketgrößen, Versandverlauf mit Kostenübersicht und Preisalarm – einmalig 2,99 €.",
                        buttonTitle: "BALD VERFÜGBAR",
                        systemImage: "star.circle"
                    ) {}

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
            .sheet(isPresented: $showMethodology) { MethodologyView() }
        }
    }
}

struct ProfileRow: View {
    let title: String
    let systemImage: String
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
