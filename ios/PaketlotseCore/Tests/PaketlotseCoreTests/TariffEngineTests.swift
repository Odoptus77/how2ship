import XCTest
@testable import PaketlotseCore

final class TariffEngineTests: XCTestCase {
    private var engine: TariffEngine!

    override func setUpWithError() throws {
        engine = TariffEngine(catalog: try TariffCatalog.bundledSample())
    }

    private let shoebox = ParcelDimensions(lengthCm: 33, widthCm: 20, heightCm: 12, weightKg: 1.2)

    func testSampleCatalogIsMarkedAsSample() throws {
        XCTAssertTrue(try TariffCatalog.bundledSample().isSample)
    }

    func testShoeboxCheapestIsHermesS() {
        let offers = engine.offers(for: shoebox)
        XCTAssertEqual(offers.first?.id, "hermes-s")
        XCTAssertEqual(offers.first?.badges.contains(.cheapest), true)
    }

    func testOffersAreSortedByPrice() {
        let prices = engine.offers(for: shoebox).map(\.priceCents)
        XCTAssertEqual(prices, prices.sorted())
    }

    func testOnlyCheapestProductPerFamily() {
        let ids = engine.offers(for: shoebox).map(\.id)
        XCTAssertTrue(ids.contains("hermes-s"))
        XCTAssertFalse(ids.contains("hermes-m"))
        XCTAssertEqual(ids.filter { $0.hasPrefix("dhl-paket-") }, ["dhl-paket-2kg"])
    }

    func testTooHeavyParcelHasNoOffers() {
        let heavy = ParcelDimensions(lengthCm: 40, widthCm: 30, heightCm: 20, weightKg: 40)
        XCTAssertTrue(engine.offers(for: heavy).isEmpty)
    }

    func testShopChannelOnly() {
        XCTAssertEqual(engine.offers(for: shoebox, channels: [.shop]).map(\.id), ["dhl-paket-2kg-filiale"])
    }

    func testOnlinePriceWinsOverShopPriceWithinFamily() {
        let ids = engine.offers(for: shoebox, channels: [.online, .shop]).map(\.id)
        XCTAssertTrue(ids.contains("dhl-paket-2kg"))
        XCTAssertFalse(ids.contains("dhl-paket-2kg-filiale"))
    }

    func testParcelExactlyAtLimitIsTight() {
        // 38 + 12 = 50 cm → passt genau in Hermes S
        let parcel = ParcelDimensions(lengthCm: 38, widthCm: 30, heightCm: 12, weightKg: 1)
        let hermes = engine.offers(for: parcel).first { $0.id == "hermes-s" }
        XCTAssertEqual(hermes?.isTight, true)
    }

    func testUPSUsesVolumetricWeight() {
        // 60 × 40 × 40 / 5000 = 19,2 kg Volumengewicht
        let parcel = ParcelDimensions(lengthCm: 60, widthCm: 40, heightCm: 40, weightKg: 2)
        let ids = engine.offers(for: parcel).map(\.id)
        XCTAssertTrue(ids.contains("ups-20kg"))
        XCTAssertFalse(ids.contains("ups-5kg"))
    }
}

final class SavingsAdvisorTests: XCTestCase {
    private var advisor: SavingsAdvisor!

    override func setUpWithError() throws {
        advisor = SavingsAdvisor(engine: TariffEngine(catalog: try TariffCatalog.bundledSample()))
    }

    func testShorteningTwoCentimetresUnlocksHermesS() {
        // 40 + 12 = 52 cm; mit 2 cm weniger: 38 + 12 = 50 cm → Hermes S (4,50 €) statt Päckchen M (5,19 €)
        let parcel = ParcelDimensions(lengthCm: 40, widthCm: 30, heightCm: 12, weightKg: 1)
        let tip = advisor.bestTip(for: parcel)
        XCTAssertEqual(tip?.adjustment, .shortenLongestSide(cm: 2))
        XCTAssertEqual(tip?.offer.id, "hermes-s")
        XCTAssertEqual(tip?.savingCents, 69)
    }

    func testNoTipWhenAlreadyCheapestPossible() {
        let shoebox = ParcelDimensions(lengthCm: 33, widthCm: 20, heightCm: 12, weightKg: 1.2)
        XCTAssertNil(advisor.bestTip(for: shoebox))
    }
}
