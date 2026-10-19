import RxSwift
@testable import MarketWatch

final class APIClientStub: APIClient {
    private(set) var requestedEndpoints: [Endpoint] = []
    private var responses: [ObjectIdentifier: Any] = [:]

    /// Responses are matched by type: `/search` decodes `SearchResponseDTO`, the market endpoints `[MarketCoinDTO]`.
    func stub<T>(_ response: T) {
        responses[ObjectIdentifier(T.self)] = response
    }

    func request<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) -> Single<T> {
        Single.deferred { [weak self] in
            self?.requestedEndpoints.append(endpoint)

            guard let response = self?.responses[ObjectIdentifier(T.self)] as? T else {
                return .error(StubError.missingResponse)
            }
            return .just(response)
        }
    }

    enum StubError: Error {
        case missingResponse
    }
}
