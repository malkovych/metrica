import XCTest
import SwiftUI
import UIKit
@testable import Metrica

/// Snapshot 2 режими × 2 мови × світла тема (M2 DoD).
@MainActor
final class TodaySnapshotTests: XCTestCase {
    func testTodaySnapshotsRestoEcomUkEn() throws {
        let resto = try MockHub().summary(businessID: "biz-resto")
        let ecom = try MockHub().summary(businessID: "biz-ecom")

        let cases: [(String, Summary, BusinessMode, Locale)] = [
            ("today_resto_uk", resto, .resto, Locale(identifier: "uk_UA")),
            ("today_resto_en", resto, .resto, Locale(identifier: "en_US")),
            ("today_ecom_uk", ecom, .ecom, Locale(identifier: "uk_UA")),
            ("today_ecom_en", ecom, .ecom, Locale(identifier: "en_US")),
        ]

        for item in cases {
            let image = try renderSnapshot(
                name: item.0,
                summary: item.1,
                mode: item.2,
                locale: item.3
            )
            XCTAssertGreaterThan(image.size.width, 300, item.0)
            XCTAssertGreaterThan(image.size.height, 400, item.0)
            try assertOrRecord(image: image, name: item.0)
        }
    }

    private func renderSnapshot(
        name: String,
        summary: Summary,
        mode: BusinessMode,
        locale: Locale
    ) throws -> UIImage {
        let view = TodaySummaryContent(summary: summary, updatedLabel: "Updated 18:41")
            .environment(\.bizTheme, ThemeA())
            .environment(\.businessMode, mode)
            .environment(\.locale, locale)
            .padding(16)
            .frame(width: 390)
            .background(ThemeA().bg)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        guard let image = renderer.uiImage else {
            throw NSError(domain: "Snapshot", code: 1, userInfo: [NSLocalizedDescriptionKey: "no image \(name)"])
        }
        return image
    }

    private func assertOrRecord(image: UIImage, name: String) throws {
        let dir = snapshotDirectory()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("\(name).png")
        guard let data = image.pngData() else {
            XCTFail("No PNG for \(name)")
            return
        }

        if ProcessInfo.processInfo.environment["RECORD_SNAPSHOTS"] == "1" || !FileManager.default.fileExists(atPath: url.path) {
            try data.write(to: url)
            return
        }

        let existing = try Data(contentsOf: url)
        // Допускаємо невелику різницю розміру (антиаліасинг / шрифти симулятора)
        let delta = abs(existing.count - data.count)
        let tolerance = max(existing.count / 50, 8_000)
        XCTAssertLessThanOrEqual(delta, tolerance, "Snapshot drift \(name): \(delta) bytes")
    }

    private func snapshotDirectory() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Snapshots", isDirectory: true)
    }
}
