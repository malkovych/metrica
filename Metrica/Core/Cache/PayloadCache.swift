import Foundation
import SwiftData

/// Персистентний кеш JSON-відповідей (summary/metrics) per business.
@MainActor
final class PayloadCache {
    static let shared = PayloadCache()

    private var container: ModelContainer?
    private var context: ModelContext?
    private let encoder = JSONEncoder()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    /// In-memory fallback (тести / якщо SwiftData ще не підключено).
    private var memory: [String: (Data, Date)] = [:]

    func configure(container: ModelContainer) {
        self.container = container
        self.context = ModelContext(container)
    }

    func save<T: Encodable>(_ value: T, key: String) throws {
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(value)
        let now = Date.now
        memory[key] = (data, now)

        guard let context else { return }
        let fd = FetchDescriptor<CachedPayload>(predicate: #Predicate { $0.key == key })
        if let existing = try context.fetch(fd).first {
            existing.data = data
            existing.updatedAt = now
        } else {
            context.insert(CachedPayload(key: key, data: data, updatedAt: now))
        }
        try context.save()
    }

    func load<T: Decodable>(_ type: T.Type, key: String) throws -> CachedValue<T>? {
        if let context {
            let fd = FetchDescriptor<CachedPayload>(predicate: #Predicate { $0.key == key })
            if let row = try context.fetch(fd).first {
                let value = try decoder.decode(T.self, from: row.data)
                return CachedValue(value: value, updatedAt: row.updatedAt)
            }
        }
        if let (data, at) = memory[key] {
            let value = try decoder.decode(T.self, from: data)
            return CachedValue(value: value, updatedAt: at)
        }
        return nil
    }

    func clearAll() throws {
        memory.removeAll()
        guard let context else { return }
        try context.delete(model: CachedPayload.self)
        try context.save()
    }
}

struct CachedValue<T> {
    let value: T
    let updatedAt: Date
}
