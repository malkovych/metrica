import Foundation
import SwiftData

/// Офлайн-кеш останніх summary/metrics per business (SwiftData).
@Model
final class CachedPayload {
    @Attribute(.unique) var key: String
    var data: Data
    var updatedAt: Date

    init(key: String, data: Data, updatedAt: Date = .now) {
        self.key = key
        self.data = data
        self.updatedAt = updatedAt
    }
}

enum CacheKey {
    static func summary(businessID: String) -> String { "summary:\(businessID)" }
    static func metrics(businessID: String, dashboard: String, period: String) -> String {
        "metrics:\(businessID):\(dashboard):\(period)"
    }
}
