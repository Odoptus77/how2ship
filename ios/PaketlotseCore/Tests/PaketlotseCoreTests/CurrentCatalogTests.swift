import XCTest
@testable import PaketlotseCore

/// Plausibilitätstests für den echten Tarifkatalog (tarife-2026.json).
/// Ändern sich Preise, müssen die erwarteten Werte hier bewusst mit angepasst werden.
final class CurrentCatalogTests: XCTestCase {
    private var catalog: TariffCatalog!
    private var engine: TariffEngine!
    private let shoebox = ParcelDimensions(lengthCm: 33, widthCm: 20, heightCm: 12, weightKg: 1.2)

    override func setUpWithError() throws {
        catalog = try TariffCatalog.bundledCurrent()
        engine = TariffEngine(catalog: catalog)
    }

    func testCatalogIsRealAndConsistent() {
        XCTAssertFalse(catalog.isSample)
        XCTAssertNotNil(catalog.sourceNote)
        let ids = catalog.tariffs.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "Tarif-IDs müssen eindeutig sein")
        XCTAssertTrue(catalog.tariffs.allSatisfy { $0.priceCents > 0 && $0.maxWeightKg > 0 })
        XCTAssertEqual(Set(catalog.tariffs.map(\.carrier)), [.dhl, .hermes, .dpd, .gls, .ups])
    }

    func testShoeboxCheapestIsShopDelivery() {
        let offers = engine.offers(for: shoebox)
        XCTAssertEqual(offers.first?.id, "gls-shop-s")
        XCTAssertEqual(offers.first?.priceCents, 389)
        XCTAssertEqual(offers.first?.tariff.delivery, .shop)
    }

    func testHomeDeliveryExcludesShopTariffs() {
        let offers = engine.offers(for: shoebox, requirements: .init(requiresHomeDelivery: true))
        XCTAssertTrue(offers.allSatisfy { $0.tariff.delivery == .home })
        XCTAssertEqual(offers.first?.id, "dhl-paeckchen-m")
    }

    func testPaeckchenHasNoTrackingAndNoLiability() throws {
        let paeckchen = try XCTUnwrap(catalog.tariffs.first { $0.id == "dhl-paeckchen-m" })
        XCTAssertFalse(paeckchen.hasTracking)
        XCTAssertEqual(paeckchen.liabilityEuro, 0)

        let offers = engine.offers(for: shoebox, requirements: .init(requiresTracking: true, requiresHomeDelivery: true))
        XCTAssertEqual(offers.first?.id, "dpd-classic-s")
        XCTAssertEqual(offers.first?.priceCents, 545)
    }

    func testBookFitsSmallestSizes() {
        let book = ParcelDimensions(lengthCm: 25, widthCm: 18, heightCm: 4, weightKg: 0.6)
        XCTAssertEqual(engine.offers(for: book).first?.id, "gls-shop-xs")
    }

    func testHighValueOnlyWithDHLInsurance() {
        let laptop = ParcelDimensions(lengthCm: 45, widthCm: 33, heightCm: 8, weightKg: 3)
        let offers = engine.offers(for: laptop, requirements: .init(declaredValueEuro: 1000, requiresTracking: true))
        XCTAssertEqual(offers.map(\.id), ["dhl-paket-5kg"])
        XCTAssertEqual(offers.first?.priceCents, 769 + 699)
        XCTAssertEqual(offers.first?.coverageEuro, 2500)
    }

    func testPickupSurcharges() {
        let moving = ParcelDimensions(lengthCm: 60, widthCm: 33, heightCm: 34, weightKg: 12)
        let offers = engine.offers(for: moving, requirements: .init(requiresPickup: true))
        XCTAssertEqual(offers.map(\.id), ["hermes-home-l", "dhl-paket-20kg", "dpd-classic-xl"])
        XCTAssertEqual(offers.map(\.priceCents), [1099 + 96, 1899 + 300, 1869 + 731])
    }

    func testGirthRuleForXL() {
        // 100 × 40 × 30 cm: Gurtmaß 240 cm → DPD/GLS XL, UPS scheidet über Volumengewicht (24 kg) aus
        let big = ParcelDimensions(lengthCm: 100, widthCm: 40, heightCm: 30, weightKg: 15)
        let ids = engine.offers(for: big, requirements: .init(requiresHomeDelivery: true)).map(\.id)
        XCTAssertEqual(ids, ["dpd-classic-xl", "dhl-paket-20kg", "gls-home-xl", "hermes-home-xl"])
    }

    func testOnlyGLSTakesMoreThan31Kilograms() {
        let heavy = ParcelDimensions(lengthCm: 60, widthCm: 40, heightCm: 40, weightKg: 35)
        XCTAssertEqual(Set(engine.offers(for: heavy).map(\.tariff.carrier)), [.gls])
    }

    func testPackstationOnlyDHL() {
        let offers = engine.offers(for: shoebox, requirements: .init(requiresPackstation: true))
        XCTAssertEqual(offers.map(\.id), ["dhl-paeckchen-m", "dhl-paket-2kg"])
    }

    func testGirthCalculation() {
        XCTAssertEqual(ParcelDimensions(lengthCm: 100, widthCm: 40, heightCm: 30, weightKg: 1).girthCm, 240)
    }
}
