import XCTest
@testable import PaketlotseCore

final class PartnerLinkTests: XCTestCase {
    private let awin = "https://www.awin1.com/cread.php?awinmid=111&awinaffid=222&clickref={clickref}&ued={url}"

    private func tariff(_ carrier: Carrier, url: String? = "https://www.myhermes.de/versenden/") -> Tariff {
        Tariff(
            id: "t", carrier: carrier, family: "f", product: "S", channel: .online, priceCents: 100, maxWeightKg: 1,
            rule: .longestPlusShortest(maxSumCm: 50, maxLengthCm: nil), liabilityEuro: 500, hasTracking: true,
            transitDays: nil, dropOff: [], bookingURL: url.flatMap(URL.init(string:))
        )
    }

    func testPlainLinkWithoutProgram() throws {
        let builder = PartnerLinkBuilder(config: PartnerLinkConfig(programs: []))
        let link = try XCTUnwrap(builder.bookingLink(for: tariff(.hermes), clickRef: "abc"))
        XCTAssertFalse(link.isPartnerLink)
        XCTAssertEqual(link.url.absoluteString, "https://www.myhermes.de/versenden/")
    }

    func testCarrierProgramWrapsBookingURL() throws {
        let program = PartnerProgram(id: "hermes-awin", name: "Hermes", kind: .carrier, enabled: true, template: awin)
        let builder = PartnerLinkBuilder(config: PartnerLinkConfig(programs: [program], carrierPrograms: ["hermes": "hermes-awin"]))
        let link = try XCTUnwrap(builder.bookingLink(for: tariff(.hermes), clickRef: "b-1 2"))
        XCTAssertTrue(link.isPartnerLink)
        XCTAssertEqual(link.programID, "hermes-awin")
        XCTAssertEqual(
            link.url.absoluteString,
            "https://www.awin1.com/cread.php?awinmid=111&awinaffid=222&clickref=b-1%202&ued=https%3A%2F%2Fwww.myhermes.de%2Fversenden%2F"
        )
        // Andere Paketdienste bleiben ohne Partnerlink
        XCTAssertFalse(try XCTUnwrap(builder.bookingLink(for: tariff(.dpd), clickRef: "x")).isPartnerLink)
    }

    func testDisabledOrPlaceholderProgramIsIgnored() throws {
        let disabled = PartnerProgram(id: "p", name: "P", kind: .carrier, enabled: false, template: awin)
        let placeholder = PartnerProgram(
            id: "q", name: "Q", kind: .carrier, enabled: true,
            template: "https://www.awin1.com/cread.php?awinmid=MERCHANT_ID&awinaffid=PUBLISHER_ID&ued={url}"
        )
        for program in [disabled, placeholder] {
            let builder = PartnerLinkBuilder(config: PartnerLinkConfig(programs: [program], carrierPrograms: ["hermes": program.id]))
            XCTAssertFalse(try XCTUnwrap(builder.bookingLink(for: tariff(.hermes), clickRef: "x")).isPartnerLink)
        }
    }

    func testNoLinkWithoutBookingURL() {
        let builder = PartnerLinkBuilder(config: PartnerLinkConfig(programs: []))
        XCTAssertNil(builder.bookingLink(for: tariff(.dhl, url: nil), clickRef: "x"))
    }

    func testPortalLinksOnlyForUsablePortals() {
        let portal = PartnerProgram(id: "packlink", name: "Packlink", kind: .portal, enabled: true, template: awin,
                                    landingURL: URL(string: "https://www.packlink.de/"))
        let inactive = PartnerProgram(id: "eurosender", name: "Eurosender", kind: .portal, enabled: false, template: awin,
                                      landingURL: URL(string: "https://www.eurosender.com/de"))
        let links = PartnerLinkBuilder(config: PartnerLinkConfig(programs: [portal, inactive])).portalLinks(clickRef: "r")
        XCTAssertEqual(links.map { $0.program.id }, ["packlink"])
        XCTAssertTrue(links[0].url.absoluteString.hasSuffix("ued=https%3A%2F%2Fwww.packlink.de%2F"))
    }

    func testBundledConfigIsInactiveByDefault() throws {
        let config = try PartnerLinkConfig.bundled()
        XCTAssertFalse(config.programs.isEmpty)
        XCTAssertTrue(config.programs.allSatisfy { !$0.isUsable }, "Ohne echte IDs darf kein Programm aktiv sein")
    }
}
