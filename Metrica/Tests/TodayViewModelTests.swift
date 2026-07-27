import XCTest
@testable import Metrica

private struct StubTodaySource: TodayDataSource {
    var result: Result<Summary, Error>

    func summary(businessID: String) async throws -> Summary {
        _ = businessID
        switch result {
        case .success(let s): return s
        case .failure(let e): throw e
        }
    }
}

@MainActor
final class TodayViewModelTests: XCTestCase {
    func testLoadShowsNetworkSummaryAndCaches() async throws {
        let summary = try MockHub().summary(businessID: "biz-resto")
        let cache = PayloadCache()
        let network = NetworkMonitor.shared
        network.setOnlineForTests(true)

        let vm = TodayViewModel(
            dataSource: StubTodaySource(result: .success(summary)),
            cache: cache,
            network: network
        )
        await vm.load(businessID: "biz-resto")

        XCTAssertEqual(vm.summary?.revenue.value, 4_825_000)
        XCTAssertFalse(vm.isOffline)
        XCTAssertNotNil(vm.updatedLabel)

        let cached = try cache.load(Summary.self, key: CacheKey.summary(businessID: "biz-resto"))
        XCTAssertEqual(cached?.value.revenue.value, 4_825_000)
    }

    func testOfflineUsesCacheAndBanner() async throws {
        let summary = try MockHub().summary(businessID: "biz-ecom")
        let cache = PayloadCache()
        try cache.save(summary, key: CacheKey.summary(businessID: "biz-ecom"))

        let network = NetworkMonitor.shared
        network.setOnlineForTests(false)

        let vm = TodayViewModel(
            dataSource: StubTodaySource(result: .failure(APIError.offline)),
            cache: cache,
            network: network
        )
        await vm.load(businessID: "biz-ecom")

        XCTAssertEqual(vm.summary?.revenue.value, 9_240_000)
        XCTAssertTrue(vm.isOffline)
        XCTAssertNil(vm.errorMessage)

        network.setOnlineForTests(true)
    }

    func testLoadFailureWithoutCacheShowsError() async {
        let cache = PayloadCache()
        let network = NetworkMonitor.shared
        network.setOnlineForTests(true)

        let vm = TodayViewModel(
            dataSource: StubTodaySource(result: .failure(APIError.http(status: 500, code: "x", message: "boom"))),
            cache: cache,
            network: network
        )
        await vm.load(businessID: "biz-resto")

        XCTAssertNil(vm.summary)
        XCTAssertNotNil(vm.errorMessage)
    }
}
