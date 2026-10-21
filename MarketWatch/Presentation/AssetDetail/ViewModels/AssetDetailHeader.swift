import Foundation

struct AssetDetailHeader: Equatable {
    let name: String
    let subtitle: String
    let imageURL: URL?
    let priceText: String
    let changeText: String
    let trend: Trend
}

// MARK: - Mapping

extension AssetDetailHeader {
    init(asset: Asset, formatter: AssetFormatter) {
        self.init(
            name: asset.name,
            subtitle: Self.subtitle(symbol: asset.symbol, rank: asset.marketCapRank),
            imageURL: asset.imageURL,
            priceText: formatter.price(asset.currentPrice),
            changeText: Self.changeText(for: asset, formatter: formatter),
            trend: Trend(dailyChangeOf: asset)
        )
    }
}

private extension AssetDetailHeader {
    static func subtitle(symbol: String, rank: Int?) -> String {
        guard let rank else {
            return symbol
        }
        return L10n.Detail.symbolAndRank(symbol, rank)
    }

    static func changeText(for asset: Asset, formatter: AssetFormatter) -> String {
        let percent = formatter.signedPercent(asset.priceChangePercentage24h)

        guard asset.priceChange24h != nil else {
            return percent
        }
        return "\(formatter.signedPrice(asset.priceChange24h)) (\(percent))"
    }
}
