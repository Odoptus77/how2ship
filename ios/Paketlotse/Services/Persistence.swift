import Foundation
import PaketlotseCore

/// Eine vom Nutzer gespeicherte Paketgröße (Premium), z. B. „Mein Standardkarton“.
struct SavedParcel: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var parcel: ParcelDimensions
}

struct AppData: Codable {
    var bookings: [PendingBooking] = []
    var shipments: [Shipment] = []
    var savedParcels: [SavedParcel] = []

    init(bookings: [PendingBooking] = [], shipments: [Shipment] = [], savedParcels: [SavedParcel] = []) {
        self.bookings = bookings
        self.shipments = shipments
        self.savedParcels = savedParcels
    }

    /// Tolerant gegenüber älteren Speicherständen ohne neue Felder.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bookings = try container.decodeIfPresent([PendingBooking].self, forKey: .bookings) ?? []
        shipments = try container.decodeIfPresent([Shipment].self, forKey: .shipments) ?? []
        savedParcels = try container.decodeIfPresent([SavedParcel].self, forKey: .savedParcels) ?? []
    }
}

/// Speichert Buchungen und Sendungen lokal als JSON (Application Support).
/// Später ersetzt/ergänzt durch den Paketlotse-Server (Sync, Tracking-Webhooks).
struct Persistence {
    private let fileURL: URL = {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("paketlotse.json")
    }()

    func load() -> AppData {
        guard let data = try? Data(contentsOf: fileURL) else { return AppData() }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode(AppData.self, from: data)) ?? AppData()
    }

    func save(_ appData: AppData) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(appData) else { return }
        try? data.write(to: fileURL, options: [.atomic, .completeFileProtection])
    }
}
