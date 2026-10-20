import XCTest
@testable import MarketWatch

final class AppComposerTests: XCTestCase {

    func test_makeRepository_withMockFlag_usesBundledRepository() {
        let repository = AppComposer.makeRepository(arguments: ["MarketWatch", "-useMockData"])

        XCTAssertTrue(repository is MockAssetRepository)
    }

    func test_makeRepository_withoutMockFlag_usesCoinGeckoRepository() {
        let repository = AppComposer.makeRepository(arguments: ["MarketWatch"])

        XCTAssertTrue(repository is CoinGeckoAssetRepository)
    }
}
