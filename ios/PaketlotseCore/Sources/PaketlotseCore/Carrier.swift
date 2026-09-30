import Foundation

public enum Carrier: String, Codable, CaseIterable, Identifiable, Sendable {
    case dhl
    case deutschePost
    case hermes
    case dpd
    case gls
    case ups

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .dhl: "DHL"
        case .deutschePost: "Deutsche Post"
        case .hermes: "Hermes"
        case .dpd: "DPD"
        case .gls: "GLS"
        case .ups: "UPS"
        }
    }

    /// Öffentliche Sendungsverfolgung beim Paketdienst.
    /// TODO: URL-Formate vor Release mit echten Sendungsnummern prüfen.
    public func trackingURL(for number: String) -> URL? {
        let n = TrackingNumberDetector.normalize(number)
        switch self {
        case .dhl, .deutschePost:
            return URL(string: "https://www.dhl.de/de/privatkunden/pakete-empfangen/verfolgen.html?piececode=\(n)")
        case .hermes:
            return URL(string: "https://www.myhermes.de/empfangen/sendungsverfolgung/sendungsinformation#\(n)")
        case .dpd:
            return URL(string: "https://tracking.dpd.de/status/de_DE/parcel/\(n)")
        case .gls:
            return URL(string: "https://gls-group.com/DE/de/paketverfolgung?match=\(n)")
        case .ups:
            return URL(string: "https://www.ups.com/track?loc=de_DE&tracknum=\(n)")
        }
    }
}

public enum SalesChannel: String, Codable, Hashable, Sendable {
    case online
    case shop

    public var displayName: String {
        switch self {
        case .online: "Online-Frankierung"
        case .shop: "Filiale / Paketshop"
        }
    }
}

public enum DropOffOption: String, Codable, Hashable, Sendable {
    case paketshop
    case packstation
    case filiale
    case abholung

    public var displayName: String {
        switch self {
        case .paketshop: "Paketshop"
        case .packstation: "Packstation"
        case .filiale: "Filiale"
        case .abholung: "Abholung"
        }
    }
}
