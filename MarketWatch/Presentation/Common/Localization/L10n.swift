import Foundation

enum L10n {
    enum List {
        static let title = text("list.title")
    }

    enum Search {
        static let placeholder = text("search.placeholder")

        static func noResults(_ query: String) -> String {
            text("state.empty.search", query)
        }
    }

    enum State {
        static let retry = text("state.retry")
    }

    enum Detail {
        static let chart7d = text("detail.chart7d")
        static let chartUnavailable = text("detail.chartUnavailable")
        static let price24hAgo = text("detail.price24hAgo")
        static let high24h = text("detail.high24h")
        static let low24h = text("detail.low24h")
        static let marketCap = text("detail.marketCap")
        static let volume24h = text("detail.volume24h")

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

    enum Compact {
        static let trillion = text("compact.trillion")
        static let billion = text("compact.billion")
        static let million = text("compact.million")
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
