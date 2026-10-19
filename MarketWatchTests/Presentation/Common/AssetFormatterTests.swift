import XCTest
@testable import MarketWatch

final class AssetFormatterTests: XCTestCase {

    func test_price_twoDecimalsAboveOne() {
        let sut = makeSUT()

        XCTAssertEqual(sut.price(81_363), formatted("US$ 81.363,00"))
        XCTAssertEqual(sut.price(1), formatted("US$ 1,00"))
    }

    func test_price_tinyValuesKeepSignificantDigits() {
        XCTAssertEqual(makeSUT().price(0.00000165), formatted("US$ 0,00000165"))
    }

    func test_signedPercent() {
        let sut = makeSUT()

        XCTAssertEqual(sut.signedPercent(1.82), "+1,82%")
        XCTAssertEqual(sut.signedPercent(-0.45337), "-0,45%")
        XCTAssertEqual(sut.signedPercent(0), "0,00%")
        XCTAssertEqual(sut.signedPercent(nil), "—")
    }

    // MARK: - Helpers

    private func makeSUT() -> AssetFormatter {
        AssetFormatter(locale: Locale(identifier: "pt_BR"))
    }

    /// The formatter keeps "US$" glued to the number with a non-breaking space.
    private func formatted(_ text: String) -> String {
        text.replacingOccurrences(of: " ", with: "\u{00A0}")
    }
}
