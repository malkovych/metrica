import Foundation
import Network
import Combine

/// Статус мережі для офлайн-баннера на «Сьогодні».
@MainActor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published private(set) var isOnline = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.metrica.network")

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isOnline = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    /// Для unit-тестів.
    func setOnlineForTests(_ online: Bool) {
        isOnline = online
    }
}
