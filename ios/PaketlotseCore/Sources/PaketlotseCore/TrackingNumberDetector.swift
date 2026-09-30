import Foundation

/// Erkennt Sendungsnummern und ordnet sie Paketdiensten zu.
///
/// Die Muster sind Heuristiken und müssen vor dem Release mit echten Sendungsnummern
/// verifiziert werden. Mehrdeutige Nummern (z. B. 14 Ziffern: Hermes oder DPD) liefern
/// mehrere Kandidaten – die App nutzt dann den Paketdienst aus der offenen Buchung.
public enum TrackingNumberDetector {
    private static let patterns: [(carrier: Carrier, regex: String)] = [
        (.ups, "^1Z[0-9A-Z]{16}$"),
        (.dhl, "^JJD[0-9]{16,21}$"),
        (.dhl, "^[0-9]{12}$"),
        (.dhl, "^[0-9]{20}$"),
        (.deutschePost, "^[A-Z]{2}[0-9]{9}DE$"),
        (.hermes, "^[0-9]{14}$"),
        (.hermes, "^H[0-9]{19}$"),
        (.dpd, "^[0-9]{14}$"),
        (.gls, "^[0-9]{11,12}$"),
        (.gls, "^(?=.*[0-9])[A-Z0-9]{8}$"),
    ]

    /// Großbuchstaben, ohne Leerzeichen, Bindestriche o. Ä.
    public static func normalize(_ raw: String) -> String {
        String(raw.uppercased().filter { $0.isASCII && ($0.isLetter || $0.isNumber) })
    }

    /// Passende Paketdienste in stabiler Reihenfolge, ohne Duplikate.
    public static func candidates(for raw: String) -> [Carrier] {
        let number = normalize(raw)
        guard !number.isEmpty else { return [] }
        var result: [Carrier] = []
        for pattern in patterns where !result.contains(pattern.carrier) {
            if number.range(of: pattern.regex, options: .regularExpression) != nil {
                result.append(pattern.carrier)
            }
        }
        return result
    }

    public static func isPlausible(_ raw: String) -> Bool {
        !candidates(for: raw).isEmpty
    }

    /// Findet Sendungsnummern in einem Text (Zwischenablage, geteilte E-Mail, Barcode-Inhalt).
    public static func extract(from text: String) -> [String] {
        var found: [String] = []
        let tokens = text.components(separatedBy: CharacterSet.alphanumerics.inverted)
        for token in tokens where isPlausible(token) {
            let number = normalize(token)
            if !found.contains(number) { found.append(number) }
        }
        // Mit Leerzeichen gedruckte Nummern („1Z 999 AA1 …“) als Ganzes prüfen.
        if found.isEmpty, text.count <= 40, isPlausible(text) {
            found.append(normalize(text))
        }
        return found
    }
}
