import Foundation

/// Wie ein Paketdienst die Paketgröße bewertet.
public enum SizeRule: Codable, Hashable, Sendable {
    /// Höchstmaße je Seite (DHL / Deutsche Post). Seiten werden sortiert verglichen.
    case maxDimensions(lengthCm: Double, widthCm: Double, heightCm: Double)
    /// Summe aus längster und kürzester Seite (Hermes, DPD, GLS).
    case longestPlusShortest(maxSumCm: Double, maxLengthCm: Double?)
    /// Abrechnung nach max(tatsächliches Gewicht, Volumengewicht) (UPS).
    case volumetric(divisor: Double, maxLengthCm: Double?)
}

public struct Tariff: Codable, Hashable, Identifiable, Sendable {
    public var id: String
    public var carrier: Carrier
    /// Produktlinie, z. B. "dhl-paket". Pro Linie wird nur das günstigste passende Produkt angezeigt.
    public var family: String
    public var product: String
    public var channel: SalesChannel
    public var priceCents: Int
    public var maxWeightKg: Double
    public var rule: SizeRule
    public var liabilityEuro: Int?
    public var hasTracking: Bool
    public var transitDays: String?
    public var dropOff: [DropOffOption]
    public var addOns: [AddOn]
    public var bookingURL: URL?

    public init(
        id: String, carrier: Carrier, family: String, product: String, channel: SalesChannel,
        priceCents: Int, maxWeightKg: Double, rule: SizeRule, liabilityEuro: Int?,
        hasTracking: Bool, transitDays: String?, dropOff: [DropOffOption], addOns: [AddOn] = [], bookingURL: URL?
    ) {
        self.id = id
        self.carrier = carrier
        self.family = family
        self.product = product
        self.channel = channel
        self.priceCents = priceCents
        self.maxWeightKg = maxWeightKg
        self.rule = rule
        self.liabilityEuro = liabilityEuro
        self.hasTracking = hasTracking
        self.transitDays = transitDays
        self.dropOff = dropOff
        self.addOns = addOns
        self.bookingURL = bookingURL
    }

    public func accepts(_ parcel: ParcelDimensions) -> Bool {
        guard parcel.isValid else { return false }
        switch rule {
        case let .maxDimensions(length, width, height):
            guard parcel.weightKg <= maxWeightKg else { return false }
            let limits = [length, width, height].sorted(by: >)
            return zip(parcel.sidesDescending, limits).allSatisfy { $0 <= $1 }

        case let .longestPlusShortest(maxSum, maxLength):
            guard parcel.weightKg <= maxWeightKg else { return false }
            if let maxLength, parcel.longestSide > maxLength { return false }
            return parcel.longestPlusShortest <= maxSum

        case let .volumetric(divisor, maxLength):
            if let maxLength, parcel.longestSide > maxLength { return false }
            let chargeable = max(parcel.weightKg, parcel.volumetricWeightKg(divisor: divisor))
            return chargeable <= maxWeightKg
        }
    }
}

public struct TariffCatalog: Codable, Sendable {
    public var version: String
    public var validFrom: String
    /// `true`, solange die Preise Platzhalter sind und nicht mit den offiziellen Preislisten abgeglichen wurden.
    public var isSample: Bool
    public var tariffs: [Tariff]

    public init(version: String, validFrom: String, isSample: Bool, tariffs: [Tariff]) {
        self.version = version
        self.validFrom = validFrom
        self.isSample = isSample
        self.tariffs = tariffs
    }

    public enum LoadError: Error {
        case missingResource
    }

    public static func decode(from data: Data) throws -> TariffCatalog {
        try JSONDecoder().decode(TariffCatalog.self, from: data)
    }

    public static func bundledSample() throws -> TariffCatalog {
        guard let url = Bundle.module.url(forResource: "tarife-beispiel", withExtension: "json") else {
            throw LoadError.missingResource
        }
        return try decode(from: Data(contentsOf: url))
    }
}
