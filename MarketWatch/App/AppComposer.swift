import Alamofire
import RxSwift
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
        let loader = AssetListLoader(repository: repository)
        let viewModel = AssetListViewModel(loader: loader,
                                           formatter: formatter)
        let viewController = AssetListViewController(viewModel: viewModel,
                                                     imageLoader: imageLoader)
        viewController.onAssetSelected = onAssetSelected
        viewController.navigationItem.searchController = makeAssetSearch(onAssetSelected: onAssetSelected)
        return viewController
    }

    func makeAssetSearch(onAssetSelected: @escaping (Asset) -> Void) -> UISearchController {
        let viewModel = AssetSearchViewModel(repository: repository,
                                             formatter: formatter,
                                             scheduler: MainScheduler.instance)
        let results = AssetSearchViewController(viewModel: viewModel,
                                                imageLoader: imageLoader)
        results.onAssetSelected = onAssetSelected
        let searchController = UISearchController(searchResultsController: results)
        searchController.searchBar.placeholder = L10n.Search.placeholder
        results.bind(to: searchController)
        return searchController
    }

    func makeAssetDetail(asset: Asset) -> UIViewController {
        let viewModel = AssetDetailViewModel(asset: asset,
                                             repository: repository,
                                             formatter: formatter)
        return AssetDetailViewController(viewModel: viewModel,
                                         imageLoader: imageLoader)
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
