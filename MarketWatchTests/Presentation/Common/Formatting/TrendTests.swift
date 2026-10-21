import XCTest
@testable import MarketWatch

final class TrendTests: XCTestCase {

    func test_trend() {
        XCTAssertEqual(Trend(change: 0.1), .up)
        XCTAssertEqual(Trend(change: -0.1), .down)
        XCTAssertEqual(Trend(change: 0), .neutral)
        XCTAssertEqual(Trend(change: nil), .neutral)
    }

    func test_percentChange_decidesAfterRoundingToTwoDecimals() {
        XCTAssertEqual(Trend(percentChange: -0.003), .neutral)
        XCTAssertEqual(Trend(percentChange: 0.004), .neutral)
        XCTAssertEqual(Trend(percentChange: -0.005), .down)
        XCTAssertEqual(Trend(percentChange: 0.45), .up)
        XCTAssertEqual(Trend(percentChange: nil), .neutral)
    }
}
