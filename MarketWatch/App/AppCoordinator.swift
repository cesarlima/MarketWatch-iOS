import UIKit

final class AppCoordinator {
    private let window: UIWindow
    private let navigationController = UINavigationController()

    init(window: UIWindow) {
        self.window = window
    }

    func start() {
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.viewControllers = [AssetListViewController()]

        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}
