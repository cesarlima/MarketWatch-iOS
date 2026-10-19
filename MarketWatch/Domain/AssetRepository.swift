import RxSwift

protocol AssetRepository {
    func assets(page: Int, pageSize: Int) -> Single<[Asset]>
    /// Fails with `AppError.unknown` when no asset has the given id.
    func asset(id: String) -> Single<Asset>
    func searchAssets(query: String) -> Single<[Asset]>
}
