import XCTest
@testable import PaketlotseCore

final class TrackingNumberDetectorTests: XCTestCase {
    func testDetectsUPS() {
        XCTAssertEqual(TrackingNumberDetector.candidates(for: "1Z999AA10123456784"), [.ups])
    }

    func testNormalizesSpacesDashesAndCase() {
        XCTAssertEqual(TrackingNumberDetector.normalize(" 1z 999aa1-0123456784 "), "1Z999AA10123456784")
        XCTAssertEqual(TrackingNumberDetector.candidates(for: " 1z 999aa1-0123456784 "), [.ups])
    }

    func testFourteenDigitsAreAmbiguous() {
        let candidates = TrackingNumberDetector.candidates(for: "01234567890123")
        XCTAssertTrue(candidates.contains(.hermes))
        XCTAssertTrue(candidates.contains(.dpd))
    }

    func testTwelveDigitsMatchDHLAndGLS() {
        let candidates = TrackingNumberDetector.candidates(for: "123456789012")
        XCTAssertTrue(candidates.contains(.dhl))
        XCTAssertTrue(candidates.contains(.gls))
    }

    func testRejectsPlainWords() {
        XCTAssertTrue(TrackingNumberDetector.candidates(for: "hallo").isEmpty)
        XCTAssertTrue(TrackingNumberDetector.candidates(for: "").isEmpty)
    }

    func testExtractsNumberFromText() {
        let text = "Ihre Sendungsnummer: 1Z999AA10123456784. Vielen Dank!"
        XCTAssertEqual(TrackingNumberDetector.extract(from: text), ["1Z999AA10123456784"])
    }

    func testExtractsNumberPrintedWithSpaces() {
        XCTAssertEqual(TrackingNumberDetector.extract(from: "1Z 999 AA1 01 2345 6784"), ["1Z999AA10123456784"])
    }
}

final class TrackingPromptPolicyTests: XCTestCase {
    private let policy = TrackingPromptPolicy()

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private func booking(at date: Date) -> PendingBooking {
        PendingBooking(tariffID: "hermes-s", carrier: .hermes, product: "S-Paket", clickedAt: date)
    }

    func testPromptOnlyAfterOneMinuteAndWithin48Hours() {
        let clicked = date(2026, 10, 1, 14, 0)
        let b = booking(at: clicked)
        XCTAssertFalse(policy.shouldPrompt(b, now: clicked.addingTimeInterval(30)))
        XCTAssertTrue(policy.shouldPrompt(b, now: clicked.addingTimeInterval(90)))
        XCTAssertFalse(policy.shouldPrompt(b, now: clicked.addingTimeInterval(49 * 3600)))
        XCTAssertTrue(policy.isExpired(b, now: clicked.addingTimeInterval(49 * 3600)))
    }

    func testPromptIsShownOnlyOnce() {
        let clicked = date(2026, 10, 1, 14, 0)
        var b = booking(at: clicked)
        b.promptShownAt = clicked.addingTimeInterval(120)
        XCTAssertFalse(policy.shouldPrompt(b, now: clicked.addingTimeInterval(300)))
    }

    func testNoPromptForCapturedOrDismissedBookings() {
        let clicked = date(2026, 10, 1, 14, 0)
        var b = booking(at: clicked)
        b.status = .numberCaptured
        XCTAssertFalse(policy.shouldPrompt(b, now: clicked.addingTimeInterval(300)))
        b.status = .dismissed
        XCTAssertFalse(policy.shouldPrompt(b, now: clicked.addingTimeInterval(300)))
    }

    func testRemindersAfterTwoHoursAndNextMorning() {
        let b = booking(at: date(2026, 10, 1, 14, 0))
        XCTAssertEqual(
            policy.reminderDates(for: b, calendar: calendar),
            [date(2026, 10, 1, 16, 0), date(2026, 10, 2, 9, 0)]
        )
    }

    func testLateEveningBookingStillGetsMorningReminder() {
        let b = booking(at: date(2026, 10, 1, 23, 30))
        XCTAssertEqual(
            policy.reminderDates(for: b, calendar: calendar),
            [date(2026, 10, 2, 1, 30), date(2026, 10, 2, 9, 0)]
        )
    }
}
