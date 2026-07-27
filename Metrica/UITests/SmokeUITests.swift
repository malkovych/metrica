import XCTest

/// M7 §11: логін → бізнес → 5 табів → перемикання мови.
final class SmokeUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITestResetAuth", "-UITesting"]
        app.launch()
    }

    func testFiveTabsAndLanguageSwitch() {
        let login = app.buttons["login_button"]
        XCTAssertTrue(login.waitForExistence(timeout: 8))
        login.tap()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 12))

        let tabs = tabBar.buttons
        XCTAssertGreaterThanOrEqual(tabs.count, 5, "Expected 5 tabs")

        // 0 Today
        tabs.element(boundBy: 0).tap()
        let todayOK = app.staticTexts["today_title"].waitForExistence(timeout: 5)
            || app.otherElements["business_chips"].waitForExistence(timeout: 3)
            || app.otherElements["today_ops_header"].waitForExistence(timeout: 2)
        XCTAssertTrue(todayOK, "Today")

        // 1 Analytics
        tabs.element(boundBy: 1).tap()
        XCTAssertTrue(app.staticTexts["analytics_title"].waitForExistence(timeout: 5))

        // 2 Reports
        tabs.element(boundBy: 2).tap()
        XCTAssertTrue(app.staticTexts["reports_title"].waitForExistence(timeout: 5))

        // 3 Alerts
        tabs.element(boundBy: 3).tap()
        XCTAssertTrue(app.staticTexts["alerts_title"].waitForExistence(timeout: 5))

        // 4 Settings + language
        tabs.element(boundBy: 4).tap()
        XCTAssertTrue(app.staticTexts["settings_title"].waitForExistence(timeout: 5))

        let en = app.buttons["lang_en"]
        let uk = app.buttons["lang_uk"]
        XCTAssertTrue(en.waitForExistence(timeout: 4))
        en.tap()
        XCTAssertTrue(uk.waitForExistence(timeout: 2))
        uk.tap()

        // Бізнес-чип (якщо видимий на Today після повернення)
        tabs.element(boundBy: 0).tap()
        let ecom = app.buttons["biz_chip_biz-ecom"]
        if ecom.waitForExistence(timeout: 3) {
            ecom.tap()
        }
    }
}
