extension AppError {
    var message: String {
        switch self {
        case .offline:
            return L10n.ErrorMessage.offline

        case .rateLimited:
            return L10n.ErrorMessage.rateLimited

        case .server:
            return L10n.ErrorMessage.server

        case .decoding:
            return L10n.ErrorMessage.decoding

        case .unknown:
            return L10n.ErrorMessage.unknown
        }
    }
}
