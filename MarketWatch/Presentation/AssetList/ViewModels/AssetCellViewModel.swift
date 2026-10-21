struct AssetCellViewModel: Equatable {
    let id: String
    let name: String
    let symbol: String
    let priceText: String
    let changeText: String
    let trend: Trend
}

// MARK: - Mapping

extension AssetCellViewModel {
    init(asset: Asset, formatter: AssetFormatter) {
        self.init(
            id: asset.id,
            name: asset.name,
            symbol: asset.symbol,
            priceText: formatter.price(asset.currentPrice),
            changeText: formatter.signedPercent(asset.priceChangePercentage24h),
            trend: Trend(change: asset.priceChangePercentage24h)
        )
    }
}
