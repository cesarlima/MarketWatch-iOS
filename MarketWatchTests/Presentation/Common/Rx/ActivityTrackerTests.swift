import RxCocoa
import RxSwift
import RxTest
import XCTest
@testable import MarketWatch

final class ActivityTrackerTests: XCTestCase {
    private var scheduler: TestScheduler!
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        scheduler = TestScheduler(initialClock: 0,
                                  resolution: 0.001,
                                  simulateProcessingDelay: false)
        disposeBag = DisposeBag()
    }

    func test_isTrueWhileSequenceRuns() {
        let activity = recordActivity { tracker in
            self.track(self.sequence(endingAt: 100), with: tracker)
        }

        XCTAssertEqual(activity.events, [.next(0, false), .next(0, true), .next(100, false)])
    }

    func test_staysTrueWithOverlappingSequences() {
        let activity = recordActivity { tracker in
            self.track(self.sequence(endingAt: 100), with: tracker)
            self.scheduler.scheduleAt(50) {
                self.track(self.sequence(endingAt: 150), with: tracker)
            }
        }

        XCTAssertEqual(activity.events, [.next(0, false), .next(0, true), .next(200, false)])
    }

    func test_returnsFalseWhenSequenceErrors() {
        let failing: Observable<Int> = scheduler.createColdObservable([.error(100, AppError.offline)]).asObservable()

        let activity = recordActivity { tracker in
            self.track(failing, with: tracker)
        }

        XCTAssertEqual(activity.events, [.next(0, false), .next(0, true), .next(100, false)])
    }

    // MARK: - Helpers

    private func sequence(endingAt time: TestTime) -> Observable<Int> {
        scheduler.createColdObservable([.completed(time)]).asObservable()
    }

    private func track(_ source: Observable<Int>, with tracker: ActivityTracker) {
        tracker.trackActivity(source)
            .subscribe()
            .disposed(by: disposeBag)
    }

    /// The tracker's Driver must be built inside `SharingScheduler.mock` to deliver on the test scheduler.
    private func recordActivity(_ work: @escaping (ActivityTracker) -> Void) -> TestableObserver<Bool> {
        let activity = scheduler.createObserver(Bool.self)
        SharingScheduler.mock(scheduler: scheduler) {
            let tracker = ActivityTracker()
            tracker.asDriver()
                .drive(activity)
                .disposed(by: disposeBag)
            work(tracker)
        }
        scheduler.start()
        return activity
    }
}
