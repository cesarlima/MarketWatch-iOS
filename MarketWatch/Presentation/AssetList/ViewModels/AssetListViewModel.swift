import RxCocoa
import RxSwift

final class AssetListViewModel {
    struct Input {
        let selection: Observable<Int>
        let retry: Observable<Void>
    }

    struct Output {
        let cells: Driver<[AssetCellViewModel]>
        let contentState: Driver<ContentState>
        let selectedAsset: Signal<Asset>
    }

    static let pageSize = 25

    private let repository: AssetRepository
    private let formatter: AssetFormatter

    init(repository: AssetRepository,
         formatter: AssetFormatter) {
        self.repository = repository
        self.formatter = formatter
    }

    func transform(_ input: Input) -> Output {
        let firstPage = loadFirstPage(on: input.retry.startWith(()))
        let assets = loadedAssets(from: firstPage)

        return Output(cells: cells(from: assets),
                      contentState: contentState(from: firstPage),
                      selectedAsset: selectedAsset(at: input.selection, in: assets))
    }
}

// MARK: - Streams

private extension AssetListViewModel {
    enum PageLoad {
        case loading
        case finished(Result<[Asset], AppError>)
    }

    /// Each request emits `.loading` and then its result, always in that order.
    func loadFirstPage(on requests: Observable<Void>) -> Observable<PageLoad> {
        requests
            .flatMapLatest { [repository] in
                repository
                    .assets(page: 1, pageSize: Self.pageSize)
                    .asResult()
                    .asObservable()
                    .map(PageLoad.finished)
                    .startWith(.loading)
            }
            .share(replay: 1)
    }

    /// The assets of each successful load.
    func loadedAssets(from page: Observable<PageLoad>) -> Observable<[Asset]> {
        page
            .compactMap { load -> [Asset]? in
                guard case let .finished(.success(assets)) = load else {
                    return nil
                }
                return assets
            }
            .share(replay: 1)
    }

    func cells(from assets: Observable<[Asset]>) -> Driver<[AssetCellViewModel]> {
        assets
            .map { [formatter] assets in
                assets.map { AssetCellViewModel(asset: $0, formatter: formatter) }
            }
            .asDriver(onErrorDriveWith: .empty())
    }

    func contentState(from page: Observable<PageLoad>) -> Driver<ContentState> {
        page
            .map { load -> ContentState in
                switch load {
                case .loading:
                    return .loading

                case let .finished(result):
                    return ContentState(result)
                }
            }
            .asDriver(onErrorDriveWith: .empty())
    }

    func selectedAsset(at selection: Observable<Int>,
                       in assets: Observable<[Asset]>) -> Signal<Asset> {
        selection
            .withLatestFrom(assets) { row, assets -> Asset? in
                assets.indices.contains(row) ? assets[row] : nil
            }
            .compactMap { $0 }
            .asSignal(onErrorSignalWith: .empty())
    }
}
