import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if let remote = launchOptions?[.remoteNotification] as? [AnyHashable: Any],
           let deep = remote["deepLink"] as? String ?? remote["deep_link"] as? String,
           let url = URL(string: deep) {
            DeepLinkPending.shared.url = url
        }
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            PushService.shared.didRegister(deviceToken: deviceToken)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Task { @MainActor in
            PushService.shared.didFailToRegister(error)
        }
    }
}

/// Cold-start deep-link з пуша до готовності AppState.
enum DeepLinkPending {
    static let shared = DeepLinkPendingBox()
}

final class DeepLinkPendingBox: @unchecked Sendable {
    var url: URL?
}
