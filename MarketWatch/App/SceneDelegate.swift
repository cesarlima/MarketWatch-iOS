import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var coordinator: AppCoordinator?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }
        let window = UIWindow(windowScene: windowScene)
        let composer = AppComposer(arguments: ProcessInfo.processInfo.arguments)
        let coordinator = AppCoordinator(window: window,
                                         composer: composer)
        coordinator.start()

        self.window = window
        self.coordinator = coordinator
    }
}
