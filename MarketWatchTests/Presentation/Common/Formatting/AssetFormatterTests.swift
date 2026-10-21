import XCTest
@testable import MarketWatch

final class AssetFormatterTests: XCTestCase {

    func test_price_twoDecimalsAboveOne() {
        let sut = makeSUT()

        XCTAssertEqual(sut.price(81_363), formatted("US$ 81.363,00"))
        XCTAssertEqual(sut.price(1), formatted("US$ 1,00"))
    }

    func test_price_belowOneKeepsFourSignificantDigits() {
        let sut = makeSUT()

        XCTAssertEqual(sut.price(0.00000165), formatted("US$ 0,00000165"))
        XCTAssertEqual(sut.price(0.999255), formatted("US$ 0,9993"))
        XCTAssertEqual(sut.price(0.331043), formatted("US$ 0,331"))
        XCTAssertEqual(sut.price(0.5), formatted("US$ 0,50"))
    }

    func test_price_justBelowOne_roundsToOne() {
        XCTAssertEqual(makeSUT().price(0.99996), formatted("US$ 1,00"))
    }

    func test_signedPercent() {
        let sut = makeSUT()

        XCTAssertEqual(sut.signedPercent(1.82), "+1,82%")
        XCTAssertEqual(sut.signedPercent(-0.45337), "-0,45%")
        XCTAssertEqual(sut.signedPercent(0), "0,00%")
        XCTAssertEqual(sut.signedPercent(-0.003), "0,00%")
        XCTAssertEqual(sut.signedPercent(nil), "—")
    }

    func test_signedPrice() {
        let sut = makeSUT()

        XCTAssertEqual(sut.signedPrice(-347.47512), formatted("-US$ 347,48"))
        XCTAssertEqual(sut.signedPrice(120.5), formatted("+US$ 120,50"))
        XCTAssertEqual(sut.signedPrice(-0.000517220109911287), formatted("-US$ 0,0005172"))
        XCTAssertEqual(sut.signedPrice(nil), "—")
    }

    func test_compactCurrency() {
        let sut = makeSUT()

        XCTAssertEqual(sut.compactCurrency(1_635_294_681_111), formatted("US$ 1,64 tri"))
        XCTAssertEqual(sut.compactCurrency(14_329_628_188), formatted("US$ 14,33 bi"))
        XCTAssertEqual(sut.compactCurrency(52_700_000), formatted("US$ 52,70 mi"))
    }

    func test_compactCurrency_belowOneMillion_showsWholeValue() {
        XCTAssertEqual(makeSUT().compactCurrency(532_104), formatted("US$ 532.104"))
    }

    func test_compactCurrency_roundsUpToNextUnit() {
        XCTAssertEqual(makeSUT().compactCurrency(999_996_000), formatted("US$ 1,00 bi"))
    }

    func test_compactCurrency_nil() {
        XCTAssertEqual(makeSUT().compactCurrency(nil), "—")
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
