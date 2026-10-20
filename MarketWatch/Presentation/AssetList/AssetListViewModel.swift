import RxCocoa
import RxSwift

enum ContentState: Equatable {
    case loading
    case loaded
    case error(message: String)
}

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

// MARK: - Content state

private extension ContentState {
    init(_ result: Result<[Asset], AppError>) {
        switch result {
        case .success:
            self = .loaded

        case let .failure(error):
            self = .error(message: error.message)
        }
    }
}

// MARK: - Error messages

extension AppError {
    var message: String {
        switch self {
        case .offline:
            return L10n.ErrorMessage.offline

        case .rateLimited:
            return L10n.ErrorMessage.rateLimited

        case .server:
            return L10n.ErrorMessage.server

        case .decoding:
            return L10n.ErrorMessage.decoding

        case .unknown:
            return L10n.ErrorMessage.unknown
        }
    }
}
