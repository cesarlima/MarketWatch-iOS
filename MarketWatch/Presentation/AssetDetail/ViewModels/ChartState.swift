enum ChartState: Equatable {
    case loading
    case loaded(sparkline: [Double], trend: Trend)
    case unavailable(message: String)
}

// MARK: - Loading result

extension ChartState {
    init(_ result: Result<Asset, AppError>) {
        switch result {
        case let .success(asset):
            self = .loaded(sparkline: asset.sparkline7d, trend: Trend(dailyChangeOf: asset))

        case .failure:
            self = .unavailable(message: L10n.Detail.chartUnavailable)
        }
    }
}
