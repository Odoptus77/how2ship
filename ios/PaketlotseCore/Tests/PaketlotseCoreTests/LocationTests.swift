import XCTest
@testable import PaketlotseCore

private var berlin: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
    return calendar
}

/// 2026-10-03 = Samstag, 2026-10-04 = Sonntag, 2026-10-05 = Montag
private func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
    berlin.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
}

final class OSMOpeningHoursParserTests: XCTestCase {
    func testWeekdaysAndSaturday() throws {
        let periods = try XCTUnwrap(OSMOpeningHoursParser.parse("Mo-Fr 08:00-18:00; Sa 09:00-13:00"))
        XCTAssertEqual(periods.count, 6)
        XCTAssertEqual(periods.first, OpeningPeriod(weekday: 1, opensMinute: 480, closesMinute: 1080))
        XCTAssertEqual(periods.last, OpeningPeriod(weekday: 6, opensMinute: 540, closesMinute: 780))
    }

    func testLunchBreak() throws {
        XCTAssertEqual(try XCTUnwrap(OSMOpeningHoursParser.parse("Mo-Fr 08:00-12:00,14:00-18:00")).count, 10)
    }

    func testAlwaysOpen() throws {
        let periods = try XCTUnwrap(OSMOpeningHoursParser.parse("24/7"))
        XCTAssertEqual(periods.count, 7)
        XCTAssertTrue(periods.allSatisfy { $0.opensMinute == 0 && $0.closesMinute == 1440 })
    }

    func testLaterRuleOverridesEarlierOne() throws {
        let periods = try XCTUnwrap(OSMOpeningHoursParser.parse("Mo-Sa 08:00-20:00; Sa 09:00-14:00"))
        XCTAssertEqual(periods.filter { $0.weekday == 6 }, [OpeningPeriod(weekday: 6, opensMinute: 540, closesMinute: 840)])
        XCTAssertEqual(periods.count, 6)
    }

    func testPublicHolidayRuleIsIgnored() throws {
        XCTAssertEqual(try XCTUnwrap(OSMOpeningHoursParser.parse("Mo-Fr 08:00-18:00; PH off")).count, 5)
    }

    func testDayRangeAcrossWeekend() throws {
        let days = try XCTUnwrap(OSMOpeningHoursParser.parse("Fr-Mo 10:00-16:00")).map(\.weekday)
        XCTAssertEqual(Set(days), [5, 6, 7, 1])
    }

    func testUnsupportedFormatsReturnNil() {
        XCTAssertNil(OSMOpeningHoursParser.parse("sunrise-sunset"))
        XCTAssertNil(OSMOpeningHoursParser.parse("Jan-Mar Mo 10:00-12:00"))
        XCTAssertNil(OSMOpeningHoursParser.parse("Su off"))
        XCTAssertNil(OSMOpeningHoursParser.parse(""))
    }
}

final class DHLLocationFinderTests: XCTestCase {
    private let fixture = """
    {"locations":[
      {"url":"/locations/8003-4103400",
       "location":{"ids":[{"locationId":"8003-4103400","provider":"parcel"}],"keyword":"Packstation","keywordId":"103","type":"locker"},
       "name":"Packstation 103",
       "place":{"address":{"countryCode":"DE","postalCode":"53113","addressLocality":"Bonn","streetAddress":"Charles-de-Gaulle-Str. 20"},
                "geo":{"latitude":50.7137,"longitude":7.1296}},
       "openingHours":[{"opens":"00:00:00","closes":"23:59:00","dayOfWeek":"http://schema.org/Monday"}],
       "serviceTypes":["parcel:pick-up"]},
      {"url":"/locations/8003-4155660",
       "location":{"ids":[{"locationId":"8003-4155660"}],"keyword":"Postfiliale","type":"postoffice"},
       "name":"Deutsche Post Filiale 502",
       "place":{"address":{"postalCode":"53113","addressLocality":"Bonn","streetAddress":"Heinrich-Brüning-Str. 1"},
                "geo":{"latitude":50.72,"longitude":7.12}},
       "openingHours":[{"opens":"09:00:00","closes":"18:00:00","dayOfWeek":"http://schema.org/Monday"},
                       {"opens":"09:00:00","closes":"13:00:00","dayOfWeek":"http://schema.org/Saturday"}]}
    ]}
    """

    func testParsesLocations() throws {
        let locations = try DHLLocationFinder.parse(Data(fixture.utf8))
        XCTAssertEqual(locations.count, 2)

        let packstation = locations[0]
        XCTAssertEqual(packstation.id, "dhl-8003-4103400")
        XCTAssertEqual(packstation.kind, .packstation)
        XCTAssertEqual(packstation.carriers, [.dhl])
        XCTAssertEqual(packstation.openingPeriods, [OpeningPeriod(weekday: 1, opensMinute: 0, closesMinute: 1440)])
        XCTAssertEqual(packstation.source, .dhl)

        let filiale = locations[1]
        XCTAssertEqual(filiale.kind, .filiale)
        XCTAssertEqual(filiale.carriers, [.dhl, .deutschePost])
        XCTAssertEqual(filiale.addressLine, "Heinrich-Brüning-Str. 1, 53113 Bonn")
    }

    func testOpeningHoursOfFiliale() throws {
        let filiale = try DHLLocationFinder.parse(Data(fixture.utf8))[1]
        XCTAssertEqual(filiale.isOpen(at: date(5, 10), calendar: berlin), true)
        XCTAssertEqual(filiale.isOpen(at: date(5, 19), calendar: berlin), false)
        XCTAssertEqual(filiale.openingHoursText(on: date(3, 10), calendar: berlin), "09:00–13:00")
        XCTAssertEqual(filiale.openingHoursText(on: date(4, 10), calendar: berlin), "geschlossen")
    }

    func testURLContainsCoordinatesAndRadius() throws {
        let url = try XCTUnwrap(DHLLocationFinder.findByGeoURL(latitude: 50.7137, longitude: 7.1296, radiusMeters: 2000))
        let query = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        XCTAssertTrue(query.contains(URLQueryItem(name: "latitude", value: "50.713700")))
        XCTAssertTrue(query.contains(URLQueryItem(name: "radius", value: "2000")))
    }

    func testWeekdayMapping() {
        XCTAssertEqual(DHLLocationFinder.weekday("http://schema.org/Monday"), 1)
        XCTAssertEqual(DHLLocationFinder.weekday("http://schema.org/Sunday"), 7)
        XCTAssertNil(DHLLocationFinder.weekday("Feiertag"))
    }
}

final class OverpassLocationsTests: XCTestCase {
    private let fixture = """
    {"elements":[
      {"type":"node","id":1,"lat":52.5,"lon":13.4,"tags":{"amenity":"post_office","post_office":"post_partner",
        "post_office:brand":"Hermes PaketShop","name":"Kiosk am Markt","addr:street":"Marktstraße","addr:housenumber":"5",
        "addr:postcode":"10115","addr:city":"Berlin","opening_hours":"Mo-Fr 08:00-18:00; Sa 09:00-13:00"}},
      {"type":"node","id":2,"lat":52.51,"lon":13.41,"tags":{"amenity":"parcel_locker","brand":"DHL Packstation","ref":"123"}},
      {"type":"way","id":3,"center":{"lat":52.52,"lon":13.42},"tags":{"shop":"convenience","post_office":"post_partner",
        "post_office:service_provider":"DPD;GLS","name":"Späti"}},
      {"type":"node","id":4,"lat":52.53,"lon":13.43,"tags":{"amenity":"parcel_locker","brand":"myflexbox"}},
      {"type":"node","id":5,"lat":52.54,"lon":13.44,"tags":{"amenity":"post_office","name":"Postfiliale"}},
      {"type":"node","id":6,"lat":52.55,"lon":13.45}
    ]}
    """

    private func parsed() throws -> [PickupLocation] {
        try OverpassLocations.parse(Data(fixture.utf8))
    }

    func testSkipsUnknownProvidersAndUntaggedElements() throws {
        XCTAssertEqual(try parsed().map(\.id), ["osm-node-1", "osm-node-2", "osm-way-3", "osm-node-5"])
    }

    func testHermesPaketshop() throws {
        let shop = try parsed()[0]
        XCTAssertEqual(shop.carriers, [.hermes])
        XCTAssertEqual(shop.kind, .paketshop)
        XCTAssertEqual(shop.name, "Kiosk am Markt")
        XCTAssertEqual(shop.addressLine, "Marktstraße 5, 10115 Berlin")
        XCTAssertEqual(shop.openingPeriods?.count, 6)
        XCTAssertEqual(shop.isOpen(at: date(5, 10), calendar: berlin), true)
        XCTAssertEqual(shop.isOpen(at: date(4, 10), calendar: berlin), false)
        XCTAssertEqual(shop.isOpen(at: date(3, 14), calendar: berlin), false)
    }

    func testPackstationAndMultiCarrierShop() throws {
        let locations = try parsed()
        XCTAssertEqual(locations[1].kind, .packstation)
        XCTAssertEqual(locations[1].carriers, [.dhl])
        XCTAssertEqual(locations[1].name, "DHL Packstation")
        XCTAssertEqual(locations[2].carriers, [.dpd, .gls])
        XCTAssertEqual(locations[2].kind, .paketshop)
        XCTAssertEqual(locations[3].kind, .filiale)
    }

    func testClassifierDoesNotMatchSubstrings() {
        XCTAssertEqual(OverpassLocations.classifyCarriers(["name": "Getränke Groups"]), [])
        XCTAssertEqual(OverpassLocations.classifyCarriers(["brand": "UPS Access Point"]), [.ups])
    }

    func testQueryContainsAroundFilter() {
        let query = OverpassLocations.query(latitude: 52.5, longitude: 13.4, radiusMeters: 1500)
        XCTAssertTrue(query.contains("around:1500,52.500000,13.400000"))
        XCTAssertTrue(query.contains("\"amenity\"=\"parcel_locker\""))
    }

    func testMergePrefersOfficialDHLData() throws {
        let osm = try parsed()
        let dhl = [PickupLocation(id: "dhl-1", name: "Packstation 1", kind: .packstation, carriers: [.dhl],
                                  latitude: 52.51, longitude: 13.41, source: .dhl)]
        let merged = PickupLocationMerger.merge(dhl: dhl, openStreetMap: osm)
        XCTAssertEqual(merged.map(\.id), ["dhl-1", "osm-node-1", "osm-way-3"])
        XCTAssertEqual(PickupLocationMerger.merge(dhl: [], openStreetMap: osm).count, 4)
    }

    func testDistance() {
        let location = PickupLocation(id: "x", name: "x", kind: .paketshop, carriers: [.hermes],
                                      latitude: 52.5200, longitude: 13.4050, source: .openStreetMap)
        // ca. 1,11 km pro 0,01° Breite
        XCTAssertEqual(location.distanceMeters(toLatitude: 52.5100, longitude: 13.4050), 1112, accuracy: 5)
    }
}
