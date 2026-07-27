import Foundation
import UIKit
import UserNotifications
import Combine

/// APNs: дозвіл → токен → POST /devices. Тап по пушу → deep-link.
@MainActor
final class PushService: NSObject, ObservableObject {
    static let shared = PushService()

    @Published private(set) var isAuthorized = false
    @Published private(set) var deviceTokenHex: String?

    weak var appState: AppState?

    func configure(appState: AppState) {
        self.appState = appState
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorizationAndRegister() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            guard granted else { return }
            UIApplication.shared.registerForRemoteNotifications()
        } catch {
            AppLog.error("push_auth_failed", ["code": String((error as NSError).code)])
        }
    }

    func didRegister(deviceToken: Data) {
        let hex = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        deviceTokenHex = hex
        Task {
            try? await APIClient.shared.registerDevice(apnsToken: hex)
        }
    }

    func didFailToRegister(_ error: Error) {
        AppLog.error("push_register_failed", ["code": String((error as NSError).code)])
        // Mock/simulator: фіктивний токен для контракту
        if AppConfig.useMocks {
            deviceTokenHex = "mock-apns-token"
            Task { try? await APIClient.shared.registerDevice(apnsToken: "mock-apns-token") }
        }
    }

    /// Симуляція пуша для UI/unit-тестів.
    func simulateIncoming(deepLink: String) {
        guard let url = URL(string: deepLink), let link = DeepLink.parse(url) else { return }
        appState?.open(link)
    }
}

extension PushService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let info = response.notification.request.content.userInfo
        let deep = (info["deepLink"] as? String)
            ?? (info["deep_link"] as? String)
        await MainActor.run {
            if let deep, let url = URL(string: deep), let link = DeepLink.parse(url) {
                appState?.open(link)
            }
        }
    }
}
