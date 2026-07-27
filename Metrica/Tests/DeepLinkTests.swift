import XCTest
@testable import Metrica

final class DeepLinkTests: XCTestCase {
    func testParseToday() {
        let url = URL(string: "metrica://business/biz-resto/today")!
        XCTAssertEqual(DeepLink.parse(url), .today(businessID: "biz-resto"))
    }

    func testParseDashboard() {
        let url = URL(string: "metrica://business/biz-ecom/dashboard/sales")!
        XCTAssertEqual(DeepLink.parse(url), .dashboard(businessID: "biz-ecom", key: "sales"))
    }

    func testParseAlertsAndReports() {
        XCTAssertEqual(
            DeepLink.parse(URL(string: "metrica://business/biz-resto/alerts")!),
            .alerts(businessID: "biz-resto")
        )
        XCTAssertEqual(
            DeepLink.parse(URL(string: "metrica://business/biz-resto/reports")!),
            .reports(businessID: "biz-resto")
        )
    }

    func testParseSourceCallback() {
        XCTAssertEqual(
            DeepLink.parse(URL(string: "metrica://sources/callback")!),
            .sourceCallback
        )
    }
}

@MainActor
final class DeepLinkRoutingTests: XCTestCase {
    func testOpenDashboardSetsTabAndPendingKey() throws {
        let state = AppState()
        let profile = try MockHub().me()
        state.apply(profile: profile, preferredBusinessID: "biz-resto")

        state.open(URL(string: "metrica://business/biz-ecom/dashboard/customers")!)

        XCTAssertEqual(state.selectedBusinessID, "biz-ecom")
        XCTAssertEqual(state.selectedTab, .analytics)
        XCTAssertEqual(state.pendingDashboardKey, "customers")
        XCTAssertEqual(state.mode, .ecom)
    }

    func testPushSimulateOpensAlerts() throws {
        let state = AppState()
        let profile = try MockHub().me()
        state.apply(profile: profile, preferredBusinessID: nil)
        PushService.shared.configure(appState: state)
        PushService.shared.simulateIncoming(deepLink: "metrica://business/biz-resto/alerts")
        XCTAssertEqual(state.selectedTab, .alerts)
        XCTAssertEqual(state.selectedBusinessID, "biz-resto")
    }
}
