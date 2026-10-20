import RxSwift
@testable import MarketWatch

final class AssetRepositoryStub: AssetRepository {
    struct PageRequest: Equatable {
        let page: Int
        let pageSize: Int
    }

    private(set) var requestedPages: [PageRequest] = []
    var assetsResponse: Single<[Asset]> = .never()

    func assets(page: Int, pageSize: Int) -> Single<[Asset]> {
        Single.deferred { [weak self] in
            self?.requestedPages.append(PageRequest(page: page, pageSize: pageSize))

            return self?.assetsResponse ?? .never()
        }
    }

    func asset(id: String) -> Single<Asset> {
        .never()
    }

    func searchAssets(query: String) -> Single<[Asset]> {
        .never()
    }
}
