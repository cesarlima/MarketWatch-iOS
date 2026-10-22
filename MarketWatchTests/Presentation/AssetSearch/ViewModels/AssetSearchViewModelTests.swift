import RxCocoa
import RxSwift
import RxTest
import XCTest
@testable import MarketWatch

final class AssetSearchViewModelTests: XCTestCase {
    private var scheduler: TestScheduler!
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        scheduler = TestScheduler(initialClock: 0,
                                  resolution: 0.001,
                                  simulateProcessingDelay: false)
        disposeBag = DisposeBag()
    }

    func test_typing_searchesOnceAfterPause() {
        let (sut, repository) = makeSUT()
        repository.searchResponsesByQuery["sol"] = .just([.fixture(id: "solana")])
        let query = typing([.next(0, "s"), .next(100, "so"), .next(200, "sol")])

        let cells = record(sut, query: query).cells

        XCTAssertEqual(repository.requestedQueries, ["sol"])
        XCTAssertEqual(cells.events.last?.time, 600)
        XCTAssertEqual(cells.events.last?.value.element?.map(\.id), ["solana"])
    }

    func test_text_isTrimmedBeforeSearching() {
        let (sut, repository) = makeSUT()
        let query = typing([.next(0, " sol ")])

        _ = record(sut, query: query)

        XCTAssertEqual(repository.requestedQueries, ["sol"])
    }

    func test_shortOrBlankText_doesNotSearch() {
        let (sut, repository) = makeSUT()
        let query = typing([.next(0, "s"), .next(1000, "  ")])

        _ = record(sut, query: query)

        XCTAssertTrue(repository.requestedQueries.isEmpty)
    }

    func test_sameTextAfterTrim_doesNotSearchAgain() {
        let (sut, repository) = makeSUT()
        let query = typing([.next(0, "sol"), .next(1000, "sol ")])

        _ = record(sut, query: query)

        XCTAssertEqual(repository.requestedQueries, ["sol"])
    }

    func test_latestSearchWins() {
        let (sut, repository) = makeSUT()
        let slowSearch = scheduler.createColdObservable([
            .next(2000, [Asset.fixture(id: "solana")]), .completed(2000)
        ])
        repository.searchResponsesByQuery["sol"] = slowSearch.asSingle()
        repository.searchResponsesByQuery["eth"] = .just([.fixture(id: "ethereum")])
        let query = typing([.next(0, "sol"), .next(1000, "eth")])

        let cells = record(sut, query: query).cells

        XCTAssertEqual(slowSearch.subscriptions, [Subscription(400, 1400)])
        XCTAssertEqual(cells.events.last?.value.element?.map(\.id), ["ethereum"])
        XCTAssertFalse(cells.events.contains { $0.value.element?.contains { $0.id == "solana" } == true })
    }

    func test_clearingText_cancelsPendingSearchAndClearsResults() {
        let (sut, repository) = makeSUT()
        let slowSearch = scheduler.createColdObservable([
            .next(2000, [Asset.fixture(id: "solana")]), .completed(2000)
        ])
        repository.searchResponsesByQuery["sol"] = slowSearch.asSingle()
        let query = typing([.next(0, "sol"), .next(1000, "")])

        let cells = record(sut, query: query).cells

        XCTAssertEqual(slowSearch.subscriptions, [Subscription(400, 1400)])
        XCTAssertEqual(cells.events.last?.value.element, [])
        XCTAssertFalse(cells.events.contains { $0.value.element?.contains { $0.id == "solana" } == true })
    }

    func test_isSearchActive_followsTwoCharactersRightAway() {
        let (sut, _) = makeSUT()
        let query = typing([.next(0, "s"), .next(100, "so"), .next(200, "s")])

        let isSearchActive = record(sut, query: query).isSearchActive

        XCTAssertEqual(isSearchActive.events, [.next(0, false), .next(100, true), .next(200, false)])
    }

    // MARK: - States

    func test_search_showsLoadingThenResults() {
        let (sut, repository) = makeSUT()
        repository.searchResponsesByQuery["sol"] = response([.fixture(id: "solana")], at: 100)
        let query = typing([.next(0, "sol")])

        let contentState = record(sut, query: query).contentState

        XCTAssertEqual(contentState.events, [.next(400, .loading), .next(500, .loaded)])
    }

    func test_noResults_showsMessageWithText() {
        let (sut, repository) = makeSUT()
        repository.searchResponsesByQuery["xyz"] = .just([])
        let query = typing([.next(0, "xyz")])

        let contentState = record(sut, query: query).contentState

        XCTAssertEqual(contentState.events.last?.value.element,
                       .empty(message: "Nenhum ativo encontrado para “xyz”"))
    }

    func test_failure_showsErrorMessageWithoutCells() {
        let (sut, repository) = makeSUT()
        repository.searchResponsesByQuery["sol"] = .error(AppError.rateLimited)
        let query = typing([.next(0, "sol")])

        let recorded = record(sut, query: query)

        XCTAssertEqual(recorded.contentState.events.last?.value.element,
                       .error(message: "Muitas requisições em pouco tempo. Tente novamente em instantes."))
        XCTAssertEqual(recorded.cells.events.last?.value.element, [])
    }

    func test_retry_repeatsLastSearch() {
        let (sut, repository) = makeSUT()
        repository.searchResponsesByQuery["sol"] = .error(AppError.offline)
        scheduler.scheduleAt(900) {
            repository.searchResponsesByQuery["sol"] = .just([.fixture(id: "solana")])
        }
        let query = typing([.next(0, "sol")])
        let retry = scheduler.createHotObservable([.next(1000, ())]).asObservable()

        let recorded = record(sut, query: query, retry: retry)

        XCTAssertEqual(repository.requestedQueries, ["sol", "sol"])
        XCTAssertEqual(recorded.contentState.events.last, .next(1000, .loaded))
        XCTAssertEqual(recorded.cells.events.last?.value.element?.map(\.id), ["solana"])
    }

    func test_newSearch_clearsPreviousResultsWhileLoading() {
        let (sut, repository) = makeSUT()
        repository.searchResponsesByQuery["sol"] = .just([.fixture(id: "solana")])
        repository.searchResponsesByQuery["eth"] = response([.fixture(id: "ethereum")], at: 100)
        let query = typing([.next(0, "sol"), .next(1000, "eth")])

        let recorded = record(sut, query: query)

        XCTAssertTrue(recorded.cells.events.contains(.next(1400, [])))
        XCTAssertTrue(recorded.contentState.events.contains(.next(1400, .loading)))
        XCTAssertEqual(recorded.cells.events.last?.time, 1500)
        XCTAssertEqual(recorded.cells.events.last?.value.element?.map(\.id), ["ethereum"])
    }

    func test_clearingText_showsNoSpinnerOrMessage() {
        let (sut, repository) = makeSUT()
        repository.searchResponsesByQuery["sol"] = .just([.fixture(id: "solana")])
        let query = typing([.next(0, "sol"), .next(1000, "")])

        let recorded = record(sut, query: query)

        XCTAssertEqual(recorded.contentState.events.last?.value.element, .loaded)
        XCTAssertEqual(recorded.cells.events.last?.value.element, [])
    }

    // MARK: - Helpers

    private func makeSUT() -> (sut: AssetSearchViewModel, repository: AssetRepositoryStub) {
        let repository = AssetRepositoryStub()
        let sut = AssetSearchViewModel(repository: repository,
                                       formatter: AssetFormatter(locale: Locale(identifier: "pt_BR")),
                                       scheduler: scheduler)
        return (sut, repository)
    }

    private func response(_ assets: [Asset], at time: TestTime) -> Single<[Asset]> {
        scheduler
            .createColdObservable([.next(time, assets), .completed(time)])
            .asSingle()
    }

    private func typing(_ events: [Recorded<Event<String>>]) -> Observable<String> {
        scheduler.createHotObservable(events).asObservable()
    }

    /// Drivers must be built inside `SharingScheduler.mock` to deliver on the test scheduler.
    private func record(_ sut: AssetSearchViewModel,
                        query: Observable<String>,
                        retry: Observable<Void> = .never()) -> RecordedOutput {
        let recorded = RecordedOutput(cells: scheduler.createObserver([AssetCellViewModel].self),
                                      contentState: scheduler.createObserver(ContentState.self),
                                      isSearchActive: scheduler.createObserver(Bool.self))
        SharingScheduler.mock(scheduler: scheduler) {
            let output = sut.transform(AssetSearchViewModel.Input(query: query,
                                                                  retry: retry))
            output.cells
                .drive(recorded.cells)
                .disposed(by: disposeBag)
            output.contentState
                .drive(recorded.contentState)
                .disposed(by: disposeBag)
            output.isSearchActive
                .drive(recorded.isSearchActive)
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
    let isSearchActive: TestableObserver<Bool>
}
