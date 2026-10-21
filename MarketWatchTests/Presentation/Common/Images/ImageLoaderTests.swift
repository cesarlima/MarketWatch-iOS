import Alamofire
import RxBlocking
import RxSwift
import UIKit
import XCTest
@testable import MarketWatch

final class ImageLoaderTests: XCTestCase {
    private let url = URL(fileURLWithPath: "/icons/bitcoin.png")

    override func tearDown() {
        StubURLProtocol.reset()
        super.tearDown()
    }

    func test_image_secondCallForSameURL_comesFromCache() throws {
        StubURLProtocol.stub(data: makePNGData())
        var requestCount = 0
        StubURLProtocol.observeRequests { _ in requestCount += 1 }
        let sut = makeSUT()

        _ = try sut.image(for: url).toBlocking().single()
        let cachedImage = try sut.image(for: url).toBlocking().single()

        XCTAssertNotNil(cachedImage)
        XCTAssertEqual(requestCount, 1)
    }

    func test_image_failedDownload_returnsNil() throws {
        StubURLProtocol.stub(data: Data(), statusCode: 404)

        let image = try makeSUT().image(for: url).toBlocking().single()

        XCTAssertNil(image)
    }

    func test_dispose_cancelsDownload() {
        StubURLProtocol.holdResponses()
        let started = expectation(description: "download started")
        let stopped = expectation(description: "download stopped")
        StubURLProtocol.observeRequests { _ in started.fulfill() }
        StubURLProtocol.observeStopLoading { stopped.fulfill() }

        // Keeps the loader (and its Session) alive: releasing the Session would cancel the task by itself.
        let sut = makeSUT()
        let subscription = sut.image(for: url).subscribe()
        wait(for: [started], timeout: 2)

        subscription.dispose()

        wait(for: [stopped], timeout: 2)
        withExtendedLifetime(sut) {}
    }

    // MARK: - Helpers

    private func makeSUT() -> ImageLoader {
        ImageLoader(session: Session(configuration: StubURLProtocol.makeConfiguration()))
    }

    private func makePNGData() -> Data {
        UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).pngData { context in
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }
}
