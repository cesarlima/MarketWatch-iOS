import RxCocoa
import RxSwift

final class AssetListViewModel {
    struct Input {}

    struct Output {
        let cells: Driver<[AssetCellViewModel]>
    }

    static let pageSize = 25

    private let repository: AssetRepository
    private let formatter: AssetFormatter

    init(repository: AssetRepository, formatter: AssetFormatter) {
        self.repository = repository
        self.formatter = formatter
    }

    func transform(_ input: Input) -> Output {
        let cells = repository
            .assets(page: 1, pageSize: Self.pageSize)
            .map { [formatter] assets in
                assets.map { AssetCellViewModel(asset: $0, formatter: formatter) }
            }
            .asDriver(onErrorJustReturn: [])

        return Output(cells: cells)
    }
}
