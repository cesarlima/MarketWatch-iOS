import RxCocoa
import RxSwift

final class AssetSearchViewModel {
    struct Input {
        let query: Observable<String>
        let retry: Observable<Void>
        let selection: Observable<Int>
    }

    struct Output {
        let cells: Driver<[AssetCellViewModel]>
        let contentState: Driver<ContentState>
        let isSearchActive: Driver<Bool>
        let selectedAsset: Signal<Asset>
    }

    static let debounce: RxTimeInterval = .milliseconds(400)
    static let minimumQueryLength = 2

    private let repository: AssetRepository
    private let formatter: AssetFormatter
    private let scheduler: SchedulerType

    init(repository: AssetRepository,
         formatter: AssetFormatter,
         scheduler: SchedulerType) {
        self.repository = repository
        self.formatter = formatter
        self.scheduler = scheduler
    }

    func transform(_ input: Input) -> Output {
        let query = input.query.map(Self.trimmed)
        let search = searchStates(for: query, retry: input.retry)
        let results = search.map(Self.assets)

        return Output(cells: makeCells(from: results),
                      contentState: makeContentState(from: search),
                      isSearchActive: searchActiveState(for: query),
                      selectedAsset: selectedAsset(at: input.selection, in: results))
    }
}

// MARK: - Output

private extension AssetSearchViewModel {
    func makeCells(from results: Observable<[Asset]>) -> Driver<[AssetCellViewModel]> {
        results
            .distinctUntilChanged()
            .map { [formatter] assets in
                assets.map { AssetCellViewModel(asset: $0, formatter: formatter) }
            }
            .asDriver(onErrorDriveWith: .empty())
    }

    func makeContentState(from search: Observable<SearchState>) -> Driver<ContentState> {
        search
            .map(Self.contentState)
            .distinctUntilChanged()
            .asDriver(onErrorDriveWith: .empty())
    }

    func selectedAsset(at selection: Observable<Int>,
                       in results: Observable<[Asset]>) -> Signal<Asset> {
        selection
            .withLatestFrom(results) { row, assets in
                assets.indices.contains(row) ? assets[row] : nil
            }
            .compactMap { $0 }
            .asSignal(onErrorSignalWith: .empty())
    }

    func searchActiveState(for query: Observable<String>) -> Driver<Bool> {
        query
            .map(Self.isSearchable)
            .distinctUntilChanged()
            .asDriver(onErrorDriveWith: .empty())
    }
}

// MARK: - Search

private extension AssetSearchViewModel {
    enum SearchState {
        case idle
        case loading
        case finished(query: String, Result<[Asset], AppError>)
    }

    func searchStates(for query: Observable<String>,
                      retry: Observable<Void>) -> Observable<SearchState> {
        let typedText = query
            .debounce(Self.debounce, scheduler: scheduler)
            .distinctUntilChanged()
            .share(replay: 1)

        return Observable
            .merge(typedText, retry.withLatestFrom(typedText))
            .flatMapLatest { [repository] text -> Observable<SearchState> in
                guard Self.isSearchable(text) else {
                    return .just(.idle)
                }
                return repository
                    .searchAssets(query: text)
                    .asResult()
                    .asObservable()
                    .map { .finished(query: text, $0) }
                    .startWith(.loading)
            }
            .share(replay: 1)
    }

    static func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func isSearchable(_ text: String) -> Bool {
        text.count >= minimumQueryLength
    }
}

// MARK: - Presentation

private extension AssetSearchViewModel {
    static func assets(in search: SearchState) -> [Asset] {
        guard case let .finished(_, .success(assets)) = search else {
            return []
        }
        return assets
    }

    static func contentState(for search: SearchState) -> ContentState {
        switch search {
        case .idle:
            return .loaded

        case .loading:
            return .loading

        case let .finished(query, .success(assets)) where assets.isEmpty:
            return .empty(message: L10n.Search.noResults(query))

        case .finished(_, .success):
            return .loaded

        case let .finished(_, .failure(error)):
            return .error(message: error.message)
        }
    }
}
