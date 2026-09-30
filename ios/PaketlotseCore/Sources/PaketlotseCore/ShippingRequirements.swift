import Foundation

/// Zusatzleistung, die ein Tarif gegen Aufpreis (oder kostenlos) anbietet.
public enum ServiceKind: String, Codable, Hashable, Sendable {
    /// Höherversicherung über die Grundhaftung hinaus.
    case insurance
    /// Abholung an der Haustür.
    case pickup
    /// Zustellung nur gegen Unterschrift.
    case signature

    public var displayName: String {
        switch self {
        case .insurance: "Versicherung"
        case .pickup: "Abholung"
        case .signature: "Unterschrift"
        }
    }
}

public struct AddOn: Codable, Hashable, Sendable {
    public var kind: ServiceKind
    public var priceCents: Int
    /// Nur bei `.insurance`: versicherter Wert in Euro.
    public var coverageEuro: Int?

    public init(kind: ServiceKind, priceCents: Int, coverageEuro: Int? = nil) {
        self.kind = kind
        self.priceCents = priceCents
        self.coverageEuro = coverageEuro
    }
}

/// Was der Nutzer für seine Sendung braucht. Fließt in Filter und Gesamtpreis ein.
public struct ShippingRequirements: Codable, Hashable, Sendable {
    /// Warenwert in Euro. Liegt er über der Grundhaftung, wird die günstigste passende Versicherung eingerechnet.
    public var declaredValueEuro: Int?
    public var requiresTracking: Bool
    public var requiresPickup: Bool
    public var requiresSignature: Bool
    public var requiresPackstation: Bool
    /// Nur Tarife, die an die Haustür zustellen (keine Zustellung in einen PaketShop).
    public var requiresHomeDelivery: Bool

    public static let none = ShippingRequirements()

    public init(
        declaredValueEuro: Int? = nil,
        requiresTracking: Bool = false,
        requiresPickup: Bool = false,
        requiresSignature: Bool = false,
        requiresPackstation: Bool = false,
        requiresHomeDelivery: Bool = false
    ) {
        self.declaredValueEuro = declaredValueEuro
        self.requiresTracking = requiresTracking
        self.requiresPickup = requiresPickup
        self.requiresSignature = requiresSignature
        self.requiresPackstation = requiresPackstation
        self.requiresHomeDelivery = requiresHomeDelivery
    }

    public var needsInsurance: Bool { (declaredValueEuro ?? 0) > 0 }

    public var isEmpty: Bool {
        !needsInsurance && !requiresTracking && !requiresPickup && !requiresSignature
            && !requiresPackstation && !requiresHomeDelivery
    }
}

/// Ergebnis der Preisberechnung eines Tarifs inkl. gewählter Zusatzleistungen.
public struct PricedTariff: Hashable, Sendable {
    public let addOns: [AddOn]
    public let totalPriceCents: Int
    /// Abgesicherter Wert: Grundhaftung oder – falls eingerechnet – Versicherungssumme.
    public let coverageEuro: Int?
}

extension Tariff {
    /// `nil`, wenn der Tarif die Anforderungen nicht erfüllen kann.
    public func priced(for requirements: ShippingRequirements) -> PricedTariff? {
        if requirements.requiresTracking && !hasTracking { return nil }
        if requirements.requiresPackstation && !dropOff.contains(.packstation) { return nil }
        if requirements.requiresHomeDelivery && delivery != .home { return nil }

        var selected: [AddOn] = []

        if requirements.requiresPickup {
            guard let pickup = cheapestAddOn(.pickup) else { return nil }
            selected.append(pickup)
        }
        if requirements.requiresSignature {
            guard let signature = cheapestAddOn(.signature) else { return nil }
            selected.append(signature)
        }

        var coverage = liabilityEuro
        if let value = requirements.declaredValueEuro, value > 0, (liabilityEuro ?? 0) < value {
            let insurance = addOns
                .filter { $0.kind == .insurance && ($0.coverageEuro ?? 0) >= value }
                .min { $0.priceCents < $1.priceCents }
            guard let insurance else { return nil }
            selected.append(insurance)
            coverage = insurance.coverageEuro
        }

        let total = priceCents + selected.reduce(0) { $0 + $1.priceCents }
        return PricedTariff(addOns: selected, totalPriceCents: total, coverageEuro: coverage)
    }

    private func cheapestAddOn(_ kind: ServiceKind) -> AddOn? {
        addOns.filter { $0.kind == kind }.min { $0.priceCents < $1.priceCents }
    }
}
