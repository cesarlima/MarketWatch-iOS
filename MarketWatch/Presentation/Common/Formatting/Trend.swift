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
}
