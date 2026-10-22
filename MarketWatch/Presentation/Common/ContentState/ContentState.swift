enum ContentState: Equatable {
    case loading
    case loaded
    case empty(message: String)
    case error(message: String)
}
