import RxCocoa
import RxSwift

final class AssetDetailViewModel {
    struct Input {}

    struct Output {
        let header: Driver<AssetDetailHeader>
        let stats: Driver<[AssetDetailStat]>
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
        let stats = AssetDetailStat.stats(for: asset, formatter: formatter)

        return Output(header: .just(header),
                      stats: .just(stats))
    }
}
