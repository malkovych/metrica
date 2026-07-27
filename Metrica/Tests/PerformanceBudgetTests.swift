import XCTest
@testable import Metrica

/// M6 §10: кеш < 200 мс; summary з mock — один запит ≤ 2 с.
@MainActor
final class PerformanceBudgetTests: XCTestCase {
    func testSummaryCacheReadUnder200ms() throws {
        let cache = PayloadCache()
        let summary = try MockHub().summary(businessID: "biz-resto")
        let key = CacheKey.summary(businessID: "biz-resto")
        try cache.save(summary, key: key)

        let start = CFAbsoluteTimeGetCurrent()
        let loaded = try cache.load(Summary.self, key: key)
        let elapsedMs = (CFAbsoluteTimeGetCurrent() - start) * 1000
        XCTAssertNotNil(loaded)
        XCTAssertLessThan(elapsedMs, 200, "cache read \(elapsedMs)ms")
    }

    func testMockSummaryRequestUnder2s() async throws {
        let start = CFAbsoluteTimeGetCurrent()
        _ = try await APIClient.shared.summary(businessID: "biz-resto")
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        XCTAssertLessThan(elapsed, 2.0, "TTI mock \(elapsed)s")
    }
}
