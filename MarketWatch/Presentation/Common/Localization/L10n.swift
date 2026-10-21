import Foundation

enum L10n {
    enum List {
        static let title = text("list.title")
    }

    enum Detail {
        static func symbolAndRank(_ symbol: String, _ rank: Int) -> String {
            text("detail.symbolAndRank", symbol, String(rank))
        }
    }

    enum ErrorMessage {
        static let offline = text("error.offline")
        static let rateLimited = text("error.rateLimited")
        static let server = text("error.server")
        static let decoding = text("error.decoding")
        static let unknown = text("error.unknown")
    }

    enum Value {
        static let unavailable = text("value.unavailable")
    }
}

// MARK: - Lookup

private extension L10n {
    static func text(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: NSLocalizedString(key, comment: ""), arguments: arguments)
    }
}
