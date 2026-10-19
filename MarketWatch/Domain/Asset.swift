import Foundation

struct Asset: Equatable {
    let id: String
    let symbol: String
    let name: String
    let imageURL: URL?
    let marketCapRank: Int?
    let currentPrice: Double
    let priceChange24h: Double?
    let priceChangePercentage24h: Double?
    let high24h: Double?
    let low24h: Double?
    let marketCap: Double?
    let totalVolume: Double?
    let sparkline7d: [Double]

    /// Crypto trades 24/7, so there is no official close; the price 24h ago stands in for it.
    var price24hAgo: Double? {
        priceChange24h.map { currentPrice - $0 }
    }
}
