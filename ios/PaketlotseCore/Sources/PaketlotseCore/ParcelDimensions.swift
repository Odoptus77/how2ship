import Foundation

/// Maße (cm) und Gewicht (kg) eines Pakets.
public struct ParcelDimensions: Codable, Hashable, Sendable {
    public var lengthCm: Double
    public var widthCm: Double
    public var heightCm: Double
    public var weightKg: Double

    public init(lengthCm: Double, widthCm: Double, heightCm: Double, weightKg: Double) {
        self.lengthCm = lengthCm
        self.widthCm = widthCm
        self.heightCm = heightCm
        self.weightKg = weightKg
    }

    public var isValid: Bool {
        lengthCm > 0 && widthCm > 0 && heightCm > 0 && weightKg > 0
    }

    /// Seiten absteigend sortiert: [längste, mittlere, kürzeste].
    public var sidesDescending: [Double] {
        [lengthCm, widthCm, heightCm].sorted(by: >)
    }

    public var longestSide: Double { sidesDescending[0] }
    public var shortestSide: Double { sidesDescending[2] }

    /// Messregel von Hermes, DPD und GLS: längste plus kürzeste Seite.
    public var longestPlusShortest: Double { longestSide + shortestSide }

    public func volumetricWeightKg(divisor: Double) -> Double {
        lengthCm * widthCm * heightCm / divisor
    }

    public func shorteningLongestSide(by cm: Double) -> ParcelDimensions {
        let sides = sidesDescending
        return ParcelDimensions(lengthCm: sides[0] - cm, widthCm: sides[1], heightCm: sides[2], weightKg: weightKg)
    }

    public func withWeight(_ kg: Double) -> ParcelDimensions {
        ParcelDimensions(lengthCm: lengthCm, widthCm: widthCm, heightCm: heightCm, weightKg: kg)
    }

    /// Vergrößert jede Seite, um „knappe“ Tarife zu erkennen (Messungenauigkeit).
    public func enlarged(byCm cm: Double) -> ParcelDimensions {
        ParcelDimensions(lengthCm: lengthCm + cm, widthCm: widthCm + cm, heightCm: heightCm + cm, weightKg: weightKg)
    }
}
