import XCTest
@testable import PaketlotseCore

final class BoxMeasurementTests: XCTestCase {
    /// Karton 40 × 30 × 12 cm auf dem Boden (y = 0), Maße in Metern.
    private func measuredBox() -> BoxMeasurement {
        var m = BoxMeasurement()
        m.add(SIMD3(0, 0, 0))
        m.add(SIMD3(0.40, 0, 0))
        m.add(SIMD3(0.40, 0, 0.30))
        m.add(SIMD3(0.20, 0.12, 0.15))
        return m
    }

    func testStepsProgress() {
        var m = BoxMeasurement()
        XCTAssertEqual(m.currentStep, .firstCorner)
        m.add(SIMD3(0, 0, 0))
        XCTAssertEqual(m.currentStep, .secondCorner)
        m.add(SIMD3(0.4, 0, 0))
        m.add(SIMD3(0.4, 0, 0.3))
        XCTAssertEqual(m.currentStep, .top)
        m.add(SIMD3(0.2, 0.12, 0.15))
        XCTAssertNil(m.currentStep)
        XCTAssertTrue(m.isComplete)
    }

    func testNoMoreThanFourPoints() {
        var m = measuredBox()
        m.add(SIMD3(1, 1, 1))
        XCTAssertEqual(m.points.count, 4)
    }

    func testRawDimensions() throws {
        let m = measuredBox()
        XCTAssertEqual(try XCTUnwrap(m.lengthCm), 40, accuracy: 0.01)
        XCTAssertEqual(try XCTUnwrap(m.widthCm), 30, accuracy: 0.01)
        XCTAssertEqual(try XCTUnwrap(m.heightCm), 12, accuracy: 0.01)
        XCTAssertTrue(m.isPlausible)
    }

    func testRoundedDimensionsIncludeSafetyMargin() throws {
        let rounded = try XCTUnwrap(measuredBox().roundedDimensionsCm())
        XCTAssertEqual(rounded.length, 41)
        XCTAssertEqual(rounded.width, 31)
        XCTAssertEqual(rounded.height, 13)
    }

    func testLengthIsAlwaysTheLongerSide() throws {
        var m = BoxMeasurement()
        m.add(SIMD3(0, 0, 0))
        m.add(SIMD3(0.20, 0, 0))     // kurze Seite zuerst gemessen
        m.add(SIMD3(0.20, 0, 0.35))
        m.add(SIMD3(0.10, 0.10, 0.10))
        let rounded = try XCTUnwrap(m.roundedDimensionsCm())
        XCTAssertEqual(rounded.length, 36)
        XCTAssertEqual(rounded.width, 21)
    }

    func testHeightIgnoresSlightlyUnevenFloor() throws {
        var m = BoxMeasurement()
        m.add(SIMD3(0, 0.002, 0))
        m.add(SIMD3(0.40, -0.002, 0))
        m.add(SIMD3(0.40, 0, 0.30))
        m.add(SIMD3(0.20, 0.15, 0.15))
        XCTAssertEqual(try XCTUnwrap(m.heightCm), 15, accuracy: 0.01)
    }

    func testRoundUpAvoidsFloatNoise() {
        XCTAssertEqual(BoxMeasurement.roundUp(40.000_000_6, marginCm: 1), 41)
        XCTAssertEqual(BoxMeasurement.roundUp(32.3, marginCm: 1), 34)
        XCTAssertEqual(BoxMeasurement.roundUp(32.3, marginCm: 0), 33)
    }

    func testPreviewPerStep() throws {
        var m = BoxMeasurement()
        XCTAssertNil(m.previewCm(to: SIMD3(0.1, 0, 0)))
        m.add(SIMD3(0, 0, 0))
        XCTAssertEqual(try XCTUnwrap(m.previewCm(to: SIMD3(0.25, 0, 0))), 25, accuracy: 0.01)
        m.add(SIMD3(0.4, 0, 0))
        m.add(SIMD3(0.4, 0, 0.3))
        XCTAssertEqual(try XCTUnwrap(m.previewCm(to: SIMD3(0.2, 0.08, 0.1))), 8, accuracy: 0.01)
    }

    func testUndoAndReset() {
        var m = measuredBox()
        m.undo()
        XCTAssertEqual(m.currentStep, .top)
        XCTAssertNil(m.heightCm)
        m.reset()
        XCTAssertEqual(m.currentStep, .firstCorner)
    }

    func testImplausibleWhenCornerMissed() {
        var m = BoxMeasurement()
        m.add(SIMD3(0, 0, 0))
        m.add(SIMD3(0.40, 0, 0))
        m.add(SIMD3(0.40, 0, 0.001))   // Ecke praktisch nicht verschoben → 0,1 cm
        m.add(SIMD3(0.20, 0.12, 0.15))
        XCTAssertFalse(m.isPlausible)
    }
}
