import XCTest
@testable import Metrica

final class TLSPinningConfigTests: XCTestCase {
    func testPinnedHostsIncludeHub() {
        XCTAssertTrue(AppConfig.pinnedHosts.contains("api.hub.example"))
    }

    func testPinningOffByDefaultInDebug() {
        // Без ENABLE_TLS_PINNING у середовищі тестів
        XCTAssertFalse(AppConfig.enableTLSPinning)
    }
}
