import Foundation

/// Rechenlogik der Kamera-Vermessung – unabhängig von ARKit und damit testbar.
///
/// Drei getrennte Strecken mit je zwei Punkten (Weltkoordinaten in Metern, y zeigt nach oben):
/// 1. Länge: Anfang → Ende der langen Seite
/// 2. Breite: Anfang → Ende der kurzen Seite
/// 3. Höhe: unten → oben an einer senkrechten Kante (gewertet wird nur der Höhenunterschied)
public struct BoxMeasurement: Hashable, Sendable {
    public enum Dimension: Int, CaseIterable, Hashable, Identifiable, Sendable {
        case length
        case width
        case height

        public var id: Int { rawValue }
        public var number: Int { rawValue + 1 }

        public var title: String {
            switch self {
            case .length: "Länge"
            case .width: "Breite"
            case .height: "Höhe"
            }
        }

        /// Kurzanleitung für den ersten bzw. zweiten Punkt.
        public func instruction(forSecondPoint: Bool) -> String {
            switch (self, forSecondPoint) {
            case (.length, false): "Setze den ersten Punkt auf eine Ecke an der langen Seite."
            case (.length, true): "Jetzt die Ecke am anderen Ende der langen Seite."
            case (.width, false): "Setze den ersten Punkt auf eine Ecke an der kurzen Seite."
            case (.width, true): "Jetzt die Ecke am anderen Ende der kurzen Seite."
            case (.height, false): "Setze den ersten Punkt unten an eine senkrechte Kante."
            case (.height, true): "Jetzt genau darüber an die Oberkante des Kartons."
            }
        }

        /// Ausführliche Erklärung für die Anleitung vor dem Schritt.
        public var tutorialText: String {
            switch self {
            case .length:
                "Miss die lange Seite: Ziele mit dem Kreis auf eine Ecke, tippe auf +, dann auf die Ecke am anderen Ende derselben Kante und tippe wieder auf +."
            case .width:
                "Miss die kurze Seite: Ziele auf eine Ecke der kurzen Kante, tippe auf +, dann auf die gegenüberliegende Ecke dieser Kante."
            case .height:
                "Miss die Höhe: Setze den ersten Punkt unten an eine senkrechte Kante, direkt am Boden. Den zweiten Punkt genau darüber an der Oberkante."
            }
        }
    }

    /// Sicherheitsaufschlag gegen Messungenauigkeit (Konzept 3.2).
    public static let defaultSafetyMarginCm: Double = 1
    public static let plausibleRangeCm: ClosedRange<Double> = 1...250

    public private(set) var points: [SIMD3<Float>] = []

    public init() {}

    /// Strecke, die gerade gemessen wird (`nil`, wenn alle drei fertig sind).
    public var currentDimension: Dimension? { Dimension(rawValue: points.count / 2) }
    /// `true`, wenn der erste Punkt der aktuellen Strecke gesetzt ist.
    public var isAwaitingSecondPoint: Bool { points.count % 2 == 1 }
    public var isComplete: Bool { points.count == Dimension.allCases.count * 2 }

    public mutating func add(_ point: SIMD3<Float>) {
        guard !isComplete else { return }
        points.append(point)
    }

    public mutating func undo() {
        if !points.isEmpty { points.removeLast() }
    }

    public mutating func reset() {
        points.removeAll()
    }

    // MARK: - Messwerte (cm, ungerundet)

    public func valueCm(for dimension: Dimension) -> Double? {
        let start = dimension.rawValue * 2
        guard points.count >= start + 2 else { return nil }
        return Self.distanceCm(points[start], points[start + 1], dimension: dimension)
    }

    public var lengthCm: Double? { valueCm(for: .length) }
    public var widthCm: Double? { valueCm(for: .width) }
    public var heightCm: Double? { valueCm(for: .height) }

    /// Live-Wert, während der erste Punkt gesetzt ist und das Fadenkreuz auf `candidate` zeigt.
    public func previewCm(to candidate: SIMD3<Float>) -> Double? {
        guard isAwaitingSecondPoint, let dimension = currentDimension, let start = points.last else { return nil }
        return Self.distanceCm(start, candidate, dimension: dimension)
    }

    // MARK: - Ergebnis

    /// Länge ≥ Breite, jeweils inkl. Sicherheitsaufschlag auf ganze cm aufgerundet.
    public func roundedDimensionsCm(safetyMarginCm: Double = defaultSafetyMarginCm) -> (length: Double, width: Double, height: Double)? {
        guard let length = lengthCm, let width = widthCm, let height = heightCm else { return nil }
        let sides = [length, width].sorted(by: >)
        return (
            Self.roundUp(sides[0], marginCm: safetyMarginCm),
            Self.roundUp(sides[1], marginCm: safetyMarginCm),
            Self.roundUp(height, marginCm: safetyMarginCm)
        )
    }

    public static func isPlausible(_ cm: Double) -> Bool {
        plausibleRangeCm.contains(cm)
    }

    /// `false`, wenn ein Wert unrealistisch klein oder groß ist (z. B. Ecke verfehlt).
    public var isPlausible: Bool {
        guard let length = lengthCm, let width = widthCm, let height = heightCm else { return false }
        return [length, width, height].allSatisfy(Self.isPlausible)
    }

    /// Messwert + Aufschlag, auf ganze cm aufgerundet. Vorher auf 0,1 mm gerundet,
    /// damit Float-Ungenauigkeiten (40,0000006) nicht einen ganzen Zentimeter kosten.
    public static func roundUp(_ cm: Double, marginCm: Double) -> Double {
        let cleaned = (cm * 100).rounded() / 100
        return (cleaned + marginCm).rounded(.up)
    }

    /// Länge/Breite: räumlicher Abstand. Höhe: nur der senkrechte Unterschied –
    /// so stört es nicht, wenn der obere Punkt etwas versetzt gesetzt wird.
    static func distanceCm(_ a: SIMD3<Float>, _ b: SIMD3<Float>, dimension: Dimension) -> Double {
        let dx = Double(a.x - b.x)
        let dy = Double(a.y - b.y)
        let dz = Double(a.z - b.z)
        switch dimension {
        case .length, .width:
            return (dx * dx + dy * dy + dz * dz).squareRoot() * 100
        case .height:
            return abs(dy) * 100
        }
    }
}
