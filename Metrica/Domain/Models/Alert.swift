import Foundation

enum AlertSeverity: String, Codable, Sendable {
    case critical
    case warning
    case positive
}

struct AlertItem: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let icon: String
    let title: String
    let body: String
    let severity: AlertSeverity
    let deepLink: String?
    let createdAt: Date
    let isRead: Bool?
}

struct AlertsPage: Codable, Sendable {
    let items: [AlertItem]
    let nextCursor: String?
    let unreadCount: Int?
}
