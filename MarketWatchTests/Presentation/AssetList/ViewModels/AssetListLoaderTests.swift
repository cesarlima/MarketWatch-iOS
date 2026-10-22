import RxSwift
import RxTest
import XCTest
@testable import MarketWatch

final class AssetListLoaderTests: XCTestCase {
    private weak var observedLoader: AssetListLoader?

    func test_beforeLoad_isIdleWithoutRequestingAssets() {
        let repository = AssetRepositoryStub()
        let sut = AssetListLoader(repository: repository)
        var latest: AssetListState?
        let subscription = sut.state.subscribe(onNext: { latest = $0 })
        defer { subscription.dispose() }

        XCTAssertEqual(latest?.loading, AssetListState.Loading.none)
        XCTAssertTrue(repository.requestedPages.isEmpty)
    }

    func test_failures_publishEachAttemptAfterUpdatingState() {
        let repository = AssetRepositoryStub()
        let asset = Asset.fixture()
        repository.assetsResponse = .just(.fixture([asset]))
        let sut = AssetListLoader(repository: repository)
        var latest: AssetListState?
        var statesAtFailure: [AssetListState] = []
        var failures: [AppError] = []
        let stateSubscription = sut.state.subscribe(onNext: { latest = $0 })
        let failureSubscription = sut.failures.subscribe(onNext: { error in
            failures.append(error)
            if let latest {
                statesAtFailure.append(latest)
            }
        })
        defer {
            stateSubscription.dispose()
            failureSubscription.dispose()
        }
        sut.load()
        repository.assetsResponse = .error(AppError.offline)

        sut.refresh()
        sut.refresh()

        XCTAssertEqual(failures, [.offline, .offline])
        let expected = AssetListState(assets: [asset], loading: .none, error: .offline)
        XCTAssertEqual(statesAtFailure, [expected, expected])
    }

    func test_failures_doNotReplayToNewSubscribers() {
        let repository = AssetRepositoryStub()
        repository.assetsResponse = .error(AppError.offline)
        let sut = AssetListLoader(repository: repository)
        sut.load()
        var failures: [AppError] = []
        let subscription = sut.failures.subscribe(onNext: { failures.append($0) })
        defer { subscription.dispose() }

        XCTAssertTrue(failures.isEmpty)

        sut.load()

        XCTAssertEqual(failures, [.offline])
    }

    func test_load_deliversSynchronousResult() {
        let repository = AssetRepositoryStub()
        let asset = Asset.fixture()
        repository.assetsResponse = .just(.fixture([asset]))
        let sut = AssetListLoader(repository: repository)
        var states: [AssetListState] = []
        let subscription = sut.state.subscribe(onNext: { states.append($0) })
        defer { subscription.dispose() }

        sut.load()

        XCTAssertEqual(states.last, AssetListState(assets: [asset], loading: .none))
        XCTAssertEqual(repository.requestedPages, [.init(page: 1, pageSize: 25)])
    }

    func test_refreshFailure_preservesAssetsAndStopsLoading() {
        let repository = AssetRepositoryStub()
        let asset = Asset.fixture()
        repository.assetsResponse = .just(.fixture([asset]))
        let sut = AssetListLoader(repository: repository)
        var states: [AssetListState] = []
        let subscription = sut.state.subscribe(onNext: { states.append($0) })
        defer { subscription.dispose() }
        sut.load()
        repository.assetsResponse = .error(AppError.offline)

        sut.refresh()

        XCTAssertEqual(Array(states.suffix(2)), [
            AssetListState(assets: [asset], loading: .refresh),
            AssetListState(assets: [asset], loading: .none, error: .offline)
        ])
    }

    func test_refresh_cancelsOldRequestAndKeepsNewResult() {
        let scheduler = TestScheduler(initialClock: 0)
        let repository = AssetRepositoryStub()
        let old = scheduler.createColdObservable([
            .next(100, AssetPage.fixture([.fixture(id: "old")])), .completed(100)
        ])
        repository.assetsResponse = old.asSingle()
        let sut = AssetListLoader(repository: repository)
        var latest: AssetListState?
        let subscription = sut.state.subscribe(onNext: { latest = $0 })
        defer { subscription.dispose() }
        sut.load()
        scheduler.scheduleAt(10) {
            repository.assetsResponse = .just(.fixture([.fixture(id: "new")]))
            sut.refresh()
        }

        scheduler.start()

        XCTAssertEqual(old.subscriptions, [Subscription(0, 10)])
        XCTAssertEqual(latest?.assets.map(\.id), ["new"])
        XCTAssertEqual(latest?.loading, AssetListState.Loading.none)
    }

    func test_deinit_cancelsPendingRequest() {
        let repository = AssetRepositoryStub()
        var cancelled = false
        repository.assetsResponse = Single.create { _ in
            Disposables.create { cancelled = true }
        }
        var sut: AssetListLoader? = AssetListLoader(repository: repository)
        observedLoader = sut
        sut?.load()

        sut = nil

        XCTAssertNil(observedLoader)
        XCTAssertTrue(cancelled)
    }
}
