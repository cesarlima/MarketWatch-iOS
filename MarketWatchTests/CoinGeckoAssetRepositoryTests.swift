import RxBlocking
import RxSwift
import XCTest
@testable import MarketWatch

final class CoinGeckoAssetRepositoryTests: XCTestCase {

    func test_assets_requestsGivenPage() throws {
        let (sut, client) = makeSUT()
        client.stubMarkets([.fixture(id: "bitcoin")])

        _ = try sut.assets(page: 2, pageSize: 25).toBlocking().single()

        XCTAssertEqual(client.requestedEndpoints, [.marketPage(page: 2, perPage: 25)])
    }

    func test_assets_mapsDTOsAndDropsCoinsWithoutPrice() throws {
        let (sut, client) = makeSUT()
        client.stubMarkets([
            .fixture(id: "bitcoin"),
            .fixture(id: "no-price", currentPrice: nil),
            .fixture(id: "solana")
        ])

        let assets = try sut.assets(page: 1, pageSize: 25).toBlocking().single()

        XCTAssertEqual(assets.map(\.id), ["bitcoin", "solana"])
    }

    func test_search_requestsAtMost25Ids() throws {
        let (sut, client) = makeSUT()
        let ids = (1...30).map { "coin-\($0)" }
        client.stubSearch(ids: ids)
        client.stubMarkets([])

        _ = try sut.searchAssets(query: "coin").toBlocking().single()

        XCTAssertEqual(client.requestedEndpoints, [
            .search(query: "coin"),
            .markets(ids: Array(ids.prefix(25)))
        ])
    }

    func test_search_preservesSearchRelevanceOrder() throws {
        let (sut, client) = makeSUT()
        client.stubSearch(ids: ["solana", "bitcoin"])
        client.stubMarkets([.fixture(id: "bitcoin"), .fixture(id: "solana")])

        let assets = try sut.searchAssets(query: "s").toBlocking().single()

        XCTAssertEqual(assets.map(\.id), ["solana", "bitcoin"])
    }

    func test_search_withNoMatches_skipsMarketsCall() throws {
        let (sut, client) = makeSUT()
        client.stubSearch(ids: [])

        let assets = try sut.searchAssets(query: "zzz").toBlocking().single()

        XCTAssertEqual(assets, [])
        XCTAssertEqual(client.requestedEndpoints, [.search(query: "zzz")])
    }

    func test_asset_requestsDetailEndpoint() throws {
        let (sut, client) = makeSUT()
        client.stubMarkets([.fixture(id: "bitcoin")])

        let asset = try sut.asset(id: "bitcoin").toBlocking().single()

        XCTAssertEqual(asset.id, "bitcoin")
        XCTAssertEqual(client.requestedEndpoints, [.assetDetail(id: "bitcoin")])
    }

    func test_asset_failsWhenIdNotFound() {
        let (sut, client) = makeSUT()
        client.stubMarkets([])

        XCTAssertThrowsError(try sut.asset(id: "unknown").toBlocking().single()) { error in
            XCTAssertEqual(error as? AppError, .unknown)
        }
    }

    // MARK: - Helpers

    private func makeSUT() -> (sut: CoinGeckoAssetRepository, client: APIClientStub) {
        let client = APIClientStub()
        return (CoinGeckoAssetRepository(httpClient: client), client)
    }
}

// MARK: - Stubbing

private extension APIClientStub {
    func stubSearch(ids: [String]) {
        stub(SearchResponseDTO(coins: ids.map(SearchCoinDTO.init(id:))))
    }

    func stubMarkets(_ coins: [MarketCoinDTO]) {
        stub(coins)
    }
}
