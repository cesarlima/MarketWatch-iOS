enum AppError: Error, Equatable {
    case offline
    case rateLimited
    case server(statusCode: Int)
    case decoding
    case unknown
}
