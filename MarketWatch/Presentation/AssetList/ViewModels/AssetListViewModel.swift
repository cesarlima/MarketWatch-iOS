import RxCocoa
import RxSwift

final class AssetListViewModel {
    struct Input {
        let selection: Observable<Int>
        let retry: Observable<Void>
        let refresh: Observable<Void>
    }

    struct Output {
        let cells: Driver<[AssetCellViewModel]>
        let contentState: Driver<ContentState>
        let selectedAsset: Signal<Asset>
        let isRefreshing: Driver<Bool>
        let transientError: Signal<String>
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
        let refreshActivity = ActivityTracker()
        let firstPage = loadFirstPage(on: triggers(from: input),
                                      refreshActivity: refreshActivity)
        let assets = loadedAssets(from: firstPage)
        let hasList = hasList(from: assets)

        return Output(cells: cells(from: assets),
                      contentState: contentState(from: firstPage, hasList: hasList),
                      selectedAsset: selectedAsset(at: input.selection, in: assets),
                      isRefreshing: refreshActivity.asDriver(),
                      transientError: transientError(from: firstPage, hasList: hasList))
    }
}

// MARK: - Streams

private extension AssetListViewModel {
    enum PageLoad {
        case loading
        case finished(Result<[Asset], AppError>)
    }

    enum LoadTrigger {
        case automatic
        case refresh
    }

    /// Opening the screen and "Tentar novamente" are automatic loads; pulling the list is a refresh.
    func triggers(from input: Input) -> Observable<LoadTrigger> {
        Observable.merge(input.retry.startWith(()).map { LoadTrigger.automatic },
                         input.refresh.map { LoadTrigger.refresh })
    }

    /// Automatic loads emit `.loading` and then the result; a refresh shows its progress
    /// through `refreshActivity` instead, so the list stays on screen.
    func loadFirstPage(on triggers: Observable<LoadTrigger>,
                       refreshActivity: ActivityTracker) -> Observable<PageLoad> {
        triggers
            .flatMapLatest { [repository] trigger -> Observable<PageLoad> in
                let load = repository
                    .assets(page: 1, pageSize: Self.pageSize)
                    .asResult()
                    .asObservable()
                    .map(PageLoad.finished)

                switch trigger {
                case .automatic:
                    return load.startWith(.loading)

                case .refresh:
                    return refreshActivity.trackActivity(load)
                }
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

    /// Whether a non-empty list is on screen, starting with `false`.
    func hasList(from assets: Observable<[Asset]>) -> Observable<Bool> {
        assets
            .map { !$0.isEmpty }
            .startWith(false)
    }

    func cells(from assets: Observable<[Asset]>) -> Driver<[AssetCellViewModel]> {
        assets
            .map { [formatter] assets in
                assets.map { AssetCellViewModel(asset: $0, formatter: formatter) }
            }
            .asDriver(onErrorDriveWith: .empty())
    }

    /// A failure with a list on screen keeps the list; it is shown by `transientError` instead.
    func contentState(from page: Observable<PageLoad>,
                      hasList: Observable<Bool>) -> Driver<ContentState> {
        page
            .withLatestFrom(hasList) { load, hasList -> ContentState in
                switch load {
                case .loading:
                    return .loading

                case .finished(.failure) where hasList:
                    return .loaded

                case let .finished(result):
                    return ContentState(result)
                }
            }
            .distinctUntilChanged()
            .asDriver(onErrorDriveWith: .empty())
    }

    func transientError(from page: Observable<PageLoad>,
                        hasList: Observable<Bool>) -> Signal<String> {
        page
            .withLatestFrom(hasList) { load, hasList -> String? in
                guard case let .finished(.failure(error)) = load, hasList else {
                    return nil
                }
                return error.message
            }
            .compactMap { $0 }
            .asSignal(onErrorSignalWith: .empty())
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
