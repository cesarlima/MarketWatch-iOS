import RxCocoa
import RxSwift
import RxTest
import XCTest
@testable import MarketWatch

final class AssetListViewModelTests: XCTestCase {
    private var scheduler: TestScheduler!
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        scheduler = TestScheduler(initialClock: 0,
                                  resolution: 0.001,
                                  simulateProcessingDelay: false)
        disposeBag = DisposeBag()
    }

    func test_initialLoad_requestsFirstPage() {
        let (sut, repository) = makeSUT()

        _ = record(sut)

        XCTAssertEqual(repository.requestedPages, [.init(page: 1, pageSize: 25)])
    }

    func test_initialLoad_mapsCells() {
        let (sut, repository) = makeSUT()
        repository.assetsResponse = response([.fixture()], at: 100)

        let cells = record(sut).cells

        let bitcoin = AssetCellViewModel(
            id: "bitcoin",
            name: "Bitcoin",
            symbol: "BTC",
            imageURL: URL(string: "https://example.com/bitcoin.png"),
            priceText: "US$\u{00A0}81.363,00",
            changeText: "-0,45%",
            trend: .down
        )
        XCTAssertEqual(cells.events, [.next(100, [bitcoin])])
    }

    func test_initialLoad_emitsLoadingThenLoaded() {
        let (sut, repository) = makeSUT()
        repository.assetsResponse = response([.fixture()], at: 100)

        let contentState = record(sut).contentState

        XCTAssertEqual(contentState.events, [.next(0, .loading), .next(100, .loaded)])
    }

    func test_initialLoadFailure_showsErrorState() {
        let (sut, repository) = makeSUT()
        repository.assetsResponse = failure(.offline, at: 100)

        let contentState = record(sut).contentState

        XCTAssertEqual(contentState.events, [
            .next(0, .loading),
            .next(100, .error(message: "Sem conexão com a internet."))
        ])
    }

    func test_retry_afterError_loadsAgain() {
        let (sut, repository) = makeSUT()
        repository.assetsResponse = failure(.offline, at: 100)
        scheduler.scheduleAt(400) {
            repository.assetsResponse = self.response([.fixture()], at: 100)
        }
        let retry = scheduler.createHotObservable([.next(500, ())]).asObservable()

        let contentState = record(sut, retry: retry).contentState

        XCTAssertEqual(contentState.events, [
            .next(0, .loading),
            .next(100, .error(message: "Sem conexão com a internet.")),
            .next(500, .loading),
            .next(600, .loaded)
        ])
        XCTAssertEqual(repository.requestedPages, [.init(page: 1, pageSize: 25), .init(page: 1, pageSize: 25)])
    }

    func test_refresh_reloadsAndTogglesIsRefreshing() {
        let (sut, repository) = makeSUT()
        repository.assetsResponse = response([.fixture()], at: 100)
        let refresh = scheduler.createHotObservable([.next(1000, ())]).asObservable()

        let isRefreshing = record(sut, refresh: refresh).isRefreshing

        XCTAssertEqual(isRefreshing.events, [.next(0, false), .next(1000, true), .next(1100, false)])
        XCTAssertEqual(repository.requestedPages.count, 2)
    }

    func test_refresh_replacesCells() {
        let (sut, repository) = makeSUT()
        repository.assetsResponse = response([.fixture(id: "bitcoin")], at: 100)
        scheduler.scheduleAt(900) {
            repository.assetsResponse = self.response([.fixture(id: "ethereum")], at: 100)
        }
        let refresh = scheduler.createHotObservable([.next(1000, ())]).asObservable()

        let cells = record(sut, refresh: refresh).cells

        XCTAssertEqual(cells.events.map(\.time), [100, 1100])
        XCTAssertEqual(cells.events.last?.value.element?.map(\.id), ["ethereum"])
    }

    func test_refresh_keepsListOnScreenWhileLoading() {
        let (sut, repository) = makeSUT()
        repository.assetsResponse = response([.fixture()], at: 100)
        let refresh = scheduler.createHotObservable([.next(1000, ())]).asObservable()

        let contentState = record(sut, refresh: refresh).contentState

        XCTAssertEqual(contentState.events, [.next(0, .loading), .next(100, .loaded)])
    }

    func test_refreshFailureWithList_emitsTransientErrorAndKeepsCells() {
        let (sut, repository) = makeSUT()
        repository.assetsResponse = response([.fixture()], at: 100)
        scheduler.scheduleAt(900) {
            repository.assetsResponse = self.failure(.rateLimited, at: 100)
        }
        let refresh = scheduler.createHotObservable([.next(1000, ())]).asObservable()

        let recorded = record(sut, refresh: refresh)

        XCTAssertEqual(recorded.transientError.events, [
            .next(1100, "Muitas requisições em pouco tempo. Tente novamente em instantes.")
        ])
        XCTAssertEqual(recorded.cells.events.map(\.time), [100])
        XCTAssertEqual(recorded.contentState.events, [.next(0, .loading), .next(100, .loaded)])
    }

    func test_refreshFailureWithoutList_keepsErrorStateWithoutBanner() {
        let (sut, repository) = makeSUT()
        repository.assetsResponse = failure(.offline, at: 100)
        let refresh = scheduler.createHotObservable([.next(1000, ())]).asObservable()

        let recorded = record(sut, refresh: refresh)

        XCTAssertEqual(recorded.transientError.events, [])
        XCTAssertEqual(recorded.contentState.events, [
            .next(0, .loading),
            .next(100, .error(message: "Sem conexão com a internet."))
        ])
    }

    // MARK: - Next page

    func test_displayingOneOfLastRows_loadsNextPage() {
        let (sut, repository) = makeSUT()
        repository.assetsResponsesByPage[1] = response(Asset.fixtures(1...25), at: 100, hasMore: true)
        repository.assetsResponsesByPage[2] = response(Asset.fixtures(26...30), at: 100)
        let displayedRow = scheduler.createHotObservable([.next(1000, 20)]).asObservable()

        let cells = record(sut, displayedRow: displayedRow).cells

        XCTAssertEqual(repository.requestedPages.map(\.page), [1, 2])
        XCTAssertEqual(cells.events.map(\.time), [100, 1100])
        XCTAssertEqual(cells.events.last?.value.element?.count, 30)
    }

    func test_displayingRowAwayFromEnd_doesNotLoadNextPage() {
        let (sut, repository) = makeSUT()
        repository.assetsResponsesByPage[1] = response(Asset.fixtures(1...25), at: 100, hasMore: true)
        let displayedRow = scheduler.createHotObservable([.next(1000, 19)]).asObservable()

        _ = record(sut, displayedRow: displayedRow)

        XCTAssertEqual(repository.requestedPages.map(\.page), [1])
    }

    func test_isLoadingNextPage_togglesDuringLoad() {
        let (sut, repository) = makeSUT()
        repository.assetsResponsesByPage[1] = response(Asset.fixtures(1...25), at: 100, hasMore: true)
        repository.assetsResponsesByPage[2] = response(Asset.fixtures(26...30), at: 100)
        let displayedRow = scheduler.createHotObservable([.next(1000, 20)]).asObservable()

        let isLoadingNextPage = record(sut, displayedRow: displayedRow).isLoadingNextPage

        XCTAssertEqual(isLoadingNextPage.events, [.next(0, false), .next(1000, true), .next(1100, false)])
    }

    func test_refresh_doesNotShowNextPageSpinner() {
        let (sut, repository) = makeSUT()
        repository.assetsResponse = response(Asset.fixtures(1...25), at: 100, hasMore: true)
        let refresh = scheduler.createHotObservable([.next(1000, ())]).asObservable()

        let isLoadingNextPage = record(sut, refresh: refresh).isLoadingNextPage

        XCTAssertEqual(isLoadingNextPage.events, [.next(0, false)])
    }

    func test_loadingNextPage_keepsScreenLoaded() {
        let (sut, repository) = makeSUT()
        repository.assetsResponsesByPage[1] = response(Asset.fixtures(1...25), at: 100, hasMore: true)
        repository.assetsResponsesByPage[2] = response(Asset.fixtures(26...30), at: 100)
        let displayedRow = scheduler.createHotObservable([.next(1000, 20)]).asObservable()

        let contentState = record(sut, displayedRow: displayedRow).contentState

        XCTAssertEqual(contentState.events, [.next(0, .loading), .next(100, .loaded)])
    }

    func test_nextPageFailure_showsBannerAndKeepsCells() {
        let (sut, repository) = makeSUT()
        repository.assetsResponsesByPage[1] = response(Asset.fixtures(1...25), at: 100, hasMore: true)
        repository.assetsResponsesByPage[2] = failure(.rateLimited, at: 100)
        let displayedRow = scheduler.createHotObservable([.next(1000, 20)]).asObservable()

        let recorded = record(sut, displayedRow: displayedRow)

        XCTAssertEqual(recorded.transientError.events, [
            .next(1100, "Muitas requisições em pouco tempo. Tente novamente em instantes.")
        ])
        XCTAssertEqual(recorded.cells.events.map(\.time), [100])
    }

    // MARK: - Selection

    func test_selection_emitsAssetAtSelectedRow() {
        let (sut, repository) = makeSUT()
        let bitcoin = Asset.fixture(id: "bitcoin")
        let ethereum = Asset.fixture(id: "ethereum", name: "Ethereum")
        repository.assetsResponse = response([bitcoin, ethereum], at: 100)
        let selection = scheduler.createHotObservable([.next(200, 1)]).asObservable()

        let selectedAsset = record(sut, selection: selection).selectedAsset

        XCTAssertEqual(selectedAsset.events, [.next(200, ethereum)])
    }

    func test_synchronousLoad_presentsAssetsWithoutDuplicateRequests() {
        let (sut, repository) = makeSUT()
        repository.assetsResponse = .just(.fixture())

        let recorded = record(sut)

        XCTAssertEqual(recorded.cells.events.last?.value.element?.map(\.id), ["bitcoin"])
        XCTAssertEqual(recorded.contentState.events.last?.value.element, .loaded)
        XCTAssertEqual(repository.requestedPages.count, 1)
    }

    func test_repeatedRefreshFailure_emitsOneBannerForEachAttempt() {
        let (sut, repository) = makeSUT()
        repository.assetsResponse = response([.fixture()], at: 100)
        scheduler.scheduleAt(200) {
            repository.assetsResponse = .error(AppError.offline)
        }
        let refresh = scheduler.createHotObservable([.next(300, ()), .next(500, ())]).asObservable()

        let recorded = record(sut, refresh: refresh)

        XCTAssertEqual(recorded.transientError.events, [
            .next(300, "Sem conexão com a internet."),
            .next(500, "Sem conexão com a internet.")
        ])
        XCTAssertEqual(recorded.cells.events.count, 1)
        XCTAssertEqual(recorded.isRefreshing.events.last?.value.element, false)
    }

    func test_transientError_doesNotReplayWhenSubscribedAfterFailure() {
        let (sut, repository) = makeSUT()
        repository.assetsResponse = response([.fixture()], at: 100)
        scheduler.scheduleAt(200) {
            repository.assetsResponse = .error(AppError.offline)
        }
        let refresh = scheduler.createHotObservable([.next(300, ()), .next(500, ())]).asObservable()
        let errors = scheduler.createObserver(String.self)
        SharingScheduler.mock(scheduler: scheduler) {
            let output = sut.transform(.init(selection: .never(),
                                             retry: .never(),
                                             refresh: refresh,
                                             displayedRow: .never()))
            output.cells.drive().disposed(by: disposeBag)
            scheduler.scheduleAt(400) {
                output.transientError.emit(to: errors).disposed(by: self.disposeBag)
            }
        }

        scheduler.start()

        XCTAssertEqual(errors.events, [.next(500, "Sem conexão com a internet.")])
    }

    func test_selectionAfterRefresh_usesUpdatedAssetsAndIgnoresInvalidRows() {
        let (sut, repository) = makeSUT()
        repository.assetsResponse = response([.fixture(id: "old")], at: 100)
        let asset = Asset.fixture(id: "new")
        scheduler.scheduleAt(200) {
            repository.assetsResponse = .just(.fixture([asset]))
        }
        let refresh = scheduler.createHotObservable([.next(300, ())]).asObservable()
        let selection = scheduler.createHotObservable([
            .next(400, 0), .next(500, -1), .next(600, 1)
        ]).asObservable()

        let recorded = record(sut, selection: selection, refresh: refresh)

        XCTAssertEqual(recorded.selectedAsset.events, [.next(400, asset)])
    }

    // MARK: - Helpers

    private func makeSUT() -> (sut: AssetListViewModel, repository: AssetRepositoryStub) {
        let repository = AssetRepositoryStub()
        let formmater = AssetFormatter(locale: Locale(identifier: "pt_BR"))
        let sut = AssetListViewModel(loader: AssetListLoader(repository: repository),
                                     formatter: formmater)
        return (sut, repository)
    }

    private func response(_ assets: [Asset],
                          at time: TestTime,
                          hasMore: Bool = false) -> Single<AssetPage> {
        scheduler
            .createColdObservable([.next(time, AssetPage.fixture(assets, hasMore: hasMore)), .completed(time)])
            .asSingle()
    }

    private func failure(_ error: AppError, at time: TestTime) -> Single<AssetPage> {
        scheduler
            .createColdObservable([.error(time, error)])
            .asSingle()
    }

    /// Drivers must be built inside `SharingScheduler.mock` to deliver on the test scheduler.
    private func record(_ sut: AssetListViewModel,
                        selection: Observable<Int> = .never(),
                        retry: Observable<Void> = .never(),
                        refresh: Observable<Void> = .never(),
                        displayedRow: Observable<Int> = .never()) -> RecordedOutput {
        let recorded = RecordedOutput(cells: scheduler.createObserver([AssetCellViewModel].self),
                                      contentState: scheduler.createObserver(ContentState.self),
                                      selectedAsset: scheduler.createObserver(Asset.self),
                                      isRefreshing: scheduler.createObserver(Bool.self),
                                      transientError: scheduler.createObserver(String.self),
                                      isLoadingNextPage: scheduler.createObserver(Bool.self))
        SharingScheduler.mock(scheduler: scheduler) {
            let output = sut.transform(AssetListViewModel.Input(selection: selection,
                                                                retry: retry,
                                                                refresh: refresh,
                                                                displayedRow: displayedRow))
            output.cells
                .drive(recorded.cells)
                .disposed(by: disposeBag)
            output.contentState
                .drive(recorded.contentState)
                .disposed(by: disposeBag)
            output.selectedAsset
                .emit(to: recorded.selectedAsset)
                .disposed(by: disposeBag)
            output.isRefreshing
                .drive(recorded.isRefreshing)
                .disposed(by: disposeBag)
            output.transientError
                .emit(to: recorded.transientError)
                .disposed(by: disposeBag)
            output.isLoadingNextPage
                .drive(recorded.isLoadingNextPage)
                .disposed(by: disposeBag)
        }
        scheduler.start()
        return recorded
    }
}

// MARK: - Recording

private struct RecordedOutput {
    let cells: TestableObserver<[AssetCellViewModel]>
    let contentState: TestableObserver<ContentState>
    let selectedAsset: TestableObserver<Asset>
    let isRefreshing: TestableObserver<Bool>
    let transientError: TestableObserver<String>
    let isLoadingNextPage: TestableObserver<Bool>
}
