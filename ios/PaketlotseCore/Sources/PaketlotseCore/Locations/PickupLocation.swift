import Foundation

public enum PickupLocationKind: String, Codable, Hashable, Sendable {
    case paketshop
    case packstation
    case filiale
    case locker

    public var displayName: String {
        switch self {
        case .paketshop: "Paketshop"
        case .packstation: "Packstation"
        case .filiale: "Filiale"
        case .locker: "Paketautomat"
        }
    }

    public var isLocker: Bool { self == .packstation || self == .locker }
}

public enum LocationSource: String, Codable, Hashable, Sendable {
    case dhl
    case openStreetMap
}

/// Öffnungszeitraum an einem Wochentag. `weekday`: 1 = Montag … 7 = Sonntag. Minuten ab Mitternacht.
public struct OpeningPeriod: Codable, Hashable, Sendable {
    public var weekday: Int
    public var opensMinute: Int
    public var closesMinute: Int

    public init(weekday: Int, opensMinute: Int, closesMinute: Int) {
        self.weekday = weekday
        self.opensMinute = opensMinute
        self.closesMinute = closesMinute
    }

    /// ISO-Wochentag (1 = Montag … 7 = Sonntag) für ein Datum.
    public static func isoWeekday(for date: Date, calendar: Calendar) -> Int {
        let weekday = calendar.component(.weekday, from: date) // 1 = Sonntag
        return weekday == 1 ? 7 : weekday - 1
    }

    public static func formatMinute(_ minute: Int) -> String {
        String(format: "%02d:%02d", minute / 60, minute % 60)
    }
}

public struct PickupLocation: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public var name: String
    public var kind: PickupLocationKind
    public var carriers: [Carrier]
    public var street: String?
    public var postalCode: String?
    public var city: String?
    public var latitude: Double
    public var longitude: Double
    /// Strukturierte Öffnungszeiten, falls bekannt bzw. auswertbar.
    public var openingPeriods: [OpeningPeriod]?
    /// Originaltext (z. B. OSM `opening_hours`), falls nicht strukturiert auswertbar.
    public var openingHoursText: String?
    public var source: LocationSource

    public init(
        id: String, name: String, kind: PickupLocationKind, carriers: [Carrier],
        street: String? = nil, postalCode: String? = nil, city: String? = nil,
        latitude: Double, longitude: Double,
        openingPeriods: [OpeningPeriod]? = nil, openingHoursText: String? = nil,
        source: LocationSource
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.carriers = carriers
        self.street = street
        self.postalCode = postalCode
        self.city = city
        self.latitude = latitude
        self.longitude = longitude
        self.openingPeriods = openingPeriods
        self.openingHoursText = openingHoursText
        self.source = source
    }

    public var addressLine: String {
        let cityLine = [postalCode, city].compactMap { $0 }.joined(separator: " ")
        return [street, cityLine.isEmpty ? nil : cityLine].compactMap { $0 }.joined(separator: ", ")
    }

    /// `nil`, wenn keine auswertbaren Öffnungszeiten vorliegen.
    public func isOpen(at date: Date, calendar: Calendar = .current) -> Bool? {
        guard let periods = openingPeriods, !periods.isEmpty else { return nil }
        let weekday = OpeningPeriod.isoWeekday(for: date, calendar: calendar)
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let minute = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        return periods.contains { $0.weekday == weekday && minute >= $0.opensMinute && minute < $0.closesMinute }
    }

    /// Öffnungszeiten eines Tages als Text, z. B. „08:00–12:00, 14:00–18:00“ oder „geschlossen“.
    public func openingHoursText(on date: Date, calendar: Calendar = .current) -> String? {
        guard let periods = openingPeriods, !periods.isEmpty else { return nil }
        let weekday = OpeningPeriod.isoWeekday(for: date, calendar: calendar)
        let today = periods.filter { $0.weekday == weekday }.sorted { $0.opensMinute < $1.opensMinute }
        if today.isEmpty { return "geschlossen" }
        if today.count == 1, today[0].opensMinute == 0, today[0].closesMinute >= 1439 { return "24 Stunden geöffnet" }
        return today
            .map { "\(OpeningPeriod.formatMinute($0.opensMinute))–\(OpeningPeriod.formatMinute($0.closesMinute))" }
            .joined(separator: ", ")
    }

    /// Luftlinie in Metern (Haversine).
    public func distanceMeters(toLatitude lat: Double, longitude lon: Double) -> Double {
        let earthRadius = 6_371_000.0
        let dLat = (latitude - lat) * .pi / 180
        let dLon = (longitude - lon) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2)
            + cos(lat * .pi / 180) * cos(latitude * .pi / 180) * sin(dLon / 2) * sin(dLon / 2)
        return 2 * earthRadius * atan2(a.squareRoot(), (1 - a).squareRoot())
    }
}

public enum PickupLocationMerger {
    /// Offizielle DHL-Daten haben Vorrang: Liefert die DHL-API Ergebnisse, werden reine DHL/Post-Einträge
    /// aus OpenStreetMap verworfen (Dubletten). Gemischte Paketshops (z. B. Hermes + DHL) bleiben erhalten.
    public static func merge(dhl: [PickupLocation], openStreetMap: [PickupLocation]) -> [PickupLocation] {
        guard !dhl.isEmpty else { return openStreetMap }
        let dhlOnly: Set<Carrier> = [.dhl, .deutschePost]
        let others = openStreetMap.filter { !Set($0.carriers).isSubset(of: dhlOnly) }
        return dhl + others
    }
}
