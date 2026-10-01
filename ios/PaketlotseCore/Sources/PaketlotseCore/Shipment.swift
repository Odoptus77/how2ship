import Foundation

public enum ShipmentDirection: String, Codable, Sendable {
    case outgoing
    case incoming
}

public enum ShipmentStatus: String, Codable, CaseIterable, Sendable {
    case registered
    case inTransit
    case outForDelivery
    case delivered
    case problem

    public var displayName: String {
        switch self {
        case .registered: "Angemeldet"
        case .inTransit: "Unterwegs"
        case .outForDelivery: "In Zustellung"
        case .delivered: "Zugestellt"
        case .problem: "Problem"
        }
    }
}

public struct TrackingEvent: Codable, Hashable, Sendable {
    public var date: Date
    public var text: String
    public var location: String?

    public init(date: Date, text: String, location: String? = nil) {
        self.date = date
        self.text = text
        self.location = location
    }
}

public struct Shipment: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public var number: String
    public var carrier: Carrier
    public var name: String?
    public var direction: ShipmentDirection
    public var status: ShipmentStatus
    public var events: [TrackingEvent]
    public var createdAt: Date
    public var deliveredAt: Date?
    public var bookingID: UUID?
    /// ID beim Paketlotse-Server (nil = noch nicht angemeldet, z. B. offline oder ohne Backend).
    public var serverID: String?
    public var expectedDelivery: Date?
    /// Letzte Statusänderung laut Server.
    public var lastUpdated: Date?

    public init(
        id: UUID = UUID(), number: String, carrier: Carrier, name: String? = nil,
        direction: ShipmentDirection = .outgoing, bookingID: UUID? = nil, createdAt: Date = Date()
    ) {
        self.id = id
        self.number = TrackingNumberDetector.normalize(number)
        self.carrier = carrier
        self.name = name
        self.direction = direction
        self.status = .registered
        self.events = []
        self.createdAt = createdAt
        self.deliveredAt = nil
        self.bookingID = bookingID
    }

    /// Übernimmt den Stand vom Server (Status, Ereignisse, Zustellung).
    public mutating func apply(
        serverID: String, status: ShipmentStatus, events: [TrackingEvent],
        expectedDelivery: Date?, deliveredAt: Date?, lastUpdated: Date?
    ) {
        self.serverID = serverID
        self.status = status
        self.events = events.sorted { $0.date > $1.date }
        self.expectedDelivery = expectedDelivery
        self.deliveredAt = deliveredAt ?? (status == .delivered ? self.deliveredAt ?? Date() : nil)
        self.lastUpdated = lastUpdated
    }

    public var displayName: String {
        if let name, !name.isEmpty { return name }
        return "\(carrier.displayName) …\(number.suffix(6))"
    }

    /// Kostenlose Version: Löschung 30 Tage nach Zustellung.
    public func deletionDate(retentionDays: Int = 30, calendar: Calendar = .current) -> Date? {
        deliveredAt.flatMap { calendar.date(byAdding: .day, value: retentionDays, to: $0) }
    }
}
