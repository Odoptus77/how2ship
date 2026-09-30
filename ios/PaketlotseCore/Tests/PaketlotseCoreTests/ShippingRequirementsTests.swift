import XCTest
@testable import PaketlotseCore

final class ShippingRequirementsTests: XCTestCase {
    private var engine: TariffEngine!
    private let shoebox = ParcelDimensions(lengthCm: 33, widthCm: 20, heightCm: 12, weightKg: 1.2)

    override func setUpWithError() throws {
        engine = TariffEngine(catalog: try TariffCatalog.bundledSample())
    }

    func testWithoutRequirementsTotalEqualsBasePrice() {
        for offer in engine.offers(for: shoebox) {
            XCTAssertEqual(offer.priceCents, offer.basePriceCents)
            XCTAssertTrue(offer.addOns.isEmpty)
        }
    }

    func testValueWithinGroundLiabilityNeedsNoInsurance() {
        // 300 € Warenwert: GLS haftet ohnehin bis 750 € → bleibt bei 4,99 €
        let offers = engine.offers(for: shoebox, requirements: .init(declaredValueEuro: 300))
        XCTAssertEqual(offers.first?.id, "gls-s")
        XCTAssertEqual(offers.first?.priceCents, 499)
        XCTAssertNil(offers.first?.insurance)
    }

    func testInsuranceIsAddedToTotalAndFiltersTariffs() {
        // 1.000 € Warenwert: Hermes (max. 500 €) und GLS (keine Höherversicherung) fallen raus
        let offers = engine.offers(for: shoebox, requirements: .init(declaredValueEuro: 1000))
        let ids = offers.map(\.id)
        XCTAssertEqual(offers.first?.id, "dpd-s")
        XCTAssertEqual(offers.first?.priceCents, 525 + 300)
        XCTAssertEqual(offers.first?.coverageEuro, 1000)
        XCTAssertEqual(offers.first?.insurance?.coverageEuro, 1000)
        XCTAssertFalse(ids.contains("hermes-s"))
        XCTAssertFalse(ids.contains("gls-s"))
    }

    func testTooHighValueHasNoOffers() {
        XCTAssertTrue(engine.offers(for: shoebox, requirements: .init(declaredValueEuro: 5000)).isEmpty)
    }

    func testPickupAddsSurchargeAndExcludesTariffsWithoutPickup() {
        let offers = engine.offers(for: shoebox, requirements: .init(requiresPickup: true))
        XCTAssertEqual(offers.first?.id, "hermes-s")
        XCTAssertEqual(offers.first?.priceCents, 450 + 200)
        XCTAssertFalse(offers.map(\.id).contains("gls-s"))
    }

    func testPackstationOnlyDHL() {
        let offers = engine.offers(for: shoebox, requirements: .init(requiresPackstation: true))
        XCTAssertEqual(offers.map(\.id), ["dhl-paeckchen-m", "dhl-paket-2kg"])
    }

    func testSignature() {
        let offers = engine.offers(for: shoebox, requirements: .init(requiresSignature: true))
        XCTAssertEqual(offers.first?.id, "dhl-paket-2kg")
        XCTAssertEqual(offers.first?.priceCents, 619 + 250)
    }

    func testRequirementsAreEmptyByDefault() {
        XCTAssertTrue(ShippingRequirements.none.isEmpty)
        XCTAssertFalse(ShippingRequirements(declaredValueEuro: 100).isEmpty)
        XCTAssertTrue(ShippingRequirements(declaredValueEuro: 0).isEmpty)
    }
}
