import Foundation
import UIKit
import Combine

protocol TodayDataSource: Sendable {
    func summary(businessID: String) async throws -> Summary
}

struct HubTodayDataSource: TodayDataSource {
    func summary(businessID: String) async throws -> Summary {
        try await APIClient.shared.summary(businessID: businessID)
    }
}

@MainActor
final class TodayViewModel: ObservableObject {
    @Published var summary: Summary?
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var isOffline = false
    @Published var errorMessage: String?
    @Published var updatedLabel: String?
    @Published private(set) var loadedBusinessID: String?

    private let dataSource: TodayDataSource
    private let cache: PayloadCache
    private let network: NetworkMonitor
    private let haptic = UIImpactFeedbackGenerator(style: .light)

    init(
        dataSource: TodayDataSource = HubTodayDataSource(),
        cache: PayloadCache = .shared,
        network: NetworkMonitor = .shared
    ) {
        self.dataSource = dataSource
        self.cache = cache
        self.network = network
    }

    /// Перше завантаження / зміна бізнесу: кеш одразу, потім мережа.
    func load(businessID: String) async {
        if loadedBusinessID != businessID {
            summary = nil
            updatedLabel = nil
            errorMessage = nil
            isOffline = false
        }
        loadedBusinessID = businessID

        // 1) Кеш миттєво (< 200 мс)
        if let cached = try? cache.load(Summary.self, key: CacheKey.summary(businessID: businessID)) {
            summary = cached.value
            setUpdatedLabel(cached.value.updatedAt ?? cached.updatedAt)
        }

        let showSkeleton = summary == nil
        if showSkeleton { isLoading = true }
        defer { isLoading = false }

        // Офлайн без свіжої спроби — лишаємо кеш + банер
        if !network.isOnline {
            isOffline = true
            if summary == nil {
                errorMessage = String(localized: "offline_banner")
            }
            return
        }

        // 2) Мережа
        do {
            let fresh = try await dataSource.summary(businessID: businessID)
            summary = fresh
            isOffline = false
            errorMessage = nil
            setUpdatedLabel(fresh.updatedAt ?? .now)
            try? cache.save(fresh, key: CacheKey.summary(businessID: businessID))
        } catch {
            if summary != nil {
                // Є кеш: без «дірок»; банер якщо мережа впала під час запиту
                isOffline = !network.isOnline
                errorMessage = nil
            } else {
                isOffline = !network.isOnline
                errorMessage = error.localizedDescription
            }
        }
    }

    /// Pull-to-refresh + haptic.
    func refresh(businessID: String) async {
        isRefreshing = true
        defer { isRefreshing = false }
        haptic.prepare()
        await load(businessID: businessID)
        haptic.impactOccurred()
    }

    private func setUpdatedLabel(_ date: Date) {
        let time = date.formatted(date: .omitted, time: .shortened)
        updatedLabel = String(format: String(localized: "updated_at"), time)
    }
}
