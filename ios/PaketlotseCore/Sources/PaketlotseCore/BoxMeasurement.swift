import Foundation

/// Rechenlogik der Kamera-Vermessung – unabhängig von ARKit und damit testbar.
///
/// Ablauf (4 Punkte in Weltkoordinaten, Meter, y zeigt nach oben):
/// 1. untere Ecke → 2. benachbarte untere Ecke (Länge) → 3. nächste untere Ecke (Breite)
/// 4. ein Punkt auf dem Deckel (Höhe = Abstand zur Bodenebene der drei Ecken).
public struct BoxMeasurement: Hashable, Sendable {
    public enum Step: Int, CaseIterable, Sendable {
        case firstCorner
        case secondCorner
        case thirdCorner
        case top

        public var number: Int { rawValue + 1 }

        public var title: String {
            switch self {
            case .firstCorner: "Erste Ecke"
            case .secondCorner: "Länge"
            case .thirdCorner: "Breite"
            case .top: "Höhe"
            }
        }

        public var instruction: String {
            switch self {
            case .firstCorner: "Ziele mit dem Kreis auf eine untere Ecke des Kartons und tippe auf +."
            case .secondCorner: "Jetzt die benachbarte untere Ecke entlang der langen Seite."
            case .thirdCorner: "Nun die nächste untere Ecke entlang der kurzen Seite."
            case .top: "Zum Schluss auf den Deckel des Kartons zielen – für die Höhe."
            }
        }
    }

    /// Sicherheitsaufschlag gegen Messungenauigkeit (Konzept 3.2).
    public static let defaultSafetyMarginCm: Double = 1
    public static let plausibleRangeCm: ClosedRange<Double> = 1...250

    public private(set) var points: [SIMD3<Float>] = []

    public init() {}

    public var currentStep: Step? { Step(rawValue: points.count) }
    public var isComplete: Bool { points.count == Step.allCases.count }

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

    /// Höhe der Bodenebene: Mittelwert der gesetzten Bodenecken (max. 3).
    public var floorLevel: Float? {
        let corners = points.prefix(3)
        guard !corners.isEmpty else { return nil }
        return corners.reduce(0) { $0 + $1.y } / Float(corners.count)
    }

    // MARK: - Messwerte (cm, ungerundet)

    public var lengthCm: Double? {
        points.count >= 2 ? Self.horizontalCm(points[0], points[1]) : nil
    }

    public var widthCm: Double? {
        points.count >= 3 ? Self.horizontalCm(points[1], points[2]) : nil
    }

    public var heightCm: Double? {
        guard points.count >= 4, let floor = floorLevel else { return nil }
        return Self.verticalCm(points[3], floorLevel: floor)
    }

    /// Live-Wert für den aktuellen Schritt, während das Fadenkreuz auf `candidate` zeigt.
    public func previewCm(to candidate: SIMD3<Float>) -> Double? {
        switch currentStep {
        case .secondCorner:
            return Self.horizontalCm(points[0], candidate)
        case .thirdCorner:
            return Self.horizontalCm(points[1], candidate)
        case .top:
            return floorLevel.map { Self.verticalCm(candidate, floorLevel: $0) }
        case .firstCorner, nil:
            return nil
        }
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

    /// `false`, wenn ein Wert unrealistisch klein oder groß ist (z. B. Ecke verfehlt).
    public var isPlausible: Bool {
        guard let length = lengthCm, let width = widthCm, let height = heightCm else { return false }
        return [length, width, height].allSatisfy { Self.plausibleRangeCm.contains($0) }
    }

    /// Messwert + Aufschlag, auf ganze cm aufgerundet. Vorher auf 0,1 mm gerundet,
    /// damit Float-Ungenauigkeiten (40,0000006) nicht einen ganzen Zentimeter kosten.
    public static func roundUp(_ cm: Double, marginCm: Double) -> Double {
        let cleaned = (cm * 100).rounded() / 100
        return (cleaned + marginCm).rounded(.up)
    }

    static func horizontalCm(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Double {
        let dx = Double(a.x - b.x)
        let dz = Double(a.z - b.z)
        return (dx * dx + dz * dz).squareRoot() * 100
    }

    static func verticalCm(_ point: SIMD3<Float>, floorLevel: Float) -> Double {
        abs(Double(point.y - floorLevel)) * 100
    }
}
