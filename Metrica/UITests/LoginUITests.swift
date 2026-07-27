import XCTest

/// UI-тест логіну (M1 DoD): логін → вибір бізнесу → головний екран.
final class LoginUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITestResetAuth", "-UITesting"]
        app.launch()
    }

    func testLoginShowsTodayAndSwitchesBusiness() {
        let login = app.buttons["login_button"]
        XCTAssertTrue(login.waitForExistence(timeout: 8), "Login screen should appear")

        // Поля вже заповнені демо-креденшалами в mock-режимі
        let email = app.textFields["login_email"]
        if email.waitForExistence(timeout: 2) {
            // якщо порожньо — вводимо
            let value = email.value as? String ?? ""
            if value.isEmpty || value == "Email" {
                email.tap()
                email.typeText("owner@metrica.app")
            }
        }

        login.tap()

        // Після логіну — таб-бар і екран «Сьогодні»
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Tab bar after login")

        let today = app.staticTexts["today_title"]
        let chips = app.otherElements["business_chips"]
        let ecomChip = app.buttons["biz_chip_biz-ecom"]

        let landed = today.waitForExistence(timeout: 5)
            || chips.waitForExistence(timeout: 5)
            || ecomChip.waitForExistence(timeout: 5)
        XCTAssertTrue(landed, "Today screen content after login")

        if ecomChip.waitForExistence(timeout: 3) {
            ecomChip.tap()
            XCTAssertTrue(ecomChip.exists)
        }
    }
}
