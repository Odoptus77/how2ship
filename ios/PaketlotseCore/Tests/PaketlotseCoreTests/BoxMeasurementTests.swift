import XCTest
@testable import PaketlotseCore

final class BoxMeasurementTests: XCTestCase {
    /// Karton 40 × 30 × 12 cm, jede Strecke einzeln gemessen (Meter).
    private func measuredBox() -> BoxMeasurement {
        var m = BoxMeasurement()
        m.add(SIMD3(0, 0, 0)); m.add(SIMD3(0.40, 0, 0))            // Länge
        m.add(SIMD3(0.40, 0, 0)); m.add(SIMD3(0.40, 0, 0.30))      // Breite
        m.add(SIMD3(0.40, 0, 0.30)); m.add(SIMD3(0.40, 0.12, 0.30)) // Höhe
        return m
    }

    func testDimensionsProgressInPairs() {
        var m = BoxMeasurement()
        XCTAssertEqual(m.currentDimension, .length)
        XCTAssertFalse(m.isAwaitingSecondPoint)
        m.add(SIMD3(0, 0, 0))
        XCTAssertEqual(m.currentDimension, .length)
        XCTAssertTrue(m.isAwaitingSecondPoint)
        m.add(SIMD3(0.4, 0, 0))
        XCTAssertEqual(m.currentDimension, .width)
        XCTAssertFalse(m.isAwaitingSecondPoint)
        m.add(SIMD3(0, 0, 0)); m.add(SIMD3(0, 0, 0.3))
        XCTAssertEqual(m.currentDimension, .height)
        m.add(SIMD3(0, 0, 0)); m.add(SIMD3(0, 0.12, 0))
        XCTAssertNil(m.currentDimension)
        XCTAssertTrue(m.isComplete)
    }

    func testNoMoreThanSixPoints() {
        var m = measuredBox()
        m.add(SIMD3(1, 1, 1))
        XCTAssertEqual(m.points.count, 6)
    }

    func testRawDimensions() throws {
        let m = measuredBox()
        XCTAssertEqual(try XCTUnwrap(m.lengthCm), 40, accuracy: 0.01)
        XCTAssertEqual(try XCTUnwrap(m.widthCm), 30, accuracy: 0.01)
        XCTAssertEqual(try XCTUnwrap(m.heightCm), 12, accuracy: 0.01)
        XCTAssertTrue(m.isPlausible)
    }

    func testSegmentsAreIndependent() throws {
        // Breite an ganz anderer Stelle gemessen als die Länge
        var m = BoxMeasurement()
        m.add(SIMD3(0, 0, 0)); m.add(SIMD3(0.40, 0, 0))
        m.add(SIMD3(2, 0, 2)); m.add(SIMD3(2, 0, 2.25))
        XCTAssertEqual(try XCTUnwrap(m.widthCm), 25, accuracy: 0.01)
    }

    func testLengthAlongTopEdgeCountsSpatialDistance() throws {
        var m = BoxMeasurement()
        m.add(SIMD3(0, 0.12, 0)); m.add(SIMD3(0.30, 0.12, 0.40))   // Diagonal im Raum: 50 cm
        XCTAssertEqual(try XCTUnwrap(m.lengthCm), 50, accuracy: 0.01)
    }

    func testHeightUsesOnlyVerticalDifference() throws {
        var m = measuredBox()
        m.undo()
        m.add(SIMD3(0.45, 0.12, 0.35))   // oben etwas versetzt getroffen
        XCTAssertEqual(try XCTUnwrap(m.heightCm), 12, accuracy: 0.01)
    }

    func testRoundedDimensionsIncludeSafetyMargin() throws {
        let rounded = try XCTUnwrap(measuredBox().roundedDimensionsCm())
        XCTAssertEqual(rounded.length, 41)
        XCTAssertEqual(rounded.width, 31)
        XCTAssertEqual(rounded.height, 13)
    }

    func testLengthIsAlwaysTheLongerSide() throws {
        var m = BoxMeasurement()
        m.add(SIMD3(0, 0, 0)); m.add(SIMD3(0.20, 0, 0))    // kurze Seite zuerst
        m.add(SIMD3(0, 0, 0)); m.add(SIMD3(0, 0, 0.35))
        m.add(SIMD3(0, 0, 0)); m.add(SIMD3(0, 0.10, 0))
        let rounded = try XCTUnwrap(m.roundedDimensionsCm())
        XCTAssertEqual(rounded.length, 36)
        XCTAssertEqual(rounded.width, 21)
    }

    func testRoundUpAvoidsFloatNoise() {
        XCTAssertEqual(BoxMeasurement.roundUp(40.000_000_6, marginCm: 1), 41)
        XCTAssertEqual(BoxMeasurement.roundUp(32.3, marginCm: 1), 34)
        XCTAssertEqual(BoxMeasurement.roundUp(32.3, marginCm: 0), 33)
    }

    func testPreviewOnlyWhileAwaitingSecondPoint() throws {
        var m = BoxMeasurement()
        XCTAssertNil(m.previewCm(to: SIMD3(0.1, 0, 0)))
        m.add(SIMD3(0, 0, 0))
        XCTAssertEqual(try XCTUnwrap(m.previewCm(to: SIMD3(0.25, 0, 0))), 25, accuracy: 0.01)
        m.add(SIMD3(0.4, 0, 0))
        XCTAssertNil(m.previewCm(to: SIMD3(0.1, 0, 0)))
        m.add(SIMD3(0, 0, 0)); m.add(SIMD3(0, 0, 0.3))
        m.add(SIMD3(0, 0, 0))
        XCTAssertEqual(try XCTUnwrap(m.previewCm(to: SIMD3(0.05, 0.08, 0))), 8, accuracy: 0.01)
    }

    func testUndoAndReset() {
        var m = measuredBox()
        m.undo()
        XCTAssertEqual(m.currentDimension, .height)
        XCTAssertTrue(m.isAwaitingSecondPoint)
        XCTAssertNil(m.heightCm)
        m.reset()
        XCTAssertEqual(m.currentDimension, .length)
    }

    func testImplausibleWhenCornerMissed() {
        var m = measuredBox()
        m.undo()
        m.add(SIMD3(0.40, 0.001, 0.30))   // Höhe 0,1 cm
        XCTAssertFalse(m.isPlausible)
    }
}
