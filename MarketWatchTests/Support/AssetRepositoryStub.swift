import RxSwift
@testable import MarketWatch

final class AssetRepositoryStub: AssetRepository {
    struct PageRequest: Equatable {
        let page: Int
        let pageSize: Int
    }

    private(set) var requestedPages: [PageRequest] = []
    private(set) var requestedAssetIDs: [String] = []
    private(set) var requestedQueries: [String] = []
    var assetsResponse: Single<AssetPage> = .never()
    /// Answers for specific pages; other pages get `assetsResponse`.
    var assetsResponsesByPage: [Int: Single<AssetPage>] = [:]
    var assetResponse: Single<Asset> = .never()
    var searchResponsesByQuery: [String: Single<[Asset]>] = [:]

    func assets(page: Int, pageSize: Int) -> Single<AssetPage> {
        Single.deferred { [weak self] in
            self?.requestedPages.append(PageRequest(page: page, pageSize: pageSize))

            return self?.assetsResponsesByPage[page] ?? self?.assetsResponse ?? .never()
        }
    }

    func asset(id: String) -> Single<Asset> {
        Single.deferred { [weak self] in
            self?.requestedAssetIDs.append(id)

            return self?.assetResponse ?? .never()
        }
    }

    func searchAssets(query: String) -> Single<[Asset]> {
        Single.deferred { [weak self] in
            self?.requestedQueries.append(query)

            return self?.searchResponsesByQuery[query] ?? .never()
        }
    }
}
