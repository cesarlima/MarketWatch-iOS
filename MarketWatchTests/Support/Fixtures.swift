import Foundation
@testable import MarketWatch

extension Asset {
    static func fixture(
        id: String = "bitcoin",
        symbol: String = "BTC",
        name: String = "Bitcoin",
        imageURL: URL? = URL(string: "https://example.com/bitcoin.png"),
        marketCapRank: Int? = 1,
        price: Double = 81_363,
        change24h: Double? = -347.47512,
        changePercentage24h: Double? = -0.45337,
        high24h: Double? = 81_728,
        low24h: Double? = 80_823,
        marketCap: Double? = 1_635_294_681_111,
        totalVolume: Double? = 14_329_628_188,
        sparkline7d: [Double] = [80_000, 81_000, 81_363]
    ) -> Asset {
        Asset(
            id: id,
            symbol: symbol,
            name: name,
            imageURL: imageURL,
            marketCapRank: marketCapRank,
            currentPrice: price,
            priceChange24h: change24h,
            priceChangePercentage24h: changePercentage24h,
            high24h: high24h,
            low24h: low24h,
            marketCap: marketCap,
            totalVolume: totalVolume,
            sparkline7d: sparkline7d
        )
    }
}

extension AssetPage {
    static func fixture(_ assets: [Asset] = [.fixture()],
                        hasMore: Bool = false) -> AssetPage {
        AssetPage(assets: assets, hasMore: hasMore)
    }
}

enum FixtureLoader {
    static func data(named name: String) throws -> Data {
        let bundle = Bundle(for: BundleToken.self)
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw FixtureError.notFound(name)
        }
        return try Data(contentsOf: url)
    }

    enum FixtureError: Error {
        case notFound(String)
    }

    private final class BundleToken {}
}

extension MarketCoinDTO {
    static func fixture(id: String, currentPrice: Double? = 1) -> MarketCoinDTO {
        MarketCoinDTO(
            id: id,
            symbol: id,
            name: id,
            image: nil,
            marketCapRank: nil,
            currentPrice: currentPrice,
            priceChange24h: nil,
            priceChangePercentage24h: nil,
            high24h: nil,
            low24h: nil,
            marketCap: nil,
            totalVolume: nil,
            sparklineIn7d: nil
        )
    }
}
