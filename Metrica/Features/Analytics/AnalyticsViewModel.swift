import Foundation
import Combine

protocol MetricsDataSource: Sendable {
    func metrics(businessID: String, dashboard: String, period: String) async throws -> MetricDashboard
}

struct HubMetricsDataSource: MetricsDataSource {
    func metrics(businessID: String, dashboard: String, period: String) async throws -> MetricDashboard {
        try await APIClient.shared.metrics(
            businessID: businessID,
            dashboard: dashboard,
            period: period
        )
    }
}

enum AnalyticsPeriod: String, CaseIterable, Identifiable {
    case day, week, month

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        }
    }
}

struct AnalyticsDashboardDef: Identifiable, Hashable {
    var id: String { key }
    let key: String
    let titleKey: String
    /// Повний MVP-дашборд (не stub).
    let isFullMVP: Bool
}

enum AnalyticsCatalog {
    static func dashboards(for mode: BusinessMode) -> [AnalyticsDashboardDef] {
        switch mode {
        case .resto:
            return [
                .init(key: "revenue", titleKey: "dash_revenue", isFullMVP: true),
                .init(key: "menu-abc", titleKey: "dash_menu_abc", isFullMVP: true),
                .init(key: "foodcost", titleKey: "dash_foodcost", isFullMVP: false),
                .init(key: "staff", titleKey: "dash_staff", isFullMVP: false),
                .init(key: "control", titleKey: "dash_control", isFullMVP: false),
                .init(key: "locations", titleKey: "dash_locations", isFullMVP: false),
            ]
        case .ecom:
            return [
                .init(key: "sales", titleKey: "dash_sales", isFullMVP: true),
                .init(key: "products", titleKey: "dash_products", isFullMVP: false),
                .init(key: "customers", titleKey: "dash_customers", isFullMVP: true),
                .init(key: "orders", titleKey: "dash_orders", isFullMVP: false),
                .init(key: "channels", titleKey: "dash_channels", isFullMVP: false),
            ]
        }
    }

    static func defaultDashboard(for mode: BusinessMode) -> String {
        mode == .resto ? "revenue" : "sales"
    }

    /// Тексти заглушок як у прототипі.
    static func stubBodyKey(dashboard: String) -> String {
        switch dashboard {
        case "foodcost": return "stub_foodcost"
        case "staff": return "stub_staff"
        case "control": return "stub_control"
        case "locations": return "stub_locations"
        case "products": return "stub_products"
        case "orders": return "stub_orders"
        case "channels": return "stub_channels"
        default: return "stub_body"
        }
    }
}

@MainActor
final class AnalyticsViewModel: ObservableObject {
    static let cacheTTL: TimeInterval = 5 * 60

    @Published var period: AnalyticsPeriod = .week
    @Published var selectedDashboard: String = "revenue"
    @Published var metric: MetricDashboard?
    @Published var isStub = false
    @Published var stubBodyKey: String = "stub_body"
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastRequestKey: String?

    private let dataSource: MetricsDataSource
    private let cache: PayloadCache
    private var selectedByMode: [BusinessMode: String] = [:]
    private var currentMode: BusinessMode = .resto

    init(
        dataSource: MetricsDataSource = HubMetricsDataSource(),
        cache: PayloadCache = .shared
    ) {
        self.dataSource = dataSource
        self.cache = cache
    }

    var dashboards: [AnalyticsDashboardDef] {
        AnalyticsCatalog.dashboards(for: currentMode)
    }

    func bind(mode: BusinessMode) {
        guard mode != currentMode else { return }
        currentMode = mode
        selectedDashboard = selectedByMode[mode] ?? AnalyticsCatalog.defaultDashboard(for: mode)
    }

    func selectDashboard(_ key: String) {
        selectedDashboard = key
        selectedByMode[currentMode] = key
        AnalyticsEvents.dashboardOpen(key: key)
    }

    /// Один запит на зміну period/chip/business; кеш 5 хв.
    func load(businessID: String?) async {
        guard let businessID else { return }
        let requestKey = "\(businessID)|\(selectedDashboard)|\(period.rawValue)"
        lastRequestKey = requestKey

        let cacheKey = CacheKey.metrics(
            businessID: businessID,
            dashboard: selectedDashboard,
            period: period.rawValue
        )

        if let cached = try? cache.load(MetricDashboard.self, key: cacheKey),
           Date.now.timeIntervalSince(cached.updatedAt) < Self.cacheTTL {
            apply(dashboard: cached.value, dashboardKey: selectedDashboard)
            return
        }

        isLoading = metric == nil
        errorMessage = nil
        defer { isLoading = false }

        do {
            let fresh = try await dataSource.metrics(
                businessID: businessID,
                dashboard: selectedDashboard,
                period: period.rawValue
            )
            // Якщо за час await користувач уже змінив фільтр — ігноруємо застарілу відповідь
            guard lastRequestKey == requestKey else { return }
            apply(dashboard: fresh, dashboardKey: selectedDashboard)
            try? cache.save(fresh, key: cacheKey)
        } catch APIError.notImplemented {
            guard lastRequestKey == requestKey else { return }
            metric = nil
            isStub = true
            stubBodyKey = AnalyticsCatalog.stubBodyKey(dashboard: selectedDashboard)
        } catch {
            guard lastRequestKey == requestKey else { return }
            if metric == nil {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func apply(dashboard: MetricDashboard, dashboardKey: String) {
        if case .stub = dashboard.elements.first {
            metric = nil
            isStub = true
            stubBodyKey = AnalyticsCatalog.stubBodyKey(dashboard: dashboardKey)
            return
        }
        metric = dashboard
        isStub = false
        errorMessage = nil
    }
}

