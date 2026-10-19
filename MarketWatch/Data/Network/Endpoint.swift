enum Endpoint: Equatable {
    /// One page of the market list, without sparkline to keep the payload small.
    case marketPage(page: Int, perPage: Int)
    /// Prices for search results, without sparkline.
    case markets(ids: [String])
    /// A single asset with its 7-day sparkline, loaded when the detail screen opens.
    case assetDetail(id: String)
    case search(query: String)

    var path: String {
        switch self {
        case .marketPage, .markets, .assetDetail:
            return "/coins/markets"

        case .search:
            return "/search"
        }
    }

    var parameters: [String: String] {
        switch self {
        case let .marketPage(page, perPage):
            return marketParameters(adding: [
                "page": String(page),
                "per_page": String(perPage)
            ])

        case let .markets(ids):
            return marketParameters(adding: [
                "ids": ids.joined(separator: ",")
            ])

        case let .assetDetail(id):
            return marketParameters(adding: [
                "ids": id,
                "sparkline": "true"
            ])

        case let .search(query):
            return ["query": query]
        }
    }

    private func marketParameters(adding extra: [String: String]) -> [String: String] {
        let common = [
            "vs_currency": "usd",
            "order": "market_cap_desc",
            "sparkline": "false"
        ]
        return common.merging(extra) { _, new in new }
    }
}
