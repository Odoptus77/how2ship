import Foundation

/// DHL Location Finder – Unified API (kostenlos, API-Key über developer.dhl.com).
/// Liefert Filialen, Paketshops und Packstationen von DHL/Deutsche Post inkl. Öffnungszeiten.
///
/// TODO: Antwortformat mit einem echten API-Aufruf gegenprüfen (Stand der Umsetzung: Doku 2021/2024).
public enum DHLLocationFinder {
    public static let apiKeyHeader = "DHL-API-Key"

    public static func findByGeoURL(latitude: Double, longitude: Double, radiusMeters: Int, limit: Int = 50) -> URL? {
        var components = URLComponents(string: "https://api.dhl.com/location-finder/v1/find-by-geo")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(format: "%.6f", latitude)),
            URLQueryItem(name: "longitude", value: String(format: "%.6f", longitude)),
            URLQueryItem(name: "radius", value: String(radiusMeters)),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "providerType", value: "parcel"),
        ]
        return components?.url
    }

    public static func parse(_ data: Data) throws -> [PickupLocation] {
        let response = try JSONDecoder().decode(Response.self, from: data)
        return response.locations.map(makeLocation)
    }

    // MARK: - Mapping

    private static func makeLocation(_ item: Item) -> PickupLocation {
        let type = item.location?.type?.lowercased() ?? ""
        let keyword = item.location?.keyword ?? ""
        let kind: PickupLocationKind
        if type == "locker" || keyword.localizedCaseInsensitiveContains("packstation") {
            kind = .packstation
        } else if type == "postoffice" || type == "postbank" {
            kind = .filiale
        } else {
            kind = .paketshop
        }

        let id = item.location?.ids?.first?.locationId
            ?? item.url
            ?? "\(item.place.geo.latitude),\(item.place.geo.longitude)"

        return PickupLocation(
            id: "dhl-\(id)",
            name: item.name ?? kind.displayName,
            kind: kind,
            carriers: kind == .filiale ? [.dhl, .deutschePost] : [.dhl],
            street: item.place.address?.streetAddress,
            postalCode: item.place.address?.postalCode,
            city: item.place.address?.addressLocality,
            latitude: item.place.geo.latitude,
            longitude: item.place.geo.longitude,
            openingPeriods: item.openingHours.flatMap(periods),
            source: .dhl
        )
    }

    private static func periods(_ hours: [Hours]) -> [OpeningPeriod]? {
        let periods = hours.compactMap { entry -> OpeningPeriod? in
            guard let weekday = weekday(entry.dayOfWeek),
                  let opens = minutes(entry.opens),
                  var closes = minutes(entry.closes) else { return nil }
            if closes == 1439 { closes = 1440 } // „23:59:00“ = bis Mitternacht
            return OpeningPeriod(weekday: weekday, opensMinute: opens, closesMinute: closes)
        }
        return periods.isEmpty ? nil : periods
    }

    /// „http://schema.org/Monday“ → 1
    static func weekday(_ schemaDay: String) -> Int? {
        let names = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        guard let name = schemaDay.split(separator: "/").last.map(String.init),
              let index = names.firstIndex(of: name) else { return nil }
        return index + 1
    }

    /// „08:30:00“ → 510
    static func minutes(_ time: String) -> Int? {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2 else { return nil }
        return parts[0] * 60 + parts[1]
    }

    // MARK: - Antwortformat

    struct Response: Decodable {
        let locations: [Item]
    }

    struct Item: Decodable {
        let url: String?
        let location: LocationInfo?
        let name: String?
        let place: Place
        let openingHours: [Hours]?
    }

    struct LocationInfo: Decodable {
        let ids: [LocationID]?
        let keyword: String?
        let type: String?
    }

    struct LocationID: Decodable {
        let locationId: String
    }

    struct Place: Decodable {
        let address: Address?
        let geo: Geo
    }

    struct Address: Decodable {
        let streetAddress: String?
        let postalCode: String?
        let addressLocality: String?
    }

    struct Geo: Decodable {
        let latitude: Double
        let longitude: Double
    }

    struct Hours: Decodable {
        let opens: String
        let closes: String
        let dayOfWeek: String
    }
}
