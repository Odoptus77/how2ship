import Foundation

public struct SavingsTip: Hashable, Sendable {
    public enum Adjustment: Hashable, Sendable {
        case shortenLongestSide(cm: Int)
        case reduceWeight(grams: Int)
    }

    public let adjustment: Adjustment
    public let offer: Offer
    public let savingCents: Int
}

/// Findet kleine Änderungen (max. 3 cm / 500 g), die ein günstigeres Format ermöglichen.
public struct SavingsAdvisor: Sendable {
    public let engine: TariffEngine
    public var maxShortenCm = 3
    public var maxWeightReductionGrams = 500

    public init(engine: TariffEngine) {
        self.engine = engine
    }

    public func bestTip(for parcel: ParcelDimensions, channels: Set<SalesChannel> = [.online]) -> SavingsTip? {
        guard let current = engine.offers(for: parcel, channels: channels).first else { return nil }
        var best: SavingsTip?

        func consider(_ adjustment: SavingsTip.Adjustment, _ candidate: ParcelDimensions) {
            guard candidate.isValid,
                  let offer = engine.offers(for: candidate, channels: channels).first else { return }
            let saving = current.priceCents - offer.priceCents
            guard saving > 0 else { return }
            // Bei gleicher Ersparnis gewinnt die kleinere Änderung (wird zuerst geprüft).
            if let best, best.savingCents >= saving { return }
            best = SavingsTip(adjustment: adjustment, offer: offer, savingCents: saving)
        }

        for cm in 1...maxShortenCm {
            consider(.shortenLongestSide(cm: cm), parcel.shorteningLongestSide(by: Double(cm)))
        }
        for grams in stride(from: 100, through: maxWeightReductionGrams, by: 100) {
            consider(.reduceWeight(grams: grams), parcel.withWeight(parcel.weightKg - Double(grams) / 1000))
        }
        return best
    }
}
