import XCTest
@testable import Metrica

final class AccessibilityCopyTests: XCTestCase {
    func testKPISpokenDeltaPlus() {
        let label = AccessibilityCopy.kpi(
            title: "Виручка",
            value: "48 250 ₴",
            deltaPct: 12,
            delta: nil,
            trend: .up
        )
        XCTAssertTrue(label.contains("Виручка"))
        XCTAssertTrue(label.contains("12") || label.localizedCaseInsensitiveContains("плюс"))
        XCTAssertFalse(label.contains("▲"))
    }

    func testKPISpokenDeltaMinus() {
        let spoken = AccessibilityCopy.spokenDeltaPct(-4)
        XCTAssertFalse(spoken.contains("▼"))
        XCTAssertTrue(spoken.contains("4") || spoken.localizedCaseInsensitiveContains("мінус") || spoken.localizedCaseInsensitiveContains("minus"))
    }

    func testAlertUnreadPrefix() {
        let label = AccessibilityCopy.alert(
            title: "Zero sales",
            body: "2h idle",
            severity: .critical,
            isUnread: true
        )
        XCTAssertTrue(label.contains("Zero sales"))
        XCTAssertTrue(label.contains("2h idle"))
    }
}
