import RxBlocking
import RxSwift
import XCTest
@testable import MarketWatch

final class MockAssetRepositoryTests: XCTestCase {

    func test_assets_paginatesBundledJSON() throws {
        let sut = makeSUT()

        let pages = try (1...5).map { page in
            try sut.assets(page: page, pageSize: 25).toBlocking().single()
        }

        XCTAssertEqual(pages.map(\.assets.count), [25, 25, 25, 25, 0])
        XCTAssertEqual(pages.map(\.hasMore), [true, true, true, false, false])
    }

    func test_search_matchesSymbolCaseInsensitive() throws {
        let assets = try makeSUT().searchAssets(query: "btc").toBlocking().single()

        XCTAssertEqual(assets.first?.id, "bitcoin")
    }

    func test_search_matchesNameIgnoringDiacritics() throws {
        let assets = try makeSUT().searchAssets(query: "ethéreum").toBlocking().single()

        XCTAssertTrue(assets.map(\.id).contains("ethereum"))
    }

    func test_search_returnsAtMost25Results() throws {
        let assets = try makeSUT().searchAssets(query: "a").toBlocking().single()

        XCTAssertEqual(assets.count, 25)
    }

    func test_asset_returnsBundledAssetWithSparkline() throws {
        let asset = try makeSUT().asset(id: "bitcoin").toBlocking().single()

        XCTAssertEqual(asset.id, "bitcoin")
        XCTAssertFalse(asset.sparkline7d.isEmpty)
    }

    func test_asset_failsWhenIdNotFound() {
        XCTAssertThrowsError(try makeSUT().asset(id: "unknown").toBlocking().single()) { error in
            XCTAssertEqual(error as? AppError, .unknown)
        }
    }

    func test_assets_withoutBundledJSON_failsWithDecoding() {
        let sut = MockAssetRepository(bundle: Bundle(for: Self.self))

        XCTAssertThrowsError(try sut.assets(page: 1, pageSize: 25).toBlocking().single()) { error in
            XCTAssertEqual(error as? AppError, .decoding)
        }
    }

    // MARK: - Helpers

    private func makeSUT() -> MockAssetRepository {
        MockAssetRepository(bundle: .main)
    }
}
