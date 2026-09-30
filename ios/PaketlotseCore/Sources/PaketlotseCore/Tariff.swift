import Foundation

/// Wie ein Paketdienst die Paketgröße bewertet.
public enum SizeRule: Codable, Hashable, Sendable {
    /// Höchstmaße je Seite (DHL / Deutsche Post). Seiten werden sortiert verglichen.
    case maxDimensions(lengthCm: Double, widthCm: Double, heightCm: Double)
    /// Summe aus längster und kürzester Seite (Hermes, DPD, GLS).
    case longestPlusShortest(maxSumCm: Double, maxLengthCm: Double?)
    /// Abrechnung nach max(tatsächliches Gewicht, Volumengewicht) (UPS).
    case volumetric(divisor: Double, maxLengthCm: Double?)
    /// Gurtmaß = längste Seite + 2 × (mittlere + kürzeste) (DPD/GLS XL).
    case girth(maxGirthCm: Double, maxLengthCm: Double?)
}

/// Wohin der Paketdienst zustellt.
public enum DeliveryTarget: String, Codable, Hashable, Sendable {
    /// An die Haustür des Empfängers.
    case home
    /// In einen PaketShop, den der Empfänger wählt (günstiger, Empfänger holt ab).
    case shop
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
    /// Haftung in Euro. `0` = keine Haftung (z. B. DHL Päckchen), `nil` = unbekannt/laut AGB.
    public var liabilityEuro: Int?
    public var hasTracking: Bool
    public var delivery: DeliveryTarget
    public var transitDays: String?
    public var dropOff: [DropOffOption]
    public var addOns: [AddOn]
    public var bookingURL: URL?

    public init(
        id: String, carrier: Carrier, family: String, product: String, channel: SalesChannel,
        priceCents: Int, maxWeightKg: Double, rule: SizeRule, liabilityEuro: Int?,
        hasTracking: Bool, delivery: DeliveryTarget = .home, transitDays: String?, dropOff: [DropOffOption],
        addOns: [AddOn] = [], bookingURL: URL?
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
        self.delivery = delivery
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

        case let .girth(maxGirth, maxLength):
            guard parcel.weightKg <= maxWeightKg else { return false }
            if let maxLength, parcel.longestSide > maxLength { return false }
            return parcel.girthCm <= maxGirth
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id, carrier, family, product, channel, priceCents, maxWeightKg, rule, liabilityEuro
        case hasTracking, delivery, transitDays, dropOff, addOns, bookingURL
    }

    /// Tolerant: `delivery` (Standard Haustür) und `addOns` dürfen fehlen.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        carrier = try c.decode(Carrier.self, forKey: .carrier)
        family = try c.decode(String.self, forKey: .family)
        product = try c.decode(String.self, forKey: .product)
        channel = try c.decode(SalesChannel.self, forKey: .channel)
        priceCents = try c.decode(Int.self, forKey: .priceCents)
        maxWeightKg = try c.decode(Double.self, forKey: .maxWeightKg)
        rule = try c.decode(SizeRule.self, forKey: .rule)
        liabilityEuro = try c.decodeIfPresent(Int.self, forKey: .liabilityEuro)
        hasTracking = try c.decode(Bool.self, forKey: .hasTracking)
        delivery = try c.decodeIfPresent(DeliveryTarget.self, forKey: .delivery) ?? .home
        transitDays = try c.decodeIfPresent(String.self, forKey: .transitDays)
        dropOff = try c.decodeIfPresent([DropOffOption].self, forKey: .dropOff) ?? []
        addOns = try c.decodeIfPresent([AddOn].self, forKey: .addOns) ?? []
        bookingURL = try c.decodeIfPresent(URL.self, forKey: .bookingURL)
    }
}

public struct TariffCatalog: Codable, Sendable {
    public var version: String
    public var validFrom: String
    /// Hinweis zur Datenherkunft (wird im Profil angezeigt).
    public var sourceNote: String?
    /// `true`, solange die Preise Platzhalter sind und nicht mit den offiziellen Preislisten abgeglichen wurden.
    public var isSample: Bool
    public var tariffs: [Tariff]

    public init(version: String, validFrom: String, sourceNote: String? = nil, isSample: Bool, tariffs: [Tariff]) {
        self.version = version
        self.validFrom = validFrom
        self.sourceNote = sourceNote
        self.isSample = isSample
        self.tariffs = tariffs
    }

    public enum LoadError: Error {
        case missingResource
    }

    public static func decode(from data: Data) throws -> TariffCatalog {
        try JSONDecoder().decode(TariffCatalog.self, from: data)
    }

    /// Aktuelle Tarife der Paketdienste (Privatkunden).
    public static let currentResource = "tarife-2026"

    public static func bundled(_ resource: String) throws -> TariffCatalog {
        guard let url = Bundle.module.url(forResource: resource, withExtension: "json") else {
            throw LoadError.missingResource
        }
        return try decode(from: Data(contentsOf: url))
    }

    public static func bundledCurrent() throws -> TariffCatalog {
        try bundled(currentResource)
    }

    /// Feste Beispieldaten für Unit-Tests der Rechenlogik.
    public static func bundledSample() throws -> TariffCatalog {
        try bundled("tarife-beispiel")
    }
}
