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
        let firstPage = repository
            .assets(page: 1, pageSize: Self.pageSize)
            .map { assets -> Result<[Asset], AppError> in
                .success(assets)
            }
            .catch { error in
                .just(.failure(error as? AppError ?? .unknown))
            }
            .asObservable()
            .share(replay: 1)

        let cells = firstPage
            .compactMap { result -> [Asset]? in
                guard case let .success(assets) = result else {
                    return nil
                }
                return assets
            }
            .map { [formatter] assets in
                assets.map { AssetCellViewModel(asset: $0, formatter: formatter) }
            }
            .asDriver(onErrorDriveWith: .empty())

        let contentState = firstPage
            .map(ContentState.init)
            .startWith(.loading)
            .asDriver(onErrorDriveWith: .empty())

        return Output(cells: cells,
                      contentState: contentState)
    }
}
