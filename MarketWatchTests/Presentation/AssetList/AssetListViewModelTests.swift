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

        _ = cells(of: sut)

        XCTAssertEqual(repository.requestedPages, [.init(page: 1, pageSize: 25)])
    }

    func test_initialLoad_mapsCells() {
        let (sut, repository) = makeSUT()
        repository.assetsResponse = response([.fixture()], at: 100)

        let cells = cells(of: sut)

        let bitcoin = AssetCellViewModel(
            id: "bitcoin",
            name: "Bitcoin",
            symbol: "BTC",
            priceText: "US$\u{00A0}81.363,00",
            changeText: "-0,45%",
            trend: .down
        )
        XCTAssertEqual(cells.events, [.next(100, [bitcoin]), .completed(100)])
    }

    // MARK: - Helpers

    private func makeSUT() -> (sut: AssetListViewModel, repository: AssetRepositoryStub) {
        let repository = AssetRepositoryStub()
        let formmater = AssetFormatter(locale: Locale(identifier: "pt_BR"))
        let sut = AssetListViewModel(repository: repository,
                                     formatter: formmater)
        return (sut, repository)
    }

    private func response(_ assets: [Asset], at time: TestTime) -> Single<[Asset]> {
        scheduler
            .createColdObservable([.next(time, assets), .completed(time)])
            .asSingle()
    }

    /// Drivers must be built inside `SharingScheduler.mock` to deliver on the test scheduler.
    private func cells(of sut: AssetListViewModel) -> TestableObserver<[AssetCellViewModel]> {
        let observer = scheduler.createObserver([AssetCellViewModel].self)
        SharingScheduler.mock(scheduler: scheduler) {
            sut.transform(AssetListViewModel.Input()).cells
                .drive(observer)
                .disposed(by: disposeBag)
        }
        scheduler.start()
        return observer
    }
}
