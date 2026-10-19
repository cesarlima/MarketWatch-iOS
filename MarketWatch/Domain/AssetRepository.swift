import RxSwift

protocol AssetRepository {
    func topAssets() -> Single<[Asset]>
    func searchAssets(query: String) -> Single<[Asset]>
}
