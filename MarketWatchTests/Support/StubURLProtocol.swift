import Foundation

final class StubURLProtocol: URLProtocol {

    private struct Stub {
        let data: Data?
        let statusCode: Int
        let error: Error?
    }

    private static var stub: Stub?
    private static var holdsResponses = false
    private static var onStartLoading: ((URLRequest) -> Void)?
    private static var onStopLoading: (() -> Void)?

    static func stub(data: Data? = nil, statusCode: Int = 200, error: Error? = nil) {
        stub = Stub(data: data, statusCode: statusCode, error: error)
    }

    static func holdResponses() {
        holdsResponses = true
    }

    static func observeRequests(_ observer: @escaping (URLRequest) -> Void) {
        onStartLoading = observer
    }

    static func observeStopLoading(_ observer: @escaping () -> Void) {
        onStopLoading = observer
    }

    static func reset() {
        stub = nil
        holdsResponses = false
        onStartLoading = nil
        onStopLoading = nil
    }

    static func makeConfiguration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return configuration
    }

    // MARK: - URLProtocol

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.onStartLoading?(request)
        guard !Self.holdsResponses, let stub = Self.stub else { return }

        if let error = stub.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        let response = HTTPURLResponse(url: request.url!,
                                       statusCode: stub.statusCode,
                                       httpVersion: nil, headerFields: nil)!
        
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        
        if let data = stub.data {
            client?.urlProtocol(self, didLoad: data)
        }
        
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
        Self.onStopLoading?()
    }
}
