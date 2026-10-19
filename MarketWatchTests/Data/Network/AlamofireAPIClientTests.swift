import Alamofire
import RxBlocking
import RxSwift
import XCTest
@testable import MarketWatch

final class AlamofireAPIClientTests: XCTestCase {

    override func tearDown() {
        StubURLProtocol.reset()
        super.tearDown()
    }

    func test_request_combinesBaseURLPathAndParameters() throws {
        StubURLProtocol.stub(data: Data(#"{"coins":[]}"#.utf8))
        var capturedURL: URL?
        StubURLProtocol.observeRequests { capturedURL = $0.url }

        _ = try makeSUT().request(.search(query: "sol"), as: SearchResponseDTO.self).toBlocking().single()

        XCTAssertEqual(capturedURL?.absoluteString, "https://api.example.com/api/v3/search?query=sol")
    }

    func test_request_decodesSuccessResponse() throws {
        StubURLProtocol.stub(data: try FixtureLoader.data(named: "markets-sample"))

        let dtos = try makeSUT().request(.marketPage(page: 1, perPage: 25), as: [MarketCoinDTO].self).toBlocking().single()

        XCTAssertEqual(dtos.count, 3)
        XCTAssertEqual(dtos.first?.id, "bitcoin")
    }

    func test_request_maps429ToRateLimited() {
        StubURLProtocol.stub(data: Data(), statusCode: 429)

        XCTAssertEqual(requestError(), .rateLimited)
    }

    func test_request_mapsOtherStatusToServer() {
        StubURLProtocol.stub(data: Data(), statusCode: 503)

        XCTAssertEqual(requestError(), .server(statusCode: 503))
    }

    func test_request_mapsInvalidJSONToDecoding() {
        StubURLProtocol.stub(data: Data("not json".utf8))

        XCTAssertEqual(requestError(), .decoding)
    }

    func test_request_mapsOfflineToOffline() {
        StubURLProtocol.stub(error: URLError(.notConnectedToInternet))

        XCTAssertEqual(requestError(), .offline)
    }

    func test_dispose_cancelsUnderlyingRequest() {
        StubURLProtocol.holdResponses()
        let started = expectation(description: "request started")
        let stopped = expectation(description: "request stopped")
        StubURLProtocol.observeRequests { _ in started.fulfill() }
        StubURLProtocol.observeStopLoading { stopped.fulfill() }

        // Keeps the client (and its Session) alive: releasing the Session would cancel the task by itself
        // and the test would pass even without an explicit cancel.
        let sut = makeSUT()
        let subscription = sut
            .request(.marketPage(page: 1, perPage: 25), as: [MarketCoinDTO].self)
            .subscribe()
        wait(for: [started], timeout: 2)

        subscription.dispose()

        wait(for: [stopped], timeout: 2)
        withExtendedLifetime(sut) {}
    }

    // MARK: - Helpers

    private func makeSUT() -> AlamofireAPIClient {
        AlamofireAPIClient(
            baseURL: "https://api.example.com/api/v3",
            session: Session(configuration: StubURLProtocol.makeConfiguration())
        )
    }

    private func requestError(file: StaticString = #filePath, line: UInt = #line) -> AppError? {
        do {
            _ = try makeSUT()
                .request(.marketPage(page: 1, perPage: 25), as: [MarketCoinDTO].self)
                .toBlocking()
                .single()
            
            XCTFail("Expected an error", file: file, line: line)
            
            return nil
        } catch {
            return error as? AppError
        }
    }
}
