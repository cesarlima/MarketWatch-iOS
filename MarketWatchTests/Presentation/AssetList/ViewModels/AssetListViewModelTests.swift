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
        XCTAssertEqual(cells.events, [.next(100, [bitcoin]), .completed(100)])
    }

    func test_initialLoad_emitsLoadingThenLoaded() {
        let (sut, repository) = makeSUT()
        repository.assetsResponse = response([.fixture()], at: 100)

        let contentState = record(sut).contentState

        XCTAssertEqual(contentState.events, [.next(0, .loading), .next(100, .loaded), .completed(100)])
    }

    func test_initialLoadFailure_showsErrorState() {
        let (sut, repository) = makeSUT()
        repository.assetsResponse = failure(.offline, at: 100)

        let contentState = record(sut).contentState

        XCTAssertEqual(contentState.events, [
            .next(0, .loading),
            .next(100, .error(message: "Sem conexão com a internet.")),
            .completed(100)
        ])
    }

    func test_selection_emitsAssetAtSelectedRow() {
        let (sut, repository) = makeSUT()
        let bitcoin = Asset.fixture(id: "bitcoin")
        let ethereum = Asset.fixture(id: "ethereum", name: "Ethereum")
        repository.assetsResponse = response([bitcoin, ethereum], at: 100)
        let selection = scheduler.createHotObservable([.next(200, 1)]).asObservable()

        let selectedAsset = record(sut, selection: selection).selectedAsset

        XCTAssertEqual(selectedAsset.events, [.next(200, ethereum)])
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

    private func failure(_ error: AppError, at time: TestTime) -> Single<[Asset]> {
        scheduler
            .createColdObservable([.error(time, error)])
            .asSingle()
    }

    /// Drivers must be built inside `SharingScheduler.mock` to deliver on the test scheduler.
    private func record(_ sut: AssetListViewModel,
                        selection: Observable<Int> = .never()) -> RecordedOutput {
        let recorded = RecordedOutput(cells: scheduler.createObserver([AssetCellViewModel].self),
                                      contentState: scheduler.createObserver(ContentState.self),
                                      selectedAsset: scheduler.createObserver(Asset.self))
        SharingScheduler.mock(scheduler: scheduler) {
            let output = sut.transform(AssetListViewModel.Input(selection: selection))
            output.cells
                .drive(recorded.cells)
                .disposed(by: disposeBag)
            output.contentState
                .drive(recorded.contentState)
                .disposed(by: disposeBag)
            output.selectedAsset
                .emit(to: recorded.selectedAsset)
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
}
