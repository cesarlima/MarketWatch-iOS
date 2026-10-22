import RxCocoa
import RxSwift

final class AssetSearchViewModel {
    struct Input {
        let query: Observable<String>
    }

    struct Output {
        let cells: Driver<[AssetCellViewModel]>
        let isSearchActive: Driver<Bool>
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

        return Output(cells: makeCells(for: query),
                      isSearchActive: searchActiveState(for: query))
    }
}

// MARK: - Output

private extension AssetSearchViewModel {
    func makeCells(for query: Observable<String>) -> Driver<[AssetCellViewModel]> {
        searchResults(for: query)
            .map { [formatter] assets in
                assets.map { AssetCellViewModel(asset: $0, formatter: formatter) }
            }
            .asDriver(onErrorDriveWith: .empty())
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
    func searchResults(for query: Observable<String>) -> Observable<[Asset]> {
        query
            .debounce(Self.debounce, scheduler: scheduler)
            .distinctUntilChanged()
            .flatMapLatest { [repository] text -> Observable<[Asset]> in
                guard Self.isSearchable(text) else {
                    return .just([])
                }
                return repository
                    .searchAssets(query: text)
                    .asObservable()
                    .catchAndReturn([])
            }
    }

    static func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func isSearchable(_ text: String) -> Bool {
        text.count >= minimumQueryLength
    }
}
