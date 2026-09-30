import SwiftUI
import PaketlotseCore

/// Versandverlauf mit Kostenübersicht (Premium).
struct ShippingHistoryView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        let history = store.shippingHistory
        let years = store.yearlyCosts()

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if history.isEmpty {
                    EmptyStateView(
                        systemImage: "chart.bar",
                        title: "Noch keine Sendungen",
                        message: "Sobald du nach einer Buchung die Sendungsnummer hinzufügst, erscheint sie hier – mit Kosten."
                    )
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(years, id: \.year) { entry in
                                YearCostCard(year: entry.year, count: entry.count, totalCents: entry.totalCents)
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 2)
                    }

                    SectionHeader(title: "Alle Sendungen")
                    ForEach(history) { booking in
                        HStack(spacing: 14) {
                            CarrierAvatar(carrier: booking.carrier, size: 42)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("\(booking.carrier.displayName) \(booking.product)")
                                    .font(.lotse(15, .bold))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(booking.clickedAt.formatted(date: .abbreviated, time: .omitted))
                                    .font(.lotse(12))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            Text(booking.priceCents.map { Money.format(cents: $0) } ?? "–")
                                .font(.lotse(16, .heavy))
                                .foregroundStyle(Theme.primary)
                        }
                        .card()
                    }

                    Text("Preise laut Vergleich zum Zeitpunkt der Buchung. Maßgeblich ist, was du beim Paketdienst bezahlt hast.")
                        .font(.lotse(11))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(Theme.padding)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Versandverlauf")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct YearCostCard: View {
    let year: Int
    let count: Int
    let totalCents: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(year))
                .font(.lotse(13, .bold))
                .foregroundStyle(.white.opacity(0.8))
            Text(Money.format(cents: totalCents))
                .font(.lotse(26, .heavy))
                .foregroundStyle(.white)
            Text(count == 1 ? "1 Paket" : "\(count) Pakete")
                .font(.lotse(13, .semibold))
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(width: 180, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(colors: [Theme.primary, Theme.primaryDark], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
        )
    }
}
