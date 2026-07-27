import XCTest
@testable import Metrica

final class PluralFormatterTests: XCTestCase {
    func testOrdersEnglish() {
        let one = PluralFormatter.orders(1, locale: Locale(identifier: "en_US"))
        let many = PluralFormatter.orders(5, locale: Locale(identifier: "en_US"))
        XCTAssertTrue(one.contains("1"))
        XCTAssertTrue(many.contains("5"))
    }

    func testOrdersUkrainian() {
        let one = PluralFormatter.orders(1, locale: Locale(identifier: "uk_UA"))
        let many = PluralFormatter.orders(5, locale: Locale(identifier: "uk_UA"))
        XCTAssertTrue(one.contains("1"))
        XCTAssertTrue(many.contains("5"))
    }
}
