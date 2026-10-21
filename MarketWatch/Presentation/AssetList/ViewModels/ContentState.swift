enum ContentState: Equatable {
    case loading
    case loaded
    case error(message: String)
}

// MARK: - Loading result

extension ContentState {
    init(_ result: Result<[Asset], AppError>) {
        switch result {
        case .success:
            self = .loaded

        case let .failure(error):
            self = .error(message: error.message)
        }
    }
}
