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
        let expected = AssetListState(assets: [asset], loading: .none, error: .offline, loadedPage: 1)
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

        XCTAssertEqual(states.last, AssetListState(assets: [asset], loading: .none, loadedPage: 1))
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
            AssetListState(assets: [asset], loading: .refresh, loadedPage: 1),
            AssetListState(assets: [asset], loading: .none, error: .offline, loadedPage: 1)
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

    // MARK: - Next page

    func test_loadNextPage_requestsNextPageAndAppends() {
        let (sut, repository) = makeSUT()
        repository.assetsResponsesByPage[1] = .just(.fixture(Asset.fixtures(1...25), hasMore: true))
        repository.assetsResponsesByPage[2] = .just(.fixture(Asset.fixtures(26...30)))
        sut.load()

        sut.loadNextPage()

        XCTAssertEqual(repository.requestedPages.map(\.page), [1, 2])
        XCTAssertEqual(currentState(of: sut)?.assets, Asset.fixtures(1...30))
    }

    func test_loadNextPage_whileLoading_keepsAssetsAndShowsLoadingMore() {
        let (sut, repository) = makeSUT()
        repository.assetsResponsesByPage[1] = .just(.fixture(Asset.fixtures(1...25), hasMore: true))
        sut.load()

        sut.loadNextPage()

        XCTAssertEqual(currentState(of: sut)?.loading, .nextPage)
        XCTAssertEqual(currentState(of: sut)?.assets, Asset.fixtures(1...25))
    }

    func test_loadNextPage_skipsAssetsAlreadyInList() {
        let (sut, repository) = makeSUT()
        let movedAsset = Asset.fixture(id: "coin-3", price: 999)
        repository.assetsResponsesByPage[1] = .just(.fixture(Asset.fixtures(1...25), hasMore: true))
        repository.assetsResponsesByPage[2] = .just(.fixture([movedAsset] + Asset.fixtures(26...27)))
        sut.load()

        sut.loadNextPage()

        XCTAssertEqual(currentState(of: sut)?.assets, Asset.fixtures(1...27))
    }

    func test_loadNextPage_beforeFirstPage_doesNothing() {
        let (sut, repository) = makeSUT()

        sut.loadNextPage()

        XCTAssertTrue(repository.requestedPages.isEmpty)
    }

    func test_loadNextPage_whileNextPageLoads_isIgnored() {
        let (sut, repository) = makeSUT()
        repository.assetsResponsesByPage[1] = .just(.fixture(Asset.fixtures(1...25), hasMore: true))
        sut.load()

        sut.loadNextPage()
        sut.loadNextPage()

        XCTAssertEqual(repository.requestedPages.map(\.page), [1, 2])
    }

    func test_loadNextPage_duringFirstLoad_isIgnored() {
        let (sut, repository) = makeSUT()
        sut.load()

        sut.loadNextPage()

        XCTAssertEqual(repository.requestedPages.map(\.page), [1])
    }

    func test_loadNextPage_afterLastPage_doesNothing() {
        let (sut, repository) = makeSUT()
        repository.assetsResponsesByPage[1] = .just(.fixture(Asset.fixtures(1...25), hasMore: false))
        sut.load()

        sut.loadNextPage()

        XCTAssertEqual(repository.requestedPages.map(\.page), [1])
    }

    func test_nextPageFailure_keepsAssetsAndRetriesSamePage() {
        let (sut, repository) = makeSUT()
        repository.assetsResponsesByPage[1] = .just(.fixture(Asset.fixtures(1...25), hasMore: true))
        repository.assetsResponsesByPage[2] = .error(AppError.rateLimited)
        var failures: [AppError] = []
        let subscription = sut.failures.subscribe(onNext: { failures.append($0) })
        defer { subscription.dispose() }
        sut.load()

        sut.loadNextPage()
        sut.loadNextPage()

        XCTAssertEqual(repository.requestedPages.map(\.page), [1, 2, 2])
        XCTAssertEqual(failures, [.rateLimited, .rateLimited])
        XCTAssertEqual(currentState(of: sut)?.assets, Asset.fixtures(1...25))
    }

    func test_refresh_cancelsNextPageAndRestartsPagination() {
        let scheduler = TestScheduler(initialClock: 0)
        let (sut, repository) = makeSUT()
        let secondPage = scheduler.createColdObservable([
            .next(100, AssetPage.fixture(Asset.fixtures(26...50))), .completed(100)
        ])
        repository.assetsResponsesByPage[1] = .just(.fixture(Asset.fixtures(1...25), hasMore: true))
        repository.assetsResponsesByPage[2] = secondPage.asSingle()
        sut.load()
        sut.loadNextPage()
        scheduler.scheduleAt(10) {
            repository.assetsResponsesByPage[1] = .just(.fixture(Asset.fixtures(51...75), hasMore: true))
            sut.refresh()
        }

        scheduler.start()
        sut.loadNextPage()

        XCTAssertEqual(secondPage.subscriptions.first, Subscription(0, 10))
        XCTAssertEqual(currentState(of: sut)?.assets, Asset.fixtures(51...75))
        XCTAssertEqual(repository.requestedPages.map(\.page), [1, 2, 1, 2])
    }

    func test_refresh_afterSeveralPages_startsAgainFromSecondPage() {
        let (sut, repository) = makeSUT()
        repository.assetsResponsesByPage[1] = .just(.fixture(Asset.fixtures(1...25), hasMore: true))
        repository.assetsResponsesByPage[2] = .just(.fixture(Asset.fixtures(26...50), hasMore: true))
        sut.load()
        sut.loadNextPage()

        sut.refresh()
        sut.loadNextPage()

        XCTAssertEqual(repository.requestedPages.map(\.page), [1, 2, 1, 2])
    }

    // MARK: - Helpers

    private func makeSUT() -> (sut: AssetListLoader, repository: AssetRepositoryStub) {
        let repository = AssetRepositoryStub()
        return (AssetListLoader(repository: repository), repository)
    }

    private func currentState(of sut: AssetListLoader) -> AssetListState? {
        var state: AssetListState?
        sut.state
            .take(1)
            .subscribe(onNext: { state = $0 })
            .dispose()
        return state
    }

}
