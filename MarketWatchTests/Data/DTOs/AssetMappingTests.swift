import XCTest
@testable import MarketWatch

final class AssetMappingTests: XCTestCase {

    func test_mapping_decodesRealPayloadAndDropsCoinWithoutPrice() throws {
        let assets = try makeAssetsFromSample()

        XCTAssertEqual(assets.count, 2)
        XCTAssertEqual(assets[0].id, "bitcoin")
        XCTAssertEqual(assets[0].symbol, "BTC")
        XCTAssertEqual(assets[0].name, "Bitcoin")
        XCTAssertEqual(assets[0].marketCapRank, 1)
        XCTAssertEqual(assets[0].sparkline7d.count, 5)
    }

    func test_mapping_decodesEveryMarketField() throws {
        let bitcoin = try XCTUnwrap(makeAssetsFromSample().first)

        XCTAssertEqual(bitcoin.currentPrice, 80_830)
        XCTAssertEqual(bitcoin.priceChange24h, -718.1117715021101)
        XCTAssertEqual(bitcoin.priceChangePercentage24h, -0.87348)
        XCTAssertEqual(bitcoin.high24h, 82_178)
        XCTAssertEqual(bitcoin.low24h, 80_753)
        XCTAssertEqual(bitcoin.marketCap, 1_624_782_336_012)
        XCTAssertEqual(bitcoin.totalVolume, 18_473_687_907)
        XCTAssertEqual(bitcoin.imageURL?.host, "coin-images.coingecko.com")
    }

    func test_mapping_keepsNilOptionalFields() throws {
        let assets = try makeAssetsFromSample()

        XCTAssertEqual(assets[1].id, "ethereum")
        XCTAssertNil(assets[1].marketCapRank)
        XCTAssertNil(assets[1].marketCap)
        XCTAssertEqual(assets[1].sparkline7d, [])
    }

    func test_price24hAgo_isCurrentMinusChange() {
        let asset = Asset.fixture(price: 100, change24h: -5)

        XCTAssertEqual(asset.price24hAgo, 105)
    }

    func test_price24hAgo_isNilWithoutChange() {
        let asset = Asset.fixture(change24h: nil)

        XCTAssertNil(asset.price24hAgo)
    }

    // MARK: - Helpers

    private func makeAssetsFromSample() throws -> [Asset] {
        let data = try FixtureLoader.data(named: "markets-sample")
        let dtos = try JSONDecoder().decode([MarketCoinDTO].self, from: data)
        return dtos.compactMap { $0.toAsset() }
    }
}
