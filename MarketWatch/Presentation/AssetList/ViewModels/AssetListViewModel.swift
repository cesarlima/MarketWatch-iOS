import RxCocoa
import RxSwift

final class AssetListViewModel {
    static let nextPageThreshold = 5

    private let loader: AssetListLoader
    private let formatter: AssetFormatter
    private let disposeBag = DisposeBag()

    init(loader: AssetListLoader,
         formatter: AssetFormatter) {
        self.loader = loader
        self.formatter = formatter
    }

    func transform(_ input: Input) -> Output {
        bindLoadingActions(input)

        return Output(cells: makeCells(),
                      contentState: makeContentState(),
                      selectedAsset: selectedAsset(at: input.selection),
                      isRefreshing: refreshingState(),
                      transientError: transientErrors(),
                      isLoadingNextPage: loadingNextPageState())
    }
}

// MARK: - Actions

private extension AssetListViewModel {
    func bindLoadingActions(_ input: Input) {
        input.retry
            .startWith(())
            .subscribe(onNext: { [loader] in loader.load() })
            .disposed(by: disposeBag)

        input.refresh
            .subscribe(onNext: { [loader] in loader.refresh() })
            .disposed(by: disposeBag)

        input.displayedRow
            .withLatestFrom(loader.state) { row, state in
                row >= state.assets.count - Self.nextPageThreshold
            }
            .filter { $0 }
            .subscribe(onNext: { [loader] _ in loader.loadNextPage() })
            .disposed(by: disposeBag)
    }
}

// MARK: - Output

private extension AssetListViewModel {
    func makeCells() -> Driver<[AssetCellViewModel]> {
        loader.state
            .filter(\.lastLoadSucceeded)
            .map(\.assets)
            .distinctUntilChanged()
            .map { [formatter] assets in
                assets.map { AssetCellViewModel(asset: $0, formatter: formatter) }
            }
            .asDriver(onErrorDriveWith: .empty())
    }

    func makeContentState() -> Driver<ContentState> {
        loader.state
            .compactMap(ContentState.init)
            .distinctUntilChanged()
            .asDriver(onErrorDriveWith: .empty())
    }

    func selectedAsset(at selection: Observable<Int>) -> Signal<Asset> {
        selection
            .withLatestFrom(loader.state) { row, state in
                state.assets.indices.contains(row) ? state.assets[row] : nil
            }
            .compactMap { $0 }
            .asSignal(onErrorSignalWith: .empty())
    }

    func refreshingState() -> Driver<Bool> {
        loader.state
            .map(\.isRefreshing)
            .distinctUntilChanged()
            .asDriver(onErrorDriveWith: .empty())
    }

    func loadingNextPageState() -> Driver<Bool> {
        loader.state
            .map(\.isLoadingNextPage)
            .distinctUntilChanged()
            .asDriver(onErrorDriveWith: .empty())
    }

    func transientErrors() -> Signal<String> {
        loader.failures
            .withLatestFrom(loader.state) { error, state in
                state.assets.isEmpty ? nil : error.message
            }
            .compactMap { $0 }
            .asSignal(onErrorSignalWith: .empty())
    }
}
