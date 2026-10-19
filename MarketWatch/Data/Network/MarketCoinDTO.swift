import Foundation

/// Mirrors an item of `GET /coins/markets`.
/// Every numeric field is optional: the API sends `null` for coins with incomplete data.
struct MarketCoinDTO: Decodable {
    let id: String
    let symbol: String
    let name: String
    let image: String?
    let marketCapRank: Int?
    let currentPrice: Double?
    let priceChange24h: Double?
    let priceChangePercentage24h: Double?
    let high24h: Double?
    let low24h: Double?
    let marketCap: Double?
    let totalVolume: Double?
    let sparklineIn7d: Sparkline?

    struct Sparkline: Decodable {
        let price: [Double]?
    }

    enum CodingKeys: String, CodingKey {
        case id, symbol, name, image
        case marketCapRank = "market_cap_rank"
        case currentPrice = "current_price"
        case priceChange24h = "price_change_24h"
        case priceChangePercentage24h = "price_change_percentage_24h"
        case high24h = "high_24h"
        case low24h = "low_24h"
        case marketCap = "market_cap"
        case totalVolume = "total_volume"
        case sparklineIn7d = "sparkline_in_7d"
    }
}

// MARK: - Domain mapping

extension MarketCoinDTO {
    /// Returns `nil` when the coin has no current price: a row without a price is useless in a market list.
    func toAsset() -> Asset? {
        guard let currentPrice else { return nil }

        return Asset(
            id: id,
            symbol: symbol.uppercased(),
            name: name,
            imageURL: image.flatMap(URL.init(string:)),
            marketCapRank: marketCapRank,
            currentPrice: currentPrice,
            priceChange24h: priceChange24h,
            priceChangePercentage24h: priceChangePercentage24h,
            high24h: high24h,
            low24h: low24h,
            marketCap: marketCap,
            totalVolume: totalVolume,
            sparkline7d: sparklineIn7d?.price ?? []
        )
    }
}
