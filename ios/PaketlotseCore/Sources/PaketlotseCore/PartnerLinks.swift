import Foundation

/// Partnerprogramm (Affiliate), z. B. über Awin.
///
/// `template` beschreibt, wie der Partnerlink gebaut wird:
/// - `{url}` → Ziel-URL (URL-kodiert), z. B. die Buchungsseite des Paketdienstes
/// - `{clickref}` → eigene Klick-Referenz zur Zuordnung von Provisionen
///
/// Beispiel Awin: `https://www.awin1.com/cread.php?awinmid=12345&awinaffid=67890&clickref={clickref}&ued={url}`
public struct PartnerProgram: Codable, Hashable, Identifiable, Sendable {
    public enum Kind: String, Codable, Hashable, Sendable {
        /// Leitet die Buchung beim Paketdienst über einen Partnerlink (Deeplink auf dessen Seite).
        case carrier
        /// Eigenes Versandportal mit eigenen Preisen (z. B. Packlink) – wird separat als Anzeige gezeigt.
        case portal
    }

    public var id: String
    public var name: String
    public var kind: Kind
    /// Erst aktivieren, wenn die Partner-IDs im Template eingetragen sind.
    public var enabled: Bool
    public var template: String
    /// Startseite des Portals (nur `portal`).
    public var landingURL: URL?
    public var description: String?

    public init(
        id: String, name: String, kind: Kind, enabled: Bool, template: String,
        landingURL: URL? = nil, description: String? = nil
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.enabled = enabled
        self.template = template
        self.landingURL = landingURL
        self.description = description
    }

    /// Aktiv und ohne verbliebene Platzhalter wie `MERCHANT_ID`.
    public var isUsable: Bool {
        enabled && template.contains("{url}") && !template.contains("_ID")
    }
}

public struct PartnerLinkConfig: Codable, Sendable {
    public var programs: [PartnerProgram]
    /// Paketdienst (`Carrier.rawValue`) → ID eines Programms vom Typ `carrier`.
    public var carrierPrograms: [String: String]

    public init(programs: [PartnerProgram], carrierPrograms: [String: String] = [:]) {
        self.programs = programs
        self.carrierPrograms = carrierPrograms
    }

    public static func decode(from data: Data) throws -> PartnerLinkConfig {
        try JSONDecoder().decode(PartnerLinkConfig.self, from: data)
    }

    public static func bundled() throws -> PartnerLinkConfig {
        guard let url = Bundle.module.url(forResource: "partner-links", withExtension: "json") else {
            throw TariffCatalog.LoadError.missingResource
        }
        return try decode(from: Data(contentsOf: url))
    }
}

/// Fertiger Link zu einem Partner-Portal.
public struct PortalLink: Identifiable, Hashable, Sendable {
    public let program: PartnerProgram
    public let url: URL
    public var id: String { program.id }
}

/// Link für „Jetzt buchen“.
public struct BookingLink: Hashable, Sendable {
    public let url: URL
    /// `true` → als „Partner-Link“ kennzeichnen (§ 5a UWG).
    public let isPartnerLink: Bool
    public let programID: String?
}

public struct PartnerLinkBuilder: Sendable {
    public let config: PartnerLinkConfig

    public init(config: PartnerLinkConfig) {
        self.config = config
    }

    /// Partnerlink, falls für den Paketdienst ein nutzbares Programm konfiguriert ist – sonst der normale Link.
    /// Die Reihenfolge der Angebote bleibt davon unberührt.
    public func bookingLink(for tariff: Tariff, clickRef: String) -> BookingLink? {
        guard let target = tariff.bookingURL else { return nil }
        if let programID = config.carrierPrograms[tariff.carrier.rawValue],
           let program = config.programs.first(where: { $0.id == programID && $0.kind == .carrier }),
           program.isUsable,
           let url = Self.apply(program.template, url: target, clickRef: clickRef) {
            return BookingLink(url: url, isPartnerLink: true, programID: program.id)
        }
        return BookingLink(url: target, isPartnerLink: false, programID: nil)
    }

    /// Aktive Partner-Portale mit fertigem Link (für die Anzeige-Karte unter den Ergebnissen).
    public func portalLinks(clickRef: String) -> [PortalLink] {
        config.programs.compactMap { program in
            guard program.kind == .portal, program.isUsable, let landing = program.landingURL,
                  let url = Self.apply(program.template, url: landing, clickRef: clickRef) else { return nil }
            return PortalLink(program: program, url: url)
        }
    }

    static func apply(_ template: String, url: URL, clickRef: String) -> URL? {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        guard let encodedURL = url.absoluteString.addingPercentEncoding(withAllowedCharacters: allowed),
              let encodedRef = clickRef.addingPercentEncoding(withAllowedCharacters: allowed) else { return nil }
        let result = template
            .replacingOccurrences(of: "{url}", with: encodedURL)
            .replacingOccurrences(of: "{clickref}", with: encodedRef)
        return URL(string: result)
    }
}
