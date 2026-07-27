import Foundation

enum SourceType: String, Codable, Sendable {
    case poster
    case woocommerce
    case opencart
}

enum BusinessMode: String, Codable, Sendable {
    case resto
    case ecom
}

struct Location: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
}

struct Business: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let emoji: String
    let sourceType: SourceType
    let mode: BusinessMode
    let currency: String
    let locations: [Location]
}
