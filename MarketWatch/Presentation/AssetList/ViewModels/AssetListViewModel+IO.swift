import RxCocoa
import RxSwift

extension AssetListViewModel {
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
}
