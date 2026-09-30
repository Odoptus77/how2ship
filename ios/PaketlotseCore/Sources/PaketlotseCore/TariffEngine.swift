import Foundation

public enum OfferBadge: String, Hashable, Sendable {
    case cheapest
    case bestLiability
}

public struct Offer: Identifiable, Hashable, Sendable {
    public let tariff: Tariff
    public let badges: Set<OfferBadge>
    /// `true`, wenn das Paket nur knapp passt (Messungenauigkeit der Kamera beachten).
    public let isTight: Bool

    public var id: String { tariff.id }
    public var priceCents: Int { tariff.priceCents }
}

/// Ermittelt alle passenden Tarife – neutral, sortiert nach Gesamtpreis.
public struct TariffEngine: Sendable {
    public let catalog: TariffCatalog

    public init(catalog: TariffCatalog) {
        self.catalog = catalog
    }

    public func offers(
        for parcel: ParcelDimensions,
        channels: Set<SalesChannel> = [.online],
        tightMarginCm: Double = 1
    ) -> [Offer] {
        let matching = catalog.tariffs.filter { channels.contains($0.channel) && $0.accepts(parcel) }

        // Pro Produktlinie nur das günstigste passende Produkt.
        var cheapestPerFamily: [String: Tariff] = [:]
        for tariff in matching {
            if let current = cheapestPerFamily[tariff.family], current.priceCents <= tariff.priceCents {
                continue
            }
            cheapestPerFamily[tariff.family] = tariff
        }

        let sorted = cheapestPerFamily.values.sorted { a, b in
            a.priceCents != b.priceCents ? a.priceCents < b.priceCents : a.id < b.id
        }
        guard let minPrice = sorted.first?.priceCents else { return [] }

        let liabilities = sorted.compactMap(\.liabilityEuro)
        let bestLiability = Set(liabilities).count > 1 ? liabilities.max() : nil
        let enlarged = parcel.enlarged(byCm: tightMarginCm)

        return sorted.map { tariff in
            var badges = Set<OfferBadge>()
            if tariff.priceCents == minPrice { badges.insert(.cheapest) }
            if let bestLiability, tariff.liabilityEuro == bestLiability { badges.insert(.bestLiability) }
            return Offer(tariff: tariff, badges: badges, isTight: !tariff.accepts(enlarged))
        }
    }
}
