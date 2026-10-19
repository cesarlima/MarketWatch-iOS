import RxSwift

final class CoinGeckoAssetRepository: AssetRepository {
    private static let searchResultLimit = 25

    private let httpClient: APIClient

    init(httpClient: APIClient) {
        self.httpClient = httpClient
    }

    func assets(page: Int, pageSize: Int) -> Single<[Asset]> {
        let endpoint = Endpoint.marketPage(page: page, perPage: pageSize)

        return httpClient
            .request(endpoint, as: [MarketCoinDTO].self)
            .map { coins in coins.toAssets() }
    }

    func asset(id: String) -> Single<Asset> {
        httpClient
            .request(.assetDetail(id: id), as: [MarketCoinDTO].self)
            .map { dtos in
                guard let asset = dtos.first(where: { $0.id == id })?.toAsset() else {
                    throw AppError.unknown
                }
                return asset
            }
    }

    /// `/search` ranks by relevance but has no prices; `/coins/markets` has prices but ranks by market cap.
    /// The search order is kept.
    func searchAssets(query: String) -> Single<[Asset]> {
        httpClient
            .request(.search(query: query), as: SearchResponseDTO.self)
            .map { response in
                response.coins.prefix(Self.searchResultLimit).map(\.id)
            }
            .flatMap { [httpClient] ids in
                guard !ids.isEmpty else {
                    return .just([])
                }
                
                return httpClient
                    .request(.markets(ids: ids), as: [MarketCoinDTO].self)
                    .map { coins in
                        Self.searchResults(from: coins, orderedBy: ids)
                    }
            }
    }
}

// MARK: - Search ordering

private extension CoinGeckoAssetRepository {
    static func searchResults(from coins: [MarketCoinDTO],
                              orderedBy ids: [String]) -> [Asset] {
        let assets = coins.toAssets()

        return ids.compactMap { id in
            assets.first { $0.id == id }
        }
    }
}
