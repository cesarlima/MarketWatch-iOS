import XCTest
@testable import MarketWatch

final class AssetDetailHeaderTests: XCTestCase {

    func test_header_showsListData() {
        let header = makeHeader(for: .fixture())

        XCTAssertEqual(header.name, "Bitcoin")
        XCTAssertEqual(header.subtitle, "BTC · #1")
        XCTAssertEqual(header.priceText, "US$\u{00A0}81.363,00")
        XCTAssertEqual(header.changeText, "-US$\u{00A0}347,48 (-0,45%)")
        XCTAssertEqual(header.trend, .down)
    }

    func test_header_withoutRank_showsOnlySymbol() {
        let header = makeHeader(for: .fixture(marketCapRank: nil))

        XCTAssertEqual(header.subtitle, "BTC")
    }

    func test_header_withoutChange_showsDash() {
        let header = makeHeader(for: .fixture(change24h: nil, changePercentage24h: nil))

        XCTAssertEqual(header.changeText, "—")
        XCTAssertEqual(header.trend, .neutral)
    }

    // MARK: - Helpers

    private func makeHeader(for asset: Asset) -> AssetDetailHeader {
        AssetDetailHeader(asset: asset,
                          formatter: AssetFormatter(locale: Locale(identifier: "pt_BR")))
    }
}
