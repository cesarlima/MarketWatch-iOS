import RxSwift
@testable import MarketWatch

final class AssetRepositoryStub: AssetRepository {
    struct PageRequest: Equatable {
        let page: Int
        let pageSize: Int
    }

    private(set) var requestedPages: [PageRequest] = []
    private(set) var requestedAssetIDs: [String] = []
    var assetsResponse: Single<AssetPage> = .never()
    var assetResponse: Single<Asset> = .never()

    func assets(page: Int, pageSize: Int) -> Single<AssetPage> {
        Single.deferred { [weak self] in
            self?.requestedPages.append(PageRequest(page: page, pageSize: pageSize))

            return self?.assetsResponse ?? .never()
        }
    }

    func asset(id: String) -> Single<Asset> {
        Single.deferred { [weak self] in
            self?.requestedAssetIDs.append(id)

            return self?.assetResponse ?? .never()
        }
    }

    func searchAssets(query: String) -> Single<[Asset]> {
        .never()
    }
}
