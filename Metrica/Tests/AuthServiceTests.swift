import XCTest
@testable import Metrica

@MainActor
final class AuthServiceTests: XCTestCase {
    override func setUp() async throws {
        KeychainStore.clearAuth()
    }

    override func tearDown() async throws {
        KeychainStore.clearAuth()
    }

    func testLoginSuccessStoresTokenAndLoadsBusinesses() async {
        let auth = AuthService()
        let ok = await auth.login(email: "owner@metrica.app", password: "password")
        XCTAssertTrue(ok)
        XCTAssertEqual(auth.phase, .authenticated)
        XCTAssertNotNil(KeychainStore.get(.accessToken))
        XCTAssertEqual(auth.profile?.businesses.count, 2)
        XCTAssertEqual(auth.profile?.role, .owner)
    }

    func testLoginEmptyFails() async {
        let auth = AuthService()
        let ok = await auth.login(email: "", password: "")
        XCTAssertFalse(ok)
        XCTAssertEqual(auth.phase, .unauthenticated)
        XCTAssertNil(KeychainStore.get(.accessToken))
    }

    func testLogoutClearsSession() async {
        let auth = AuthService()
        _ = await auth.login(email: "owner@metrica.app", password: "password")
        await auth.logout()
        XCTAssertEqual(auth.phase, .unauthenticated)
        XCTAssertNil(auth.profile)
        XCTAssertNil(KeychainStore.get(.accessToken))
    }

    func testApplyProfileSelectsPreferredBusiness() {
        let state = AppState()
        let profile = try! MockHub().me()
        state.apply(profile: profile, preferredBusinessID: "biz-ecom")
        XCTAssertEqual(state.selectedBusinessID, "biz-ecom")
        XCTAssertEqual(state.mode, .ecom)
        state.selectBusiness("biz-resto")
        XCTAssertEqual(state.mode, .resto)
    }
}
