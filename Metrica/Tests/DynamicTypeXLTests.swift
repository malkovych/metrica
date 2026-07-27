import XCTest
import SwiftUI
import UIKit
@testable import Metrica

/// M11: ключові екрани рендеряться при Dynamic Type XL без крашу.
@MainActor
final class DynamicTypeXLTests: XCTestCase {
    func testTodayAtAccessibilityXL() throws {
        let summary = try MockHub().summary(businessID: "biz-resto")
        let view = TodaySummaryContent(summary: summary, updatedLabel: "Updated", businessName: "Pizza")
            .environment(\.bizTheme, ThemeA())
            .environment(\.businessMode, .resto)
            .environment(\.sizeCategory, .accessibilityExtraLarge)
            .frame(width: 390)
            .padding(16)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        XCTAssertNotNil(renderer.uiImage)
        XCTAssertGreaterThan(renderer.uiImage?.size.height ?? 0, 200)
    }

    func testKPICardAtXL() {
        let kpi = KPI(
            key: "receipts",
            title: "Receipts",
            value: "312",
            unitKey: nil,
            deltaPct: 12,
            delta: nil,
            trend: .up
        )
        let view = KPICard(kpi: kpi)
            .environment(\.bizTheme, ThemeB())
            .environment(\.sizeCategory, .accessibilityExtraLarge)
            .frame(width: 180)

        let renderer = ImageRenderer(content: view)
        XCTAssertNotNil(renderer.uiImage)
    }
}
