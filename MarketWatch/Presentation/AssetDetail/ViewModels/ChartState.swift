enum ChartState: Equatable {
    case loading
    case loaded
    case unavailable(message: String)
}

// MARK: - Loading result

extension ChartState {
    init(_ result: Result<Asset, AppError>) {
        switch result {
        case .success:
            self = .loaded

        case .failure:
            self = .unavailable(message: L10n.Detail.chartUnavailable)
        }
    }
}
