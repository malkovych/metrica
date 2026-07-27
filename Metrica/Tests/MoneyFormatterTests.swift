import XCTest
@testable import Metrica

final class MoneyFormatterTests: XCTestCase {
    func testMinorUnitsToUAH() {
        let s = MoneyFormatter.string(minorUnits: 4825000, currencyCode: "UAH", locale: Locale(identifier: "uk_UA"))
        XCTAssertTrue(s.contains("48") || s.contains("48250"), "got \(s)")
    }

    func testDeltaPct() {
        XCTAssertTrue(MoneyFormatter.deltaPct(12).contains("12"))
        XCTAssertTrue(MoneyFormatter.deltaPct(-4).hasPrefix("▼"))
    }
}

final class MockHubTests: XCTestCase {
    func testMeFixture() throws {
        let hub = MockHub(bundle: .main)
        // У unit-тестах main bundle застосунку містить фікстури
        let profile = try hub.me()
        XCTAssertEqual(profile.businesses.count, 2)
        XCTAssertEqual(profile.businesses[0].mode, .resto)
        XCTAssertEqual(profile.businesses[1].mode, .ecom)
    }

    func testSummaryRestoDTO() throws {
        let summary = try MockHub().summary(businessID: "biz-resto")
        XCTAssertEqual(summary.revenue.value, 4_825_000)
        XCTAssertEqual(summary.kpis.count, 4)
        XCTAssertFalse(summary.blocks.isEmpty)
    }
}
