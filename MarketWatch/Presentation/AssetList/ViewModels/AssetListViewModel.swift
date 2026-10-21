import RxCocoa
import RxSwift

final class AssetListViewModel {
    struct Input {}

    struct Output {
        let cells: Driver<[AssetCellViewModel]>
        let contentState: Driver<ContentState>
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
        let firstPage = loadFirstPage()

        return Output(cells: cells(from: firstPage),
                      contentState: contentState(from: firstPage))
    }
}

// MARK: - Streams

private extension AssetListViewModel {
    typealias PageResult = Result<[Asset], AppError>

    func loadFirstPage() -> Observable<PageResult> {
        repository
            .assets(page: 1, pageSize: Self.pageSize)
            .asResult()
            .asObservable()
            .share(replay: 1)
    }

    func cells(from page: Observable<PageResult>) -> Driver<[AssetCellViewModel]> {
        page
            .compactMap { result in try? result.get() }
            .map { [formatter] assets in
                assets.map { AssetCellViewModel(asset: $0, formatter: formatter) }
            }
            .asDriver(onErrorDriveWith: .empty())
    }

    func contentState(from page: Observable<PageResult>) -> Driver<ContentState> {
        page
            .map(ContentState.init)
            .startWith(.loading)
            .asDriver(onErrorDriveWith: .empty())
    }
}
