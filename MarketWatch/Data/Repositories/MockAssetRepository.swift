import Foundation
import RxSwift

/// Serves a real `/coins/markets` response bundled with the app, for offline demos.
final class MockAssetRepository: AssetRepository {
    private static let searchResultLimit = 25

    private let allAssets: Single<[Asset]>

    init(bundle: Bundle) {
        allAssets = Self.loadAssets(from: bundle)
    }

    func assets(page: Int, pageSize: Int) -> Single<AssetPage> {
        allAssets.map { assets in
            let alreadyLoaded = (page - 1) * pageSize
            let loadedAfterThisPage = alreadyLoaded + pageSize

            return AssetPage(assets: Array(assets.dropFirst(alreadyLoaded).prefix(pageSize)),
                             hasMore: loadedAfterThisPage < assets.count)
        }
    }

    func asset(id: String) -> Single<Asset> {
        allAssets.map { assets in
            guard let asset = assets.first(where: { $0.id == id }) else {
                throw AppError.unknown
            }
            return asset
        }
    }

    func searchAssets(query: String) -> Single<[Asset]> {
        allAssets.map { assets in
            let matches = assets.filter { $0.matches(query) }

            return Array(matches.prefix(Self.searchResultLimit))
        }
    }
}

// MARK: - Loading

private extension MockAssetRepository {
    static func loadAssets(from bundle: Bundle) -> Single<[Asset]> {
        guard
            let url = bundle.url(forResource: "mock-markets", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let coins = try? JSONDecoder().decode([MarketCoinDTO].self, from: data)
        else {
            return .error(AppError.decoding)
        }
        return .just(coins.toAssets())
    }
}

// MARK: - Search matching

private extension Asset {
    /// Ignores case and accents, like the search field the user types into.
    func matches(_ query: String) -> Bool {
        name.localizedStandardContains(query) || symbol.localizedStandardContains(query)
    }
}
