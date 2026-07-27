import XCTest
@testable import Metrica

private final class CountingMetricsSource: MetricsDataSource, @unchecked Sendable {
    private let lock = NSLock()
    private(set) var calls = 0
    var result: Result<MetricDashboard, Error>

    init(result: Result<MetricDashboard, Error>) {
        self.result = result
    }

    func metrics(businessID: String, dashboard: String, period: String) async throws -> MetricDashboard {
        lock.lock(); calls += 1; lock.unlock()
        _ = businessID; _ = dashboard; _ = period
        switch result {
        case .success(let m): return m
        case .failure(let e): throw e
        }
    }
}

@MainActor
final class AnalyticsViewModelTests: XCTestCase {
    func testCacheTTLSkipsSecondNetworkCall() async throws {
        let dashboard = try MockHub().metrics(businessID: "biz-resto", dashboard: "revenue", period: "week")
        let source = CountingMetricsSource(result: .success(dashboard))
        let cache = PayloadCache()
        let vm = AnalyticsViewModel(dataSource: source, cache: cache)
        vm.bind(mode: .resto)
        vm.selectDashboard("revenue")
        vm.period = .week

        await vm.load(businessID: "biz-resto")
        await vm.load(businessID: "biz-resto")

        XCTAssertEqual(source.calls, 1)
        XCTAssertEqual(vm.metric?.key, "revenue")
        XCTAssertFalse(vm.isStub)
    }

    func testNotImplementedShowsStub() async {
        let source = CountingMetricsSource(result: .failure(APIError.notImplemented))
        let vm = AnalyticsViewModel(dataSource: source, cache: PayloadCache())
        vm.bind(mode: .resto)
        vm.selectDashboard("foodcost")

        await vm.load(businessID: "biz-resto")

        XCTAssertTrue(vm.isStub)
        XCTAssertNil(vm.metric)
        XCTAssertEqual(vm.stubBodyKey, "stub_foodcost")
    }

    func testModeSwitchRestoresDashboardSelection() {
        let vm = AnalyticsViewModel(dataSource: CountingMetricsSource(result: .failure(APIError.offline)), cache: PayloadCache())
        vm.bind(mode: .resto)
        vm.selectDashboard("menu-abc")
        vm.bind(mode: .ecom)
        XCTAssertEqual(vm.selectedDashboard, "sales")
        vm.selectDashboard("customers")
        vm.bind(mode: .resto)
        XCTAssertEqual(vm.selectedDashboard, "menu-abc")
    }

    func testFullMVPDashboardsExist() {
        let resto = AnalyticsCatalog.dashboards(for: .resto).filter(\.isFullMVP).map(\.key)
        let ecom = AnalyticsCatalog.dashboards(for: .ecom).filter(\.isFullMVP).map(\.key)
        XCTAssertEqual(Set(resto), Set(["revenue", "menu-abc"]))
        XCTAssertEqual(Set(ecom), Set(["sales", "customers"]))
    }
}
