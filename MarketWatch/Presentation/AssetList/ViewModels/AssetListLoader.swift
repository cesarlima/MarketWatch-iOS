import RxRelay
import RxSwift

final class AssetListLoader {
    private static let pageSize = 25

    private let repository: AssetRepository
    private let requests = PublishRelay<Request>()
    private let stateRelay = BehaviorRelay(value: AssetListState())
    private let failureRelay = PublishRelay<AppError>()
    private let disposeBag = DisposeBag()

    var state: Observable<AssetListState> {
        stateRelay.asObservable()
    }

    var failures: Observable<AppError> {
        failureRelay.asObservable()
    }

    init(repository: AssetRepository) {
        self.repository = repository
        bindRequests()
    }

    func load() {
        requests.accept(Request(page: 1, loading: .initial))
    }

    func refresh() {
        requests.accept(Request(page: 1, loading: .refresh))
    }

    func loadNextPage() {
        let state = stateRelay.value
        guard state.canLoadNextPage else {
            return
        }
        requests.accept(Request(page: state.loadedPage + 1, loading: .nextPage))
    }
}

// MARK: - Requests

private extension AssetListLoader {
    struct Request {
        let page: Int
        let loading: AssetListState.Loading
    }

    func bindRequests() {
        requests
            .do(onNext: { [weak self] request in
                self?.startLoading(request.loading)
            })
            .flatMapLatest { [repository] request in
                repository
                    .assets(page: request.page, pageSize: Self.pageSize)
                    .asResult()
                    .asObservable()
                    .map { (request, $0) }
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] request, result in
                switch result {
                case let .success(page):
                    self?.receive(page, for: request)

                case let .failure(error):
                    self?.receiveError(error)
                }
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - State

private extension AssetListLoader {
    func startLoading(_ loading: AssetListState.Loading) {
        MainScheduler.ensureRunningOnMainThread()
        var state = stateRelay.value
        state.loading = loading
        state.error = nil
        stateRelay.accept(state)
    }

    func receive(_ page: AssetPage, for request: Request) {
        let assets = request.page == 1
            ? page.assets
            : stateRelay.value.assets.appendingNew(page.assets)

        stateRelay.accept(AssetListState(assets: assets,
                                         loading: .none,
                                         loadedPage: request.page,
                                         hasMore: page.hasMore))
    }

    func receiveError(_ error: AppError) {
        var state = stateRelay.value
        state.loading = .none
        state.error = error
        stateRelay.accept(state)
        failureRelay.accept(error)
    }
}

// MARK: - Appending

private extension Array where Element == Asset {
    /// Rankings move between requests, so a new page may repeat an asset already in the list.
    func appendingNew(_ assets: [Asset]) -> [Asset] {
        let ids = Set(map(\.id))
        return self + assets.filter { !ids.contains($0.id) }
    }
}
