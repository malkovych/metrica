import XCTest
@testable import Metrica

/// M11: парсинг усіх фікстур §5.
final class FixtureDTOTests: XCTestCase {
    private let hub = MockHub()

    func testMe() throws {
        let me = try hub.me()
        XCTAssertFalse(me.businesses.isEmpty)
    }

    func testSummaries() throws {
        let resto = try hub.summary(businessID: "biz-resto")
        XCTAssertEqual(resto.kpis.count, 4)
        let ecom = try hub.summary(businessID: "biz-ecom")
        XCTAssertFalse(ecom.blocks.isEmpty)
    }

    func testMetricsFullDashboards() throws {
        _ = try hub.metrics(businessID: "biz-resto", dashboard: "revenue", period: "day")
        _ = try hub.metrics(businessID: "biz-resto", dashboard: "menu-abc", period: "week")
        _ = try hub.metrics(businessID: "biz-ecom", dashboard: "sales", period: "day")
        _ = try hub.metrics(businessID: "biz-ecom", dashboard: "customers", period: "month")
    }

    func testAlertsAndReports() throws {
        let page = try hub.alerts(businessID: "biz-resto", cursor: nil)
        XCTAssertFalse(page.items.isEmpty)
        let reports = try hub.reports(businessID: "biz-resto")
        XCTAssertFalse(reports.isEmpty)
        XCTAssertTrue(reports.contains { $0.type == .investor })
    }

    func testStubDashboardReturnsStubElement() throws {
        let dash = try hub.metrics(businessID: "biz-resto", dashboard: "foodcost", period: "day")
        XCTAssertEqual(dash.key, "foodcost")
        if case .stub = dash.elements.first {
            return
        }
        XCTFail("expected stub element")
    }
}
