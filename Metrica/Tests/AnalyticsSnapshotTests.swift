import XCTest
import SwiftUI
import UIKit
@testable import Metrica

/// Snapshot повних дашбордів M3: revenue, menu-abc, sales, customers.
@MainActor
final class AnalyticsSnapshotTests: XCTestCase {
    func testFullDashboardSnapshots() throws {
        let cases: [(String, String, String)] = [
            ("analytics_resto_revenue", "biz-resto", "revenue"),
            ("analytics_resto_menu_abc", "biz-resto", "menu-abc"),
            ("analytics_ecom_sales", "biz-ecom", "sales"),
            ("analytics_ecom_customers", "biz-ecom", "customers"),
        ]

        for item in cases {
            let metric = try MockHub().metrics(
                businessID: item.1,
                dashboard: item.2,
                period: "week"
            )
            let mode: BusinessMode = item.1 == "biz-ecom" ? .ecom : .resto
            let image = try render(name: item.0, metric: metric, mode: mode)
            XCTAssertGreaterThan(image.size.width, 300, item.0)
            XCTAssertGreaterThan(image.size.height, 200, item.0)
            try assertOrRecord(image: image, name: item.0)
        }
    }

    private func render(name: String, metric: MetricDashboard, mode: BusinessMode) throws -> UIImage {
        let view = AnalyticsDashboardContent(metric: metric)
            .environment(\.bizTheme, ThemeA())
            .environment(\.businessMode, mode)
            .padding(16)
            .frame(width: 390)
            .background(ThemeA().bg)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        guard let image = renderer.uiImage else {
            throw NSError(domain: "Snapshot", code: 1, userInfo: [NSLocalizedDescriptionKey: name])
        }
        return image
    }

    private func assertOrRecord(image: UIImage, name: String) throws {
        let dir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Snapshots", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("\(name).png")
        guard let data = image.pngData() else {
            XCTFail("No PNG \(name)")
            return
        }
        if !FileManager.default.fileExists(atPath: url.path)
            || ProcessInfo.processInfo.environment["RECORD_SNAPSHOTS"] == "1" {
            try data.write(to: url)
            return
        }
        let existing = try Data(contentsOf: url)
        let delta = abs(existing.count - data.count)
        let tolerance = max(existing.count / 50, 8_000)
        XCTAssertLessThanOrEqual(delta, tolerance, "Snapshot drift \(name): \(delta)")
    }
}
