import RxCocoa
import RxSwift

final class AssetDetailViewModel {
    struct Input {}

    struct Output {
        let header: Driver<AssetDetailHeader>
    }

    private let asset: Asset
    private let formatter: AssetFormatter

    init(asset: Asset,
         formatter: AssetFormatter) {
        self.asset = asset
        self.formatter = formatter
    }

    func transform(_ input: Input) -> Output {
        let header = AssetDetailHeader(asset: asset, formatter: formatter)

        return Output(header: .just(header))
    }
}
