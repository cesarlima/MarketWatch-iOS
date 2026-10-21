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

    func test_image_isReducedToMaxPixelSize() throws {
        StubURLProtocol.stub(data: makePNGData(pixels: 300))

        let image = try makeSUT(maxPixelSize: 96).image(for: url).toBlocking().single()

        XCTAssertEqual(image?.cgImage?.width, 96)
        XCTAssertEqual(image?.cgImage?.height, 96)
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

    private func makeSUT(maxPixelSize: Int = 96) -> ImageLoader {
        ImageLoader(session: Session(configuration: StubURLProtocol.makeConfiguration()),
                    maxPixelSize: maxPixelSize)
    }

    private func makePNGData(pixels: CGFloat = 1) -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let size = CGSize(width: pixels, height: pixels)

        return UIGraphicsImageRenderer(size: size, format: format).pngData { context in
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
