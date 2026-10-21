import XCTest
@testable import MarketWatch

final class AssetDetailStatTests: XCTestCase {

    func test_stats_followMockupOrder() {
        let stats = makeStats(for: .fixture())

        XCTAssertEqual(stats, [
            AssetDetailStat(title: "Preço há 24h", value: formatted("US$ 81.710,48")),
            AssetDetailStat(title: "Máx. 24h", value: formatted("US$ 81.728,00")),
            AssetDetailStat(title: "Mín. 24h", value: formatted("US$ 80.823,00")),
            AssetDetailStat(title: "Market cap", value: formatted("US$ 1,64 tri")),
            AssetDetailStat(title: "Volume 24h", value: formatted("US$ 14,33 bi"))
        ])
    }

    func test_stats_missingFieldsShowDash() {
        let asset = Asset.fixture(change24h: nil,
                                  high24h: nil,
                                  low24h: nil,
                                  marketCap: nil,
                                  totalVolume: nil)

        let values = makeStats(for: asset).map(\.value)

        XCTAssertEqual(values, ["—", "—", "—", "—", "—"])
    }

    // MARK: - Helpers

    private func makeStats(for asset: Asset) -> [AssetDetailStat] {
        AssetDetailStat.stats(for: asset,
                              formatter: AssetFormatter(locale: Locale(identifier: "pt_BR")))
    }

    private func formatted(_ text: String) -> String {
        text.replacingOccurrences(of: " ", with: "\u{00A0}")
    }
}
