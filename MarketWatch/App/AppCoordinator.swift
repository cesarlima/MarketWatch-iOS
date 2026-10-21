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
        navigationController.viewControllers = [composer.makeAssetList()]

        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}
