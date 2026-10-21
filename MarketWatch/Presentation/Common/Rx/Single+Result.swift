import RxSwift

extension PrimitiveSequence where Trait == SingleTrait {
    /// Failures become values, so one error doesn't end the stream.
    func asResult() -> Single<Result<Element, AppError>> {
        map { .success($0) }
            .catch { error in
                .just(.failure(error as? AppError ?? .unknown))
            }
    }
}
