import Alamofire
import UIKit

final class AppComposer {
    private let repository: AssetRepository
    private let formatter = AssetFormatter(locale: .current)
    private let imageLoader = ImageLoader(session: .default,
                                          maxPixelSize: 96)

    init(arguments: [String]) {
        repository = Self.makeRepository(arguments: arguments)
    }

    func makeAssetList(onAssetSelected: @escaping (Asset) -> Void) -> UIViewController {
        let viewModel = AssetListViewModel(repository: repository,
                                           formatter: formatter)
        let viewController = AssetListViewController(viewModel: viewModel,
                                                     imageLoader: imageLoader)
        viewController.onAssetSelected = onAssetSelected
        return viewController
    }

    func makeAssetDetail(asset: Asset) -> UIViewController {
        AssetDetailViewController()
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
