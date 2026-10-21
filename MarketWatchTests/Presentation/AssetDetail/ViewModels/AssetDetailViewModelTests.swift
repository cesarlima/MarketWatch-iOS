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

        let header = record(sut).header

        XCTAssertEqual(header.events.first?.time, 0)
        XCTAssertEqual(header.events.first?.value.element?.name, "Bitcoin")
    }

    func test_stats_showListDataRightAway() {
        let sut = AssetDetailViewModel(asset: .fixture(),
                                       formatter: makeFormatter())

        let stats = record(sut).stats

        XCTAssertEqual(stats.events.first?.time, 0)
        XCTAssertEqual(stats.events.first?.value.element?.count, 5)
    }

    // MARK: - Helpers

    private func makeFormatter() -> AssetFormatter {
        AssetFormatter(locale: Locale(identifier: "pt_BR"))
    }

    /// Drivers must be built inside `SharingScheduler.mock` to deliver on the test scheduler.
    private func record(_ sut: AssetDetailViewModel) -> RecordedOutput {
        let recorded = RecordedOutput(header: scheduler.createObserver(AssetDetailHeader.self),
                                      stats: scheduler.createObserver([AssetDetailStat].self))
        SharingScheduler.mock(scheduler: scheduler) {
            let output = sut.transform(AssetDetailViewModel.Input())
            output.header
                .drive(recorded.header)
                .disposed(by: disposeBag)
            output.stats
                .drive(recorded.stats)
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
}
