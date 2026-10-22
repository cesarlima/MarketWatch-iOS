import RxRelay
import RxSwift

final class AssetListLoader {
    private static let pageSize = 25

    private let repository: AssetRepository
    private let requests = PublishRelay<AssetListState.Loading>()
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
        requests.accept(.initial)
    }

    func refresh() {
        requests.accept(.refresh)
    }
}

// MARK: - Requests

private extension AssetListLoader {
    func bindRequests() {
        requests
            .do(onNext: { [weak self] loading in
                self?.startLoading(loading)
            })
            .flatMapLatest { [repository] _ in
                repository
                    .assets(page: 1, pageSize: Self.pageSize)
                    .map(\.assets)
                    .asResult()
                    .asObservable()
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] result in
                switch result {
                case let .success(assets):
                    self?.receive(assets)

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

    func receive(_ assets: [Asset]) {
        stateRelay.accept(AssetListState(assets: assets, loading: .none))
    }

    func receiveError(_ error: AppError) {
        var state = stateRelay.value
        state.loading = .none
        state.error = error
        stateRelay.accept(state)
        failureRelay.accept(error)
    }
}
