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
        XCTAssertEqual(cells.events.map(\.time), [600])
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
        XCTAssertEqual(cells.events.map { $0.value.element?.map(\.id) }, [["ethereum"]])
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
        XCTAssertEqual(cells.events, [.next(1400, [])])
    }

    func test_isSearchActive_followsTwoCharactersRightAway() {
        let (sut, _) = makeSUT()
        let query = typing([.next(0, "s"), .next(100, "so"), .next(200, "s")])

        let isSearchActive = record(sut, query: query).isSearchActive

        XCTAssertEqual(isSearchActive.events, [.next(0, false), .next(100, true), .next(200, false)])
    }

    // MARK: - Helpers

    private func makeSUT() -> (sut: AssetSearchViewModel, repository: AssetRepositoryStub) {
        let repository = AssetRepositoryStub()
        let sut = AssetSearchViewModel(repository: repository,
                                       formatter: AssetFormatter(locale: Locale(identifier: "pt_BR")),
                                       scheduler: scheduler)
        return (sut, repository)
    }

    private func typing(_ events: [Recorded<Event<String>>]) -> Observable<String> {
        scheduler.createHotObservable(events).asObservable()
    }

    /// Drivers must be built inside `SharingScheduler.mock` to deliver on the test scheduler.
    private func record(_ sut: AssetSearchViewModel,
                        query: Observable<String>) -> RecordedOutput {
        let recorded = RecordedOutput(cells: scheduler.createObserver([AssetCellViewModel].self),
                                      isSearchActive: scheduler.createObserver(Bool.self))
        SharingScheduler.mock(scheduler: scheduler) {
            let output = sut.transform(AssetSearchViewModel.Input(query: query))
            output.cells
                .drive(recorded.cells)
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
    let isSearchActive: TestableObserver<Bool>
}
