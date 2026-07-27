import Foundation
import Combine

protocol AlertsDataSource: Sendable {
    func alerts(businessID: String, cursor: String?) async throws -> AlertsPage
}

struct HubAlertsDataSource: AlertsDataSource {
    func alerts(businessID: String, cursor: String?) async throws -> AlertsPage {
        try await APIClient.shared.alerts(businessID: businessID, cursor: cursor)
    }
}

@MainActor
final class AlertsViewModel: ObservableObject {
    @Published var items: [AlertItem] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published private(set) var nextCursor: String?

    private let dataSource: AlertsDataSource
    private var businessID: String?

    init(dataSource: AlertsDataSource = HubAlertsDataSource()) {
        self.dataSource = dataSource
    }

    var canLoadMore: Bool { nextCursor != nil && !isLoadingMore }

    func reload(businessID: String, appState: AppState) async {
        self.businessID = businessID
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let page = try await dataSource.alerts(businessID: businessID, cursor: nil)
            items = page.items
            nextCursor = page.nextCursor
            appState.unreadAlertCount = page.unreadCount
                ?? page.items.filter { !($0.isRead ?? true) }.count
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMore() async {
        guard let businessID, let cursor = nextCursor, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let page = try await dataSource.alerts(businessID: businessID, cursor: cursor)
            let existing = Set(items.map(\.id))
            items.append(contentsOf: page.items.filter { !existing.contains($0.id) })
            nextCursor = page.nextCursor
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func open(_ alert: AlertItem, appState: AppState) {
        AnalyticsEvents.alertTap(id: alert.id)
        markRead(alert.id, appState: appState)
        if let raw = alert.deepLink, let url = URL(string: raw) {
            appState.open(url)
        } else {
            appState.selectedTab = .alerts
        }
    }

    private func markRead(_ id: String, appState: AppState) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        let old = items[idx]
        if old.isRead == true { return }
        items[idx] = AlertItem(
            id: old.id,
            icon: old.icon,
            title: old.title,
            body: old.body,
            severity: old.severity,
            deepLink: old.deepLink,
            createdAt: old.createdAt,
            isRead: true
        )
        appState.unreadAlertCount = max(0, appState.unreadAlertCount - 1)
    }
}

