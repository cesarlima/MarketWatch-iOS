import XCTest
@testable import MarketWatch

final class TrendTests: XCTestCase {

    func test_trend() {
        XCTAssertEqual(Trend(change: 0.1), .up)
        XCTAssertEqual(Trend(change: -0.1), .down)
        XCTAssertEqual(Trend(change: 0), .neutral)
        XCTAssertEqual(Trend(change: nil), .neutral)
    }
}
