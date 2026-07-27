import XCTest
@testable import Metrica

/// M10 / теми §7.4 — контраст AA.
final class ThemeContrastTests: XCTestCase {
    func testThemeATextOnCard() {
        XCTAssertTrue(ContrastRatio.meetsAA(fg: 0x17171C, bg: 0xFFFFFF))
        XCTAssertTrue(ContrastRatio.meetsAA(fg: 0x6E6C7A, bg: 0xFFFFFF))
    }

    func testThemeBSubOnCardReadable() {
        // Після фіксу sub #9BA0B5 на card #16181F
        let ratio = ContrastRatio.ratio(fg: 0x9BA0B5, bg: 0x16181F)
        XCTAssertGreaterThanOrEqual(ratio, 4.5, "Theme B sub/card ratio \(ratio)")
        XCTAssertTrue(ContrastRatio.meetsAA(fg: 0xF2F3F7, bg: 0x16181F))
        XCTAssertTrue(ContrastRatio.meetsDeltaAA(fg: 0x3DFFA2, bg: 0x16181F))
    }

    func testThemeCAndD() {
        XCTAssertTrue(ContrastRatio.meetsAA(fg: 0x1A2B33, bg: 0xFFFFFF))
        XCTAssertTrue(ContrastRatio.meetsAA(fg: 0x5A6B73, bg: 0xFFFFFF))
        XCTAssertTrue(ContrastRatio.meetsAA(fg: 0x1B1D29, bg: 0xFFFFFF))
        XCTAssertTrue(ContrastRatio.meetsAA(fg: 0x63687A, bg: 0xFFFFFF))
    }

    func testNoHexLeakOutsideThemeFile() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let skip = Set(["Theme.swift", "ContrastRatio.swift"])
        var leaks: [String] = []
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: root, includingPropertiesForKeys: nil) else {
            return
        }
        while let url = enumerator.nextObject() as? URL {
            guard url.pathExtension == "swift" else { continue }
            let name = url.lastPathComponent
            guard !skip.contains(name), !url.path.contains("/Tests/") else { continue }
            let text = try String(contentsOf: url, encoding: .utf8)
            if text.contains("Color(hex:") {
                leaks.append(url.path.replacingOccurrences(of: root.path + "/", with: ""))
            }
        }
        XCTAssertTrue(leaks.isEmpty, "Hex leaks:\n\(leaks.joined(separator: "\n"))")
    }
}
