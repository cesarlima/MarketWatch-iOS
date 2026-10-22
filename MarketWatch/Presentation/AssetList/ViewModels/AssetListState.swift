struct AssetListState: Equatable {
    enum Loading {
        case none
        case initial
        case refresh
    }

    var assets: [Asset] = []
    var loading: Loading = .none
    var error: AppError?
}

// MARK: - Conditions

extension AssetListState {
    var lastLoadSucceeded: Bool {
        loading == .none && error == nil
    }

    var isRefreshing: Bool {
        loading == .refresh
    }
}
