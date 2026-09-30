import Foundation
import PaketlotseCore

/// Lädt Abgabestellen aus DHL Location Finder (falls API-Key hinterlegt) und OpenStreetMap parallel.
struct LocationService {
    enum LoadError: LocalizedError {
        case unavailable

        var errorDescription: String? {
            "Standorte konnten nicht geladen werden. Prüfe deine Internetverbindung."
        }
    }

    /// Aus Info.plist (`DHLAPIKey`, befüllt über `Config/Secrets.xcconfig`).
    /// Hinweis: Ein Key in der App ist auslesbar – für den Produktivbetrieb über das Backend abfragen.
    private let dhlAPIKey: String? = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "DHLAPIKey") as? String,
              !key.isEmpty, !key.hasPrefix("$(") else { return nil }
        return key
    }()

    private let session = URLSession.shared
    private let timeout: TimeInterval = 20

    var usesDHLAPI: Bool { dhlAPIKey != nil }

    func locations(latitude: Double, longitude: Double, radiusMeters: Int) async throws -> [PickupLocation] {
        async let dhl = fetchDHL(latitude: latitude, longitude: longitude, radiusMeters: radiusMeters)
        async let osm = fetchOpenStreetMap(latitude: latitude, longitude: longitude, radiusMeters: radiusMeters)
        let (dhlResult, osmResult) = await (dhl, osm)

        guard dhlResult != nil || osmResult != nil else { throw LoadError.unavailable }
        let merged = PickupLocationMerger.merge(dhl: dhlResult ?? [], openStreetMap: osmResult ?? [])
        return merged.sorted {
            $0.distanceMeters(toLatitude: latitude, longitude: longitude)
                < $1.distanceMeters(toLatitude: latitude, longitude: longitude)
        }
    }

    /// `nil` bei Fehler, `[]` wenn kein API-Key konfiguriert ist.
    private func fetchDHL(latitude: Double, longitude: Double, radiusMeters: Int) async -> [PickupLocation]? {
        guard let key = dhlAPIKey else { return [] }
        guard let url = DHLLocationFinder.findByGeoURL(
            latitude: latitude, longitude: longitude, radiusMeters: min(radiusMeters, 5000)
        ) else { return nil }

        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.setValue(key, forHTTPHeaderField: DHLLocationFinder.apiKeyHeader)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        do {
            let (data, response) = try await session.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            return try DHLLocationFinder.parse(data)
        } catch {
            return nil
        }
    }

    private func fetchOpenStreetMap(latitude: Double, longitude: Double, radiusMeters: Int) async -> [PickupLocation]? {
        let query = OverpassLocations.query(latitude: latitude, longitude: longitude, radiusMeters: radiusMeters)
        var request = URLRequest(url: OverpassLocations.endpoint, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.httpBody = OverpassLocations.requestBody(for: query)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("Paketlotse/0.1 (iOS; kontakt@paketlotse.de)", forHTTPHeaderField: "User-Agent")
        do {
            let (data, response) = try await session.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            return try OverpassLocations.parse(data)
        } catch {
            return nil
        }
    }
}
