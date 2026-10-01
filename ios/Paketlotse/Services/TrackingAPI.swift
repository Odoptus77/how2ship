import Foundation
import Security
import PaketlotseCore

/// Anonyme Gerätekennung für das Paketlotse-Backend (kein Konto).
/// Geräte-ID und Geheimnis liegen im Keychain und bleiben auch nach App-Updates erhalten.
struct DeviceCredentials {
    let deviceID: String
    let secret: String

    private static let service = "de.paketlotse.device"

    static func loadOrCreate() -> DeviceCredentials {
        if let id = read("deviceID"), let secret = read("secret") {
            return DeviceCredentials(deviceID: id, secret: secret)
        }
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        let credentials = DeviceCredentials(
            deviceID: UUID().uuidString.lowercased(),
            secret: bytes.map { String(format: "%02x", $0) }.joined()
        )
        write("deviceID", credentials.deviceID)
        write("secret", credentials.secret)
        return credentials
    }

    /// Nach „Server-Daten löschen“: neue Identität erzeugen.
    static func reset() {
        for account in ["deviceID", "secret"] {
            SecItemDelete([kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: account] as CFDictionary)
        }
    }

    private static func read(_ account: String) -> String? {
        var item: CFTypeRef?
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: account,
            kSecReturnData: true, kSecMatchLimit: kSecMatchLimitOne,
        ]
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func write(_ account: String, _ value: String) {
        let base: [CFString: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: account]
        SecItemDelete(base as CFDictionary)
        var attributes = base
        attributes[kSecValueData] = Data(value.utf8)
        attributes[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(attributes as CFDictionary, nil)
    }
}

/// Antwortformat des Backends (siehe backend/README.md).
struct ShipmentDTO: Decodable {
    struct Event: Decodable {
        let date: Date
        let text: String
        let location: String?
    }

    let id: String
    let number: String
    let carrier: String
    let name: String?
    let status: String
    let expectedDelivery: Date?
    let deliveredAt: Date?
    let updatedAt: Date?
    let events: [Event]
}

/// Client für das Tracking-Backend. Ohne konfigurierte URL (`API_BASE_URL`) ist er deaktiviert –
/// die App funktioniert dann wie bisher rein lokal.
struct TrackingAPI {
    enum APIError: LocalizedError {
        case notConfigured
        case server(status: Int, message: String?)

        var errorDescription: String? {
            switch self {
            case .notConfigured: "Kein Tracking-Server konfiguriert."
            case let .server(status, message): message ?? "Serverfehler (\(status))"
            }
        }
    }

    let baseURL: URL?
    private let credentials = DeviceCredentials.loadOrCreate()
    private let session: URLSession = .shared

    /// Aus Info.plist (`PaketlotseAPIBaseURL`, befüllt über `API_BASE_URL` in Config/Secrets.xcconfig).
    static func fromInfoPlist() -> TrackingAPI {
        let raw = (Bundle.main.object(forInfoDictionaryKey: "PaketlotseAPIBaseURL") as? String) ?? ""
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        let url = trimmed.isEmpty || trimmed.hasPrefix("$(") ? nil : URL(string: trimmed)
        return TrackingAPI(baseURL: url)
    }

    var isConfigured: Bool { baseURL != nil }

    func register(number: String, carrier: Carrier, name: String?) async throws -> ShipmentDTO {
        struct Body: Encodable { let number: String; let carrier: String; let name: String? }
        return try await send("POST", "/v1/shipments", body: Body(number: number, carrier: carrier.rawValue, name: name))
    }

    func list() async throws -> [ShipmentDTO] {
        struct Response: Decodable { let shipments: [ShipmentDTO] }
        let response: Response = try await send("GET", "/v1/shipments")
        return response.shipments
    }

    func refresh(id: String) async throws -> ShipmentDTO {
        try await send("POST", "/v1/shipments/\(id)/refresh")
    }

    func delete(id: String) async throws {
        try await sendWithoutResponse("DELETE", "/v1/shipments/\(id)")
    }

    func setPushToken(_ token: String?, sandbox: Bool) async throws {
        struct Body: Encodable { let token: String?; let sandbox: Bool }
        try await sendWithoutResponse("PUT", "/v1/device/push-token", body: Body(token: token, sandbox: sandbox))
    }

    func deleteDevice() async throws {
        try await sendWithoutResponse("DELETE", "/v1/device")
    }

    // MARK: - Intern

    private func request(_ method: String, _ path: String, body: (any Encodable)?) throws -> URLRequest {
        guard let baseURL else { throw APIError.notConfigured }
        var request = URLRequest(url: baseURL.appendingPathComponent(path), timeoutInterval: 20)
        request.httpMethod = method
        request.setValue(credentials.deviceID, forHTTPHeaderField: "X-Device-Id")
        request.setValue("Bearer \(credentials.secret)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }
        return request
    }

    private func send<T: Decodable>(_ method: String, _ path: String, body: (any Encodable)? = nil) async throws -> T {
        let (data, response) = try await session.data(for: request(method, path, body: body))
        try Self.check(response, data)
        return try Self.decoder.decode(T.self, from: data)
    }

    private func sendWithoutResponse(_ method: String, _ path: String, body: (any Encodable)? = nil) async throws {
        let (data, response) = try await session.data(for: request(method, path, body: body))
        try Self.check(response, data)
    }

    private static func check(_ response: URLResponse, _ data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            struct ErrorBody: Decodable { let error: String }
            throw APIError.server(status: http.statusCode, message: try? JSONDecoder().decode(ErrorBody.self, from: data).error)
        }
    }

    /// Der Server liefert ISO-8601 mit Millisekunden („2026-10-01T15:11:28.750Z“).
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let value = try decoder.singleValueContainer().decode(String.self)
            let withFraction = ISO8601DateFormatter()
            withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = withFraction.date(from: value) ?? ISO8601DateFormatter().date(from: value) { return date }
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Ungültiges Datum: \(value)"))
        }
        return decoder
    }()
}

extension Shipment {
    /// Stand vom Server übernehmen.
    mutating func apply(_ dto: ShipmentDTO) {
        apply(
            serverID: dto.id,
            status: ShipmentStatus(rawValue: dto.status) ?? status,
            events: dto.events.map { TrackingEvent(date: $0.date, text: $0.text, location: $0.location) },
            expectedDelivery: dto.expectedDelivery,
            deliveredAt: dto.deliveredAt,
            lastUpdated: dto.updatedAt
        )
    }
}
