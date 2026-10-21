import UIKit

final class AppCoordinator {
    private let window: UIWindow
    private let composer: AppComposer
    private let navigationController = UINavigationController()

    init(window: UIWindow,
         composer: AppComposer) {
        self.window = window
        self.composer = composer
    }

    func start() {
        navigationController.navigationBar.prefersLargeTitles = true
        let assetList = composer.makeAssetList(onAssetSelected: { [weak self] asset in
            self?.showDetail(of: asset)
        })
        navigationController.viewControllers = [assetList]

        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}

// MARK: - Navigation

private extension AppCoordinator {
    func showDetail(of asset: Asset) {
        let assetDetail = composer.makeAssetDetail(asset: asset)
        navigationController.pushViewController(assetDetail, animated: true)
    }
}
