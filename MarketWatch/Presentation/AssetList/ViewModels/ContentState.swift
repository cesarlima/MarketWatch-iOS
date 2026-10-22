enum ContentState: Equatable {
    case loading
    case loaded
    case error(message: String)
}

// MARK: - List state

extension ContentState {
    /// `nil` while refreshing or loading more: the screen keeps what it shows until the load ends.
    init?(_ state: AssetListState) {
        switch (state.loading, state.error) {
        case (.refresh, _), (.nextPage, _):
            return nil

        case (.initial, _):
            self = .loading

        case let (.none, error?) where state.assets.isEmpty:
            self = .error(message: error.message)

        case (.none, _):
            self = .loaded
        }
    }
}
