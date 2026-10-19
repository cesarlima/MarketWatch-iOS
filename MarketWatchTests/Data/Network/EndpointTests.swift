import XCTest
@testable import MarketWatch

final class EndpointTests: XCTestCase {

    func test_marketPage_requestsPageWithoutSparkline() {
        let endpoint = Endpoint.marketPage(page: 2, perPage: 25)

        XCTAssertEqual(endpoint.path, "/coins/markets")
        XCTAssertEqual(endpoint.parameters, [
            "vs_currency": "usd",
            "order": "market_cap_desc",
            "sparkline": "false",
            "page": "2",
            "per_page": "25"
        ])
    }

    func test_markets_joinsIdsWithCommaWithoutSparkline() {
        let endpoint = Endpoint.markets(ids: ["bitcoin", "solana"])

        XCTAssertEqual(endpoint.path, "/coins/markets")
        XCTAssertEqual(endpoint.parameters, [
            "vs_currency": "usd",
            "order": "market_cap_desc",
            "sparkline": "false",
            "ids": "bitcoin,solana"
        ])
    }

    func test_assetDetail_requestsOneIdWithSparkline() {
        let endpoint = Endpoint.assetDetail(id: "bitcoin")

        XCTAssertEqual(endpoint.path, "/coins/markets")
        XCTAssertEqual(endpoint.parameters, [
            "vs_currency": "usd",
            "order": "market_cap_desc",
            "sparkline": "true",
            "ids": "bitcoin"
        ])
    }

    func test_search_sendsQuery() {
        let endpoint = Endpoint.search(query: "sol")

        XCTAssertEqual(endpoint.path, "/search")
        XCTAssertEqual(endpoint.parameters, ["query": "sol"])
    }
}
