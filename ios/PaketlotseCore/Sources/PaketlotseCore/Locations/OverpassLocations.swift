import Foundation

/// Paketshops und Paketautomaten aus OpenStreetMap über die Overpass API (ohne API-Key).
/// Daten © OpenStreetMap-Mitwirkende, ODbL – Namensnennung in der App ist Pflicht.
///
/// Hinweis: Die öffentlichen Overpass-Server sind für Entwicklung und moderate Nutzung gedacht.
/// Für den Produktivbetrieb Anfragen über das Paketlotse-Backend bündeln/cachen oder eine eigene Instanz nutzen.
public enum OverpassLocations {
    public static let endpoint = URL(string: "https://overpass-api.de/api/interpreter")!

    public static func query(latitude: Double, longitude: Double, radiusMeters: Int, limit: Int = 150) -> String {
        let around = "around:\(radiusMeters),\(String(format: "%.6f", latitude)),\(String(format: "%.6f", longitude))"
        return """
        [out:json][timeout:20];
        (
          nwr["post_office"="post_partner"](\(around));
          nwr["amenity"="parcel_locker"](\(around));
          nwr["amenity"="post_office"](\(around));
        );
        out center tags \(limit);
        """
    }

    /// Formular-Body für den POST an den Overpass-Endpunkt.
    public static func requestBody(for query: String) -> Data {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        let encoded = query.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
        return Data("data=\(encoded)".utf8)
    }

    public static func parse(_ data: Data) throws -> [PickupLocation] {
        let response = try JSONDecoder().decode(Response.self, from: data)
        return response.elements.compactMap(makeLocation)
    }

    // MARK: - Mapping

    static func makeLocation(_ element: Element) -> PickupLocation? {
        guard let tags = element.tags,
              let latitude = element.lat ?? element.center?.lat,
              let longitude = element.lon ?? element.center?.lon
        else { return nil }

        let isLocker = tags["amenity"] == "parcel_locker"
        let isPostPartner = tags["post_office"] == "post_partner"
        let isPostOffice = tags["amenity"] == "post_office"

        var carriers = classifyCarriers(tags)
        if carriers.isEmpty {
            // Postfilialen ohne Markenangabe sind in Deutschland praktisch immer Deutsche Post/DHL.
            guard isPostOffice else { return nil }
            carriers = [.dhl, .deutschePost]
        }

        let kind: PickupLocationKind
        if isLocker {
            kind = carriers.contains(.dhl) ? .packstation : .locker
        } else if isPostPartner {
            kind = .paketshop
        } else {
            kind = .filiale
        }

        let street = [tags["addr:street"], tags["addr:housenumber"]].compactMap { $0 }.joined(separator: " ")
        let hoursText = tags["opening_hours"]

        return PickupLocation(
            id: "osm-\(element.type)-\(element.id)",
            name: tags["name"] ?? tags["brand"] ?? tags["post_office:brand"] ?? kind.displayName,
            kind: kind,
            carriers: carriers,
            street: street.isEmpty ? nil : street,
            postalCode: tags["addr:postcode"],
            city: tags["addr:city"],
            latitude: latitude,
            longitude: longitude,
            openingPeriods: hoursText.flatMap(OSMOpeningHoursParser.parse),
            openingHoursText: hoursText,
            source: .openStreetMap
        )
    }

    /// Erkennt Paketdienste anhand von brand/operator/name und den post_office:*-Tags.
    public static func classifyCarriers(_ tags: [String: String]) -> [Carrier] {
        let keys = ["brand", "operator", "name", "network", "post_office:brand", "post_office:service_provider", "post_office:operator"]
        let text = keys.compactMap { tags[$0] }.joined(separator: " ").lowercased()
        let tokens = Set(text.split { !$0.isLetter }.map(String.init))

        var result: [Carrier] = []
        if tokens.contains("dhl") || text.contains("deutsche post") || text.contains("packstation") || text.contains("postfiliale") {
            result.append(.dhl)
        }
        if tokens.contains("hermes") { result.append(.hermes) }
        if tokens.contains("dpd") { result.append(.dpd) }
        if tokens.contains("gls") { result.append(.gls) }
        if tokens.contains("ups") { result.append(.ups) }
        return result
    }

    // MARK: - Antwortformat

    struct Response: Decodable {
        let elements: [Element]
    }

    struct Element: Decodable {
        let type: String
        let id: Int64
        let lat: Double?
        let lon: Double?
        let center: Center?
        let tags: [String: String]?
    }

    struct Center: Decodable {
        let lat: Double
        let lon: Double
    }
}
