import Foundation
import RxCocoa
import RxSwift

/// Counts the sequences it is tracking and drives `true` while at least one of them is running.
///
/// A sequence counts from subscription until it completes, fails or is disposed, so overlapping
/// loads keep the indicator on until the last one ends.
final class ActivityTracker: SharedSequenceConvertibleType {
    typealias Element = Bool
    typealias SharingStrategy = DriverSharingStrategy

    private let lock = NSRecursiveLock()
    private let runningCount = BehaviorRelay(value: 0)
    private let isActive: Driver<Bool>

    init() {
        isActive = runningCount
            .asDriver()
            .map { $0 > 0 }
            .distinctUntilChanged()
    }

    /// Keeps the tracker alive while the sequence runs, so the count always comes back down.
    func trackActivity<Source: ObservableConvertibleType>(_ source: Source) -> Observable<Source.Element> {
        source
            .asObservable()
            .do(onSubscribe: {
                self.changeCount(by: 1)
            }, onDispose: {
                self.changeCount(by: -1)
            })
    }

    func asSharedSequence() -> Driver<Bool> {
        isActive
    }
}

// MARK: - Counting

private extension ActivityTracker {
    func changeCount(by delta: Int) {
        lock.lock()
        runningCount.accept(runningCount.value + delta)
        lock.unlock()
    }
}
