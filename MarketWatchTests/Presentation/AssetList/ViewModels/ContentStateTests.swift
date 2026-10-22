import XCTest
@testable import MarketWatch

final class ContentStateTests: XCTestCase {
    func test_initialLoading_showsLoading() {
        let state = AssetListState(loading: .initial)

        XCTAssertEqual(ContentState(state), .loading)
    }

    func test_failureWithoutAssets_showsError() {
        let state = AssetListState(error: .offline)

        XCTAssertEqual(ContentState(state), .error(message: "Sem conexão com a internet."))
    }

    func test_failureWithAssets_keepsList() {
        let state = AssetListState(assets: [.fixture()], error: .offline)

        XCTAssertEqual(ContentState(state), .loaded)
    }

    func test_loadedAssets_showsList() {
        let state = AssetListState(assets: [.fixture()])

        XCTAssertEqual(ContentState(state), .loaded)
    }

    func test_loadingNextPage_keepsCurrentScreen() {
        let state = AssetListState(assets: [.fixture()], loading: .nextPage)

        XCTAssertNil(ContentState(state))
    }

    func test_refreshing_keepsCurrentScreen() {
        let state = AssetListState(loading: .refresh)

        XCTAssertNil(ContentState(state))
    }
}
