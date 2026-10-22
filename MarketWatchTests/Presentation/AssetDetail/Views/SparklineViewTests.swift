import XCTest
@testable import MarketWatch

final class SparklineViewTests: XCTestCase {

    func test_points_scaleToRect() {
        let points = SparklineView.points(for: [1, 3, 2], in: CGRect(x: 0, y: 0, width: 100, height: 50))

        XCTAssertEqual(points, [CGPoint(x: 0, y: 50), CGPoint(x: 50, y: 0), CGPoint(x: 100, y: 25)])
    }

    func test_points_flatValues_drawMiddleLine() {
        let points = SparklineView.points(for: [2, 2, 2], in: CGRect(x: 0, y: 0, width: 100, height: 50))

        XCTAssertEqual(points.map(\.y), [25, 25, 25])
    }

    func test_points_ignoreValuesThatAreNotFinite() {
        let points = SparklineView.points(for: [1, .nan, 3, .infinity, 2], in: CGRect(x: 0, y: 0, width: 100, height: 50))

        XCTAssertEqual(points, [CGPoint(x: 0, y: 50), CGPoint(x: 50, y: 0), CGPoint(x: 100, y: 25)])
    }

    func test_points_hugeRange_staysFinite() {
        let values = [-Double.greatestFiniteMagnitude, Double.greatestFiniteMagnitude]

        let points = SparklineView.points(for: values, in: CGRect(x: 0, y: 0, width: 100, height: 50))

        XCTAssertTrue(points.allSatisfy { $0.x.isFinite && $0.y.isFinite })
        XCTAssertEqual(points.count, 2)
    }

    func test_points_needAtLeastTwoValues() {
        XCTAssertEqual(SparklineView.points(for: [1], in: CGRect(x: 0, y: 0, width: 100, height: 50)), [])
    }
}
