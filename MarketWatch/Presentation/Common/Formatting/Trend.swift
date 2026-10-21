enum Trend: Equatable {
    case up
    case down
    case neutral

    init(change: Double?) {
        switch change {
        case let change? where change > 0:
            self = .up

        case let change? where change < 0:
            self = .down

        default:
            self = .neutral
        }
    }

    /// Up, down or neutral for a percentage as it appears on screen, with 2 decimals.
    /// A change that shows as "0,00%" is neutral: `-0.003` → `.neutral`, `-0.005` → `.down`.
    init(percentChange: Double?) {
        self.init(change: percentChange.map { ($0 * 100).rounded() / 100 })
    }

    /// Up, down or neutral for an asset's last 24h: the dollar change when there is one,
    /// otherwise the percentage as it appears on screen.
    init(dailyChangeOf asset: Asset) {
        guard let dollarChange = asset.priceChange24h else {
            self.init(percentChange: asset.priceChangePercentage24h)
            return
        }
        self.init(change: dollarChange)
    }
}
