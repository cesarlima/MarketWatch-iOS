enum ContentState: Equatable {
    case loading
    case loaded
    case error(message: String)
}
