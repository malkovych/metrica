import XCTest
@testable import Metrica

@MainActor
final class PayloadCacheTests: XCTestCase {
    func testSaveAndLoadSummary() throws {
        let cache = PayloadCache()
        let summary = try MockHub().summary(businessID: "biz-resto")
        try cache.save(summary, key: CacheKey.summary(businessID: "biz-resto"))

        let loaded = try cache.load(Summary.self, key: CacheKey.summary(businessID: "biz-resto"))
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.value.revenue.value, 4_825_000)
        XCTAssertEqual(loaded?.value.kpis.count, 4)
    }

    func testMissingKeyReturnsNil() throws {
        let cache = PayloadCache()
        let loaded = try cache.load(Summary.self, key: "summary:missing")
        XCTAssertNil(loaded)
    }
}
