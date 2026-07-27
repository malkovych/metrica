import XCTest
@testable import Metrica

final class AnalyticsEventsTests: XCTestCase {
    override func setUp() {
        InMemoryAnalyticsSink.shared.reset()
    }

    func testTracksRequiredEvents() {
        AnalyticsEvents.screenView("today")
        AnalyticsEvents.dashboardOpen(key: "revenue")
        AnalyticsEvents.alertTap(id: "a1")
        AnalyticsEvents.reportShare(id: "r1")
        AnalyticsEvents.languageChange(.en)

        let names = InMemoryAnalyticsSink.shared.events.map(\.name)
        XCTAssertEqual(names, [
            "screen_view", "dashboard_open", "alert_tap", "report_share", "language_change",
        ])
    }
}
