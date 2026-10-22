struct AssetListState: Equatable {
    enum Loading {
        case none
        case initial
        case refresh
        case nextPage
    }

    var assets: [Asset] = []
    var loading: Loading = .none
    var error: AppError?
    /// The last page that arrived successfully; 0 before the first one.
    var loadedPage = 0
    var hasMore = false
}

// MARK: - Conditions

extension AssetListState {
    var lastLoadSucceeded: Bool {
        loading == .none && error == nil
    }

    var isRefreshing: Bool {
        loading == .refresh
    }

    var isLoadingNextPage: Bool {
        loading == .nextPage
    }

    /// The first page arrived, nothing is loading and the API said there is more.
    var canLoadNextPage: Bool {
        loadedPage > 0 && loading == .none && hasMore
    }
}
