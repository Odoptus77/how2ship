import Foundation

public enum OfferBadge: String, Hashable, Sendable {
    case cheapest
    case bestLiability
}

public struct Offer: Identifiable, Hashable, Sendable {
    public let tariff: Tariff
    /// Eingerechnete Zusatzleistungen (Versicherung, Abholung, Unterschrift).
    public let addOns: [AddOn]
    /// Gesamtpreis = Grundpreis + Zusatzleistungen.
    public let priceCents: Int
    /// Abgesicherter Wert (Grundhaftung oder Versicherungssumme).
    public let coverageEuro: Int?
    public let badges: Set<OfferBadge>
    /// `true`, wenn das Paket nur knapp passt (Messungenauigkeit der Kamera beachten).
    public let isTight: Bool

    public var id: String { tariff.id }
    public var basePriceCents: Int { tariff.priceCents }
    public var insurance: AddOn? { addOns.first { $0.kind == .insurance } }
}

/// Ermittelt alle passenden Tarife – neutral, sortiert nach Gesamtpreis inkl. Zusatzleistungen.
public struct TariffEngine: Sendable {
    public let catalog: TariffCatalog

    public init(catalog: TariffCatalog) {
        self.catalog = catalog
    }

    public func offers(
        for parcel: ParcelDimensions,
        requirements: ShippingRequirements = .none,
        channels: Set<SalesChannel> = [.online],
        tightMarginCm: Double = 1
    ) -> [Offer] {
        let matching: [(tariff: Tariff, priced: PricedTariff)] = catalog.tariffs.compactMap { tariff in
            guard channels.contains(tariff.channel), tariff.accepts(parcel),
                  let priced = tariff.priced(for: requirements) else { return nil }
            return (tariff, priced)
        }

        // Pro Produktlinie nur das günstigste passende Produkt (nach Gesamtpreis).
        var cheapestPerFamily: [String: (tariff: Tariff, priced: PricedTariff)] = [:]
        for candidate in matching {
            if let current = cheapestPerFamily[candidate.tariff.family],
               current.priced.totalPriceCents <= candidate.priced.totalPriceCents {
                continue
            }
            cheapestPerFamily[candidate.tariff.family] = candidate
        }

        let sorted = cheapestPerFamily.values.sorted { a, b in
            a.priced.totalPriceCents != b.priced.totalPriceCents
                ? a.priced.totalPriceCents < b.priced.totalPriceCents
                : a.tariff.id < b.tariff.id
        }
        guard let minPrice = sorted.first?.priced.totalPriceCents else { return [] }

        let coverages = sorted.compactMap { $0.priced.coverageEuro }
        let bestCoverage = Set(coverages).count > 1 ? coverages.max() : nil
        let enlarged = parcel.enlarged(byCm: tightMarginCm)

        return sorted.map { candidate in
            var badges = Set<OfferBadge>()
            if candidate.priced.totalPriceCents == minPrice { badges.insert(.cheapest) }
            if let bestCoverage, candidate.priced.coverageEuro == bestCoverage { badges.insert(.bestLiability) }
            return Offer(
                tariff: candidate.tariff,
                addOns: candidate.priced.addOns,
                priceCents: candidate.priced.totalPriceCents,
                coverageEuro: candidate.priced.coverageEuro,
                badges: badges,
                isTight: !candidate.tariff.accepts(enlarged)
            )
        }
    }
}
