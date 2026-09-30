import SwiftUI
import PaketlotseCore

struct ResultsView: View {
    let parcel: ParcelDimensions
    var requirements: ShippingRequirements = .none

    @Environment(AppStore.self) private var store
    @Environment(\.openURL) private var openURL
    @State private var sortOrder: OfferSortOrder = .price
    @State private var showMethodology = false

    var body: some View {
        let offers = store.engine.offers(for: parcel, requirements: requirements).sorted(by: sortOrder)
        let tip = store.advisor.bestTip(for: parcel, requirements: requirements)

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                parcelSummary

                if store.catalog.isSample { SampleDataBanner() }

                if let tip { SavingsTipCard(tip: tip) }

                if offers.isEmpty {
                    EmptyStateView(
                        systemImage: "exclamationmark.magnifyingglass",
                        title: "Kein passender Tarif",
                        message: requirements.isEmpty
                            ? "Für diese Maße bzw. dieses Gewicht haben wir kein Angebot. Prüfe die Eingaben oder denk an Sperrgut-Versand."
                            : "Mit diesen Zusatzleistungen passt kein Tarif. Entferne z. B. die Versicherung, Abholung oder Unterschrift."
                    )
                } else {
                    SectionHeader(title: "\(offers.count) passende Angebote")
                    sortPicker
                    ForEach(offers) { offer in
                        OfferCard(offer: offer) { book(offer) }
                    }
                }

                Button {
                    showMethodology = true
                } label: {
                    Text("Sortiert nach \(sortOrder == .price ? "Gesamtpreis" : "Versicherungssumme"). Bei manchen Buchungen erhalten wir eine Provision – die Reihenfolge beeinflusst das nicht. **So vergleichen wir**")
                        .font(.lotse(12))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                .buttonStyle(.plain)
            }
            .padding(Theme.padding)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Angebote")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showMethodology) { MethodologyView() }
    }

    private var sortPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Label("Sortieren", systemImage: "arrow.up.arrow.down")
                    .font(.lotse(13, .semibold))
                    .foregroundStyle(Theme.textSecondary)
                ForEach(OfferSortOrder.allCases) { order in
                    Chip(title: order.displayName, isSelected: sortOrder == order) {
                        withAnimation(.easeInOut(duration: 0.25)) { sortOrder = order }
                    }
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 2)
        }
    }

    private var parcelSummary: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                summaryTag("\(Self.cm(parcel.lengthCm)) × \(Self.cm(parcel.widthCm)) × \(Self.cm(parcel.heightCm)) cm", "cube")
                summaryTag("\(Self.cm(parcel.weightKg)) kg", "scalemass")
                if let value = requirements.declaredValueEuro, value > 0 {
                    summaryTag("Wert \(value.formatted(.number.locale(Locale(identifier: "de_DE")))) €", "shield")
                }
                if requirements.requiresTracking { summaryTag("Sendungsverfolgung", "location") }
                if requirements.requiresHomeDelivery { summaryTag("Haustür", "door.left.hand.closed") }
                if requirements.requiresPickup { summaryTag("Abholung", "shippingbox.and.arrow.backward") }
                if requirements.requiresSignature { summaryTag("Unterschrift", "signature") }
                if requirements.requiresPackstation { summaryTag("Packstation", "square.grid.3x3.square") }
            }
            .padding(.vertical, 2)
        }
    }

    private func summaryTag(_ text: String, _ systemImage: String) -> some View {
        Tag(text: text, systemImage: systemImage, tint: Theme.primary, background: Theme.surface)
    }

    /// Buchung läuft extern (Carrier-App bzw. Standardbrowser). Paketlotse liest dort nichts aus;
    /// bei der Rückkehr fragt die App nach der Sendungsnummer (Konzept 4.2).
    private func book(_ offer: Offer) {
        guard let url = offer.tariff.bookingURL else { return }
        store.startBooking(for: offer)
        openURL(url)
    }

    private static func cm(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)).locale(Locale(identifier: "de_DE")))
    }
}

struct OfferCard: View {
    let offer: Offer
    let onBook: () -> Void

    private var tariff: Tariff { offer.tariff }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                CarrierAvatar(carrier: tariff.carrier)

                VStack(alignment: .leading, spacing: 4) {
                    Text(tariff.carrier.displayName)
                        .font(.lotse(12, .semibold))
                        .foregroundStyle(Theme.textSecondary)
                    Text(tariff.product)
                        .font(.lotse(17, .bold))
                        .foregroundStyle(Theme.textPrimary)
                    if let transit = tariff.transitDays {
                        Label("\(transit) Werktage", systemImage: "clock")
                            .font(.lotse(12))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text(Money.format(cents: offer.priceCents))
                        .font(.lotse(20, .heavy))
                        .foregroundStyle(offer.badges.contains(.cheapest) ? Theme.accent : Theme.primary)
                    if offer.badges.contains(.cheapest) {
                        Tag(text: "Günstigster", tint: .white, background: Theme.accent)
                    }
                    if offer.badges.contains(.bestLiability) {
                        Tag(text: "Beste Haftung", systemImage: "shield.fill", tint: .white, background: Theme.primary)
                    }
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    if tariff.delivery == .shop {
                        Tag(text: "Zustellung in PaketShop", systemImage: "storefront", tint: Theme.accent, background: Theme.accentSoft)
                    }
                    if tariff.hasTracking { Tag(text: "Sendungsverfolgung", systemImage: "location") }
                    if let insurance = offer.insurance, let coverage = insurance.coverageEuro {
                        Tag(text: "Versichert bis \(coverage.formatted(.number.locale(Locale(identifier: "de_DE")))) €", systemImage: "checkmark.shield", tint: Theme.primary)
                    } else if let liability = tariff.liabilityEuro, liability > 0 {
                        Tag(text: "Haftung \(liability) €", systemImage: "shield")
                    } else if tariff.liabilityEuro == 0 {
                        Tag(text: "Ohne Haftung", systemImage: "shield.slash")
                    } else {
                        Tag(text: "Haftung lt. AGB", systemImage: "shield")
                    }
                    if !tariff.hasTracking {
                        Tag(text: "Ohne Sendungsverfolgung", systemImage: "location.slash")
                    }
                    ForEach(tariff.dropOff, id: \.self) { Tag(text: $0.displayName) }
                }
            }

            if !offer.addOns.isEmpty {
                PriceBreakdown(offer: offer)
            }

            if offer.isTight {
                Label("Knapp an der Grenze – bitte nachmessen", systemImage: "exclamationmark.triangle.fill")
                    .font(.lotse(12, .semibold))
                    .foregroundStyle(Theme.accent)
            }

            if tariff.bookingURL != nil {
                Button("Jetzt buchen", action: onBook)
                    .buttonStyle(PrimaryButtonStyle(compact: true))
            } else {
                Text("Nur in der Filiale bzw. im Paketshop frankierbar")
                    .font(.lotse(12))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .card()
    }
}

/// Grundpreis plus eingerechnete Zusatzleistungen.
struct PriceBreakdown: View {
    let offer: Offer

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            row("Grundpreis", offer.basePriceCents)
            ForEach(offer.addOns, id: \.self) { addOn in
                row(label(for: addOn), addOn.priceCents, prefix: "+ ")
            }
        }
        .font(.lotse(12))
        .foregroundStyle(Theme.textSecondary)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.chip, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func label(for addOn: AddOn) -> String {
        if addOn.kind == .insurance, let coverage = addOn.coverageEuro {
            return "Versicherung bis \(coverage.formatted(.number.locale(Locale(identifier: "de_DE")))) €"
        }
        return addOn.kind.displayName
    }

    private func row(_ title: String, _ cents: Int, prefix: String = "") -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(cents == 0 ? "inklusive" : prefix + Money.format(cents: cents))
        }
    }
}

/// Cremefarbene Hinweiskarte – wie „Urgent Needed“ in der Referenz.
struct SavingsTipCard: View {
    let tip: SavingsTip

    private var message: String {
        let target = "\(tip.offer.tariff.carrier.displayName) \(tip.offer.tariff.product)"
        let saving = Money.format(cents: tip.savingCents)
        switch tip.adjustment {
        case .shortenLongestSide(let cm):
            return "Wenn dein Paket \(cm) cm kürzer ist, passt es in \(target). Du sparst \(saving)."
        case .reduceWeight(let grams):
            return "Mit \(grams) g weniger Gewicht passt es in \(target). Du sparst \(saving)."
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 20))
                .foregroundStyle(Theme.accent)
                .frame(width: 42, height: 42)
                .background(Theme.surface, in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text("Spar-Tipp")
                    .font(.lotse(15, .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(message)
                    .font(.lotse(14))
                    .foregroundStyle(Theme.textPrimary.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(background: Theme.accentSoft)
    }
}

struct MethodologyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("So vergleichen wir")
                    .font(.lotse(24, .bold))
                Text("""
                • Wir zeigen alle Tarife, in die dein Paket nach den Regeln des jeweiligen Paketdienstes passt.
                • Standardmäßig sortieren wir nach dem Gesamtpreis inkl. MwSt. und gewählter Zusatzleistungen. Alternativ kannst du nach der Versicherungssumme sortieren.
                • Pro Produktlinie zeigen wir das günstigste passende Produkt.
                • Bei manchen Buchungen erhalten wir eine Provision von Partnern. Das beeinflusst die Reihenfolge nicht.
                • Alle Angaben ohne Gewähr. Maßgeblich sind die Bedingungen des Paketdienstes.
                • Paketlotse ist ein unabhängiger Vergleichsdienst und nicht mit den Paketdiensten verbunden.
                """)
                .font(.lotse(15))
                .foregroundStyle(Theme.textSecondary)
            }
            .padding(24)
        }
        .presentationDetents([.medium, .large])
    }
}
