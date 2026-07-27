import Foundation

/// Модель ролей закладається в MVP; UI — тільки Власник (§2 Out).
enum TeamRole: String, Codable, Sendable, CaseIterable {
    case owner
    case manager
    case investor

    var localizationKey: String {
        switch self {
        case .owner: return "owner"
        case .manager: return "manager"
        case .investor: return "investor"
        }
    }
}

struct TeamMember: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let email: String?
    let role: TeamRole
}
