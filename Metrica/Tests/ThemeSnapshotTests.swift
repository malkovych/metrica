import XCTest
import SwiftUI
import UIKit
@testable import Metrica

/// Snapshot героя «Сьогодні» у 4 темах × resto.
@MainActor
final class ThemeSnapshotTests: XCTestCase {
    func testTodayHeroAcrossThemes() throws {
        let summary = try MockHub().summary(businessID: "biz-resto")
        let themes: [(String, any Theme)] = [
            ("theme_a_today", ThemeA()),
            ("theme_b_today", ThemeB()),
            ("theme_c_today", ThemeC()),
            ("theme_d_today", ThemeD()),
        ]

        for item in themes {
            let image = try render(name: item.0, summary: summary, theme: item.1)
            XCTAssertGreaterThan(image.size.width, 300, item.0)
            XCTAssertGreaterThan(image.size.height, 200, item.0)
            try assertOrRecord(image: image, name: item.0)
        }
    }

    private func render(name: String, summary: Summary, theme: any Theme) throws -> UIImage {
        let view = TodaySummaryContent(summary: summary, updatedLabel: "Updated 18:41", businessName: "Pizza Nova")
            .environment(\.bizTheme, theme)
            .environment(\.businessMode, .resto)
            .padding(16)
            .frame(width: 390)
            .background(theme.bg)

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
        let tolerance = max(existing.count / 40, 12_000)
        XCTAssertLessThanOrEqual(delta, tolerance, "Snapshot drift \(name): \(delta)")
    }
}
