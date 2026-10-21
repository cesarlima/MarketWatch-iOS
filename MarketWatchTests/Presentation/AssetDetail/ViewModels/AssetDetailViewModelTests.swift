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
        let asset = Asset.fixture()
        let sut = AssetDetailViewModel(asset: asset,
                                       formatter: makeFormatter())

        let header = record(sut)

        XCTAssertEqual(header.events.first?.time, 0)
        XCTAssertEqual(header.events.first?.value.element?.name, "Bitcoin")
    }

    // MARK: - Helpers

    private func makeFormatter() -> AssetFormatter {
        AssetFormatter(locale: Locale(identifier: "pt_BR"))
    }

    /// Drivers must be built inside `SharingScheduler.mock` to deliver on the test scheduler.
    private func record(_ sut: AssetDetailViewModel) -> TestableObserver<AssetDetailHeader> {
        let header = scheduler.createObserver(AssetDetailHeader.self)
        SharingScheduler.mock(scheduler: scheduler) {
            sut.transform(AssetDetailViewModel.Input()).header
                .drive(header)
                .disposed(by: disposeBag)
        }
        scheduler.start()
        return header
    }
}
