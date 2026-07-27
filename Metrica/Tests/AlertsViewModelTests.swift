import XCTest
@testable import Metrica

private struct StubAlertsSource: AlertsDataSource {
    func alerts(businessID: String, cursor: String?) async throws -> AlertsPage {
        try MockHub().alerts(businessID: businessID, cursor: cursor)
    }
}

@MainActor
final class AlertsViewModelTests: XCTestCase {
    func testPaginationAppendsPage2() async throws {
        let vm = AlertsViewModel(dataSource: StubAlertsSource())
        let state = AppState()
        await vm.reload(businessID: "biz-resto", appState: state)

        XCTAssertEqual(vm.items.count, 4)
        XCTAssertEqual(vm.nextCursor, "page2")
        XCTAssertEqual(state.unreadAlertCount, 2)

        await vm.loadMore()
        XCTAssertEqual(vm.items.count, 5)
        XCTAssertNil(vm.nextCursor)
        XCTAssertTrue(vm.items.contains(where: { $0.id == "a5" }))
    }

    func testOpenAlertNavigatesAndMarksRead() async throws {
        let vm = AlertsViewModel(dataSource: StubAlertsSource())
        let state = AppState()
        let profile = try MockHub().me()
        state.apply(profile: profile, preferredBusinessID: "biz-resto")
        await vm.reload(businessID: "biz-resto", appState: state)

        let unreadBefore = state.unreadAlertCount
        let alert = vm.items.first { $0.id == "a3" }!
        XCTAssertEqual(alert.isRead, false)

        vm.open(alert, appState: state)

        XCTAssertEqual(state.selectedTab, .analytics)
        XCTAssertEqual(state.pendingDashboardKey, "revenue")
        XCTAssertEqual(state.unreadAlertCount, unreadBefore - 1)
        XCTAssertEqual(vm.items.first { $0.id == "a3" }?.isRead, true)
    }
}
