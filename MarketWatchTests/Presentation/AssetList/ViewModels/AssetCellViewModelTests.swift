import XCTest
@testable import MarketWatch

final class AssetCellViewModelTests: XCTestCase {

    func test_tinyChange_isNeutral() {
        let cell = AssetCellViewModel(asset: .fixture(changePercentage24h: -0.003),
                                      formatter: AssetFormatter(locale: Locale(identifier: "pt_BR")))

        XCTAssertEqual(cell.changeText, "0,00%")
        XCTAssertEqual(cell.trend, .neutral)
    }
}
