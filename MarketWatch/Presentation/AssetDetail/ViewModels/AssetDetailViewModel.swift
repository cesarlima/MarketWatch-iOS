import RxCocoa
import RxSwift

final class AssetDetailViewModel {
    struct Input {
        let retry: Observable<Void>
    }

    struct Output {
        let header: Driver<AssetDetailHeader>
        let stats: Driver<[AssetDetailStat]>
        let chartState: Driver<ChartState>
    }

    private let asset: Asset
    private let repository: AssetRepository
    private let formatter: AssetFormatter

    init(asset: Asset,
         repository: AssetRepository,
         formatter: AssetFormatter) {
        self.asset = asset
        self.repository = repository
        self.formatter = formatter
    }

    func transform(_ input: Input) -> Output {
        let freshAsset = loadFreshAsset(on: input.retry.startWith(()))
        let latestAsset = latestAsset(from: freshAsset)

        return Output(header: header(from: latestAsset),
                      stats: stats(from: latestAsset),
                      chartState: chartState(from: freshAsset))
    }
}

// MARK: - Streams

private extension AssetDetailViewModel {
    enum FreshAsset {
        case loading
        case finished(Result<Asset, AppError>)
    }

    func loadFreshAsset(on requests: Observable<Void>) -> Observable<FreshAsset> {
        requests
            .flatMapLatest { [repository, asset] in
                repository
                    .asset(id: asset.id)
                    .asResult()
                    .asObservable()
                    .map(FreshAsset.finished)
                    .startWith(.loading)
            }
            .share(replay: 1)
    }

    func latestAsset(from freshAsset: Observable<FreshAsset>) -> Observable<Asset> {
        freshAsset
            .compactMap { state -> Asset? in
                guard case let .finished(.success(asset)) = state else {
                    return nil
                }
                return asset
            }
            .startWith(asset)
    }

    func header(from asset: Observable<Asset>) -> Driver<AssetDetailHeader> {
        asset
            .map { [formatter] asset in
                AssetDetailHeader(asset: asset, formatter: formatter)
            }
            .asDriver(onErrorDriveWith: .empty())
    }

    func stats(from asset: Observable<Asset>) -> Driver<[AssetDetailStat]> {
        asset
            .map { [formatter] asset in
                AssetDetailStat.stats(for: asset, formatter: formatter)
            }
            .asDriver(onErrorDriveWith: .empty())
    }

    func chartState(from freshAsset: Observable<FreshAsset>) -> Driver<ChartState> {
        freshAsset
            .map { state -> ChartState in
                switch state {
                case .loading:
                    return .loading

                case let .finished(result):
                    return ChartState(result)
                }
            }
            .asDriver(onErrorDriveWith: .empty())
    }
}
