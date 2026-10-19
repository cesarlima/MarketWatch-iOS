import RxBlocking
import RxSwift
import XCTest
@testable import MarketWatch

final class CoinGeckoAssetRepositoryTests: XCTestCase {

    func test_assets_requestsGivenPage() throws {
        let client = APIClientStub()
        client.stub([MarketCoinDTO.fixture(id: "bitcoin")])

        _ = try makeSUT(client: client).assets(page: 2, pageSize: 25).toBlocking().single()

        XCTAssertEqual(client.requestedEndpoints, [.marketPage(page: 2, perPage: 25)])
    }

    func test_assets_mapsDTOsAndDropsCoinsWithoutPrice() throws {
        let client = APIClientStub()
        client.stub([
            MarketCoinDTO.fixture(id: "bitcoin"),
            MarketCoinDTO.fixture(id: "no-price", currentPrice: nil),
            MarketCoinDTO.fixture(id: "solana")
        ])

        let assets = try makeSUT(client: client).assets(page: 1, pageSize: 25).toBlocking().single()

        XCTAssertEqual(assets.map(\.id), ["bitcoin", "solana"])
    }

    func test_search_requestsAtMost25Ids() throws {
        let client = APIClientStub()
        let ids = (1...30).map { "coin-\($0)" }
        client.stub(SearchResponseDTO(coins: ids.map(SearchCoinDTO.init(id:))))
        client.stub([MarketCoinDTO]())

        _ = try makeSUT(client: client).searchAssets(query: "coin").toBlocking().single()

        XCTAssertEqual(client.requestedEndpoints, [
            .search(query: "coin"),
            .markets(ids: Array(ids.prefix(25)))
        ])
    }

    func test_search_preservesSearchRelevanceOrder() throws {
        let client = APIClientStub()
        client.stub(SearchResponseDTO(coins: [SearchCoinDTO(id: "solana"), SearchCoinDTO(id: "bitcoin")]))
        client.stub([MarketCoinDTO.fixture(id: "bitcoin"), MarketCoinDTO.fixture(id: "solana")])

        let assets = try makeSUT(client: client).searchAssets(query: "s").toBlocking().single()

        XCTAssertEqual(assets.map(\.id), ["solana", "bitcoin"])
    }

    func test_search_withNoMatches_skipsMarketsCall() throws {
        let client = APIClientStub()
        client.stub(SearchResponseDTO(coins: []))

        let assets = try makeSUT(client: client).searchAssets(query: "zzz").toBlocking().single()

        XCTAssertEqual(assets, [])
        XCTAssertEqual(client.requestedEndpoints, [.search(query: "zzz")])
    }

    func test_asset_requestsDetailEndpoint() throws {
        let client = APIClientStub()
        client.stub([MarketCoinDTO.fixture(id: "bitcoin")])

        let asset = try makeSUT(client: client).asset(id: "bitcoin").toBlocking().single()

        XCTAssertEqual(asset.id, "bitcoin")
        XCTAssertEqual(client.requestedEndpoints, [.assetDetail(id: "bitcoin")])
    }

    func test_asset_failsWhenIdNotFound() {
        let client = APIClientStub()
        client.stub([MarketCoinDTO]())

        XCTAssertThrowsError(try makeSUT(client: client).asset(id: "unknown").toBlocking().single()) { error in
            XCTAssertEqual(error as? AppError, .unknown)
        }
    }

    // MARK: - Helpers

    private func makeSUT(client: APIClientStub) -> CoinGeckoAssetRepository {
        CoinGeckoAssetRepository(httpClient: client)
    }
}
