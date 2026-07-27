import XCTest

/// e2e: логін → relaunch з deep-link (як тап по пушу) → Аналітика.
final class DeepLinkUITests: XCTestCase {
    func testPushDeepLinkOpensAnalyticsDashboard() {
        let app = XCUIApplication()

        // 1) Чистий логін (сесія в Keychain)
        app.launchArguments = ["-UITestResetAuth", "-UITesting"]
        app.launch()
        let login = app.buttons["login_button"]
        XCTAssertTrue(login.waitForExistence(timeout: 8), "Login screen")
        login.tap()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "Tabs after login")
        app.terminate()

        // 2) Cold start із deep-link
        app.launchArguments = [
            "-UITesting",
            "-UITestDeepLink",
            "metrica://business/biz-resto/dashboard/revenue",
        ]
        app.launch()

        // Якщо сесія не відновилась — залогінитись ще раз (deep-link уже в pending до auth)
        if app.buttons["login_button"].waitForExistence(timeout: 3) {
            app.buttons["login_button"].tap()
        }

        let title = app.staticTexts["analytics_title"]
        let chip = app.buttons["dash_chip_revenue"]
        let opened = title.waitForExistence(timeout: 12) || chip.waitForExistence(timeout: 12)
        XCTAssertTrue(opened, "Deep-link should open Analytics (tab/chip)")
    }
}
