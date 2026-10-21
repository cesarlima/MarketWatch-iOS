import RxCocoa
import RxSwift
import RxTest
import XCTest
@testable import MarketWatch

final class AssetDetailViewModelTests: XCTestCase {
    private var scheduler: TestScheduler!
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        scheduler = TestScheduler(initialClock: 0,
                                  resolution: 0.001,
                                  simulateProcessingDelay: false)
        disposeBag = DisposeBag()
    }

    func test_header_showsListDataRightAway() {
        let (sut, _) = makeSUT()

        let header = record(sut).header

        XCTAssertEqual(header.events.first?.time, 0)
        XCTAssertEqual(header.events.first?.value.element?.name, "Bitcoin")
    }

    func test_stats_showListDataRightAway() {
        let (sut, _) = makeSUT()

        let stats = record(sut).stats

        XCTAssertEqual(stats.events.first?.time, 0)
        XCTAssertEqual(stats.events.first?.value.element?.count, 5)
    }

    func test_open_requestsFreshDataForTheAsset() {
        let (sut, repository) = makeSUT()

        _ = record(sut)

        XCTAssertEqual(repository.requestedAssetIDs, ["bitcoin"])
    }

    func test_freshData_updatesHeaderAndStats() {
        let (sut, repository) = makeSUT()
        repository.assetResponse = response(.fixture(price: 90_000), at: 100)

        let recorded = record(sut)

        XCTAssertEqual(recorded.header.events.map(\.time), [0, 100])
        XCTAssertEqual(recorded.header.events.last?.value.element?.priceText, "US$\u{00A0}90.000,00")
        XCTAssertEqual(recorded.stats.events.map(\.time), [0, 100])
    }

    func test_chartState_isLoadingThenLoaded() {
        let (sut, repository) = makeSUT()
        repository.assetResponse = response(.fixture(), at: 100)

        let chartState = record(sut).chartState

        XCTAssertEqual(chartState.events, [.next(0, .loading), .next(100, .loaded)])
    }

    func test_failure_showsChartUnavailableAndKeepsListData() {
        let (sut, repository) = makeSUT()
        repository.assetResponse = failure(.offline, at: 100)

        let recorded = record(sut)

        XCTAssertEqual(recorded.chartState.events, [
            .next(0, .loading),
            .next(100, .unavailable(message: "Gráfico indisponível"))
        ])
        XCTAssertEqual(recorded.header.events.map(\.time), [0])
    }

    func test_retry_requestsAgain() {
        let (sut, repository) = makeSUT()
        repository.assetResponse = failure(.offline, at: 100)
        let retry = scheduler.createHotObservable([.next(200, ())]).asObservable()

        let chartState = record(sut, retry: retry).chartState

        XCTAssertEqual(repository.requestedAssetIDs, ["bitcoin", "bitcoin"])
        XCTAssertEqual(chartState.events.map(\.time), [0, 100, 200, 300])
        XCTAssertEqual(chartState.events[2].value.element, .loading)
    }

    // MARK: - Helpers

    private func makeSUT() -> (sut: AssetDetailViewModel, repository: AssetRepositoryStub) {
        let repository = AssetRepositoryStub()
        let sut = AssetDetailViewModel(asset: .fixture(),
                                       repository: repository,
                                       formatter: AssetFormatter(locale: Locale(identifier: "pt_BR")))
        return (sut, repository)
    }

    private func response(_ asset: Asset, at time: TestTime) -> Single<Asset> {
        scheduler
            .createColdObservable([.next(time, asset), .completed(time)])
            .asSingle()
    }

    private func failure(_ error: AppError, at time: TestTime) -> Single<Asset> {
        scheduler
            .createColdObservable([.error(time, error)])
            .asSingle()
    }

    /// Drivers must be built inside `SharingScheduler.mock` to deliver on the test scheduler.
    private func record(_ sut: AssetDetailViewModel,
                        retry: Observable<Void> = .never()) -> RecordedOutput {
        let recorded = RecordedOutput(header: scheduler.createObserver(AssetDetailHeader.self),
                                      stats: scheduler.createObserver([AssetDetailStat].self),
                                      chartState: scheduler.createObserver(ChartState.self))
        SharingScheduler.mock(scheduler: scheduler) {
            let output = sut.transform(AssetDetailViewModel.Input(retry: retry))
            output.header
                .drive(recorded.header)
                .disposed(by: disposeBag)
            output.stats
                .drive(recorded.stats)
                .disposed(by: disposeBag)
            output.chartState
                .drive(recorded.chartState)
                .disposed(by: disposeBag)
        }
        scheduler.start()
        return recorded
    }
}

// MARK: - Recording

private struct RecordedOutput {
    let header: TestableObserver<AssetDetailHeader>
    let stats: TestableObserver<[AssetDetailStat]>
    let chartState: TestableObserver<ChartState>
}
