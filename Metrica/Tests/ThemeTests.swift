import XCTest
@testable import Metrica

final class ThemeTests: XCTestCase {
    func testAllThemesAvailable() {
        XCTAssertTrue(ThemeID.allCases.allSatisfy(\.isAvailable))
    }

    func testAccentPairsDifferForABD() {
        let a = ThemeA()
        XCTAssertNotEqual(a.accent(for: .resto), a.accent(for: .ecom))
        let b = ThemeB()
        XCTAssertNotEqual(b.accent(for: .resto), b.accent(for: .ecom))
        let d = ThemeD()
        XCTAssertNotEqual(d.accent(for: .resto), d.accent(for: .ecom))
    }

    func testThemeCSharedAccentAndOpsHero() {
        let c = ThemeC()
        XCTAssertEqual(c.accent(for: .resto), c.accent(for: .ecom))
        XCTAssertEqual(c.heroVariant, .opsGrid)
        XCTAssertTrue(c.showsModeBadge)
        XCTAssertEqual(c.kpiVariant, .ops)
    }

    func testThemeBDarkSchemeAndNeonHero() {
        let b = ThemeB()
        XCTAssertEqual(b.preferredColorScheme, .dark)
        XCTAssertEqual(b.heroVariant, .darkNeon)
        XCTAssertEqual(b.chartVariant, .accentLine)
        XCTAssertNotNil(b.cardBorder)
    }

    func testThemeDCommerceTiles() {
        let d = ThemeD()
        XCTAssertEqual(d.heroVariant, .darkSolid)
        XCTAssertEqual(d.kpiVariant, .commerce)
    }

    func testRegistryRoundTrip() {
        for id in ThemeID.allCases {
            XCTAssertEqual(ThemeRegistry.theme(for: id).id, id)
        }
    }
}
