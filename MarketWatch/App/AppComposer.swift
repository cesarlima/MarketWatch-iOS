import Alamofire
import UIKit

final class AppComposer {
    private let repository: AssetRepository
    private let formatter = AssetFormatter(locale: .current)

    init(arguments: [String]) {
        repository = Self.makeRepository(arguments: arguments)
    }

    func makeAssetList() -> UIViewController {
        let viewModel = AssetListViewModel(repository: repository,
                                           formatter: formatter)
        return AssetListViewController(viewModel: viewModel)
    }
}

// MARK: - Repository

extension AppComposer {
    private static let mockDataFlag = "-useMockData"
    private static let coinGeckoBaseURL = "https://api.coingecko.com/api/v3"

    static func makeRepository(arguments: [String]) -> AssetRepository {
        guard arguments.contains(mockDataFlag) else {
            let httpClient = AlamofireAPIClient(baseURL: coinGeckoBaseURL,
                                                session: .default)
            return CoinGeckoAssetRepository(httpClient: httpClient)
        }
        return MockAssetRepository(bundle: .main)
    }
}
