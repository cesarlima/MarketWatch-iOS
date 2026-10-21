struct AssetDetailStat: Equatable {
    let title: String
    let value: String
}

// MARK: - Mapping

extension AssetDetailStat {
    /// The rows under the chart
    static func stats(for asset: Asset, formatter: AssetFormatter) -> [AssetDetailStat] {
        [
            AssetDetailStat(title: L10n.Detail.price24hAgo, value: price(asset.price24hAgo, formatter)),
            AssetDetailStat(title: L10n.Detail.high24h, value: price(asset.high24h, formatter)),
            AssetDetailStat(title: L10n.Detail.low24h, value: price(asset.low24h, formatter)),
            AssetDetailStat(title: L10n.Detail.marketCap, value: formatter.compactCurrency(asset.marketCap)),
            AssetDetailStat(title: L10n.Detail.volume24h, value: formatter.compactCurrency(asset.totalVolume))
        ]
    }
}

private extension AssetDetailStat {
    static func price(_ value: Double?, _ formatter: AssetFormatter) -> String {
        value.map(formatter.price) ?? L10n.Value.unavailable
    }
}
