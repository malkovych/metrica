import Foundation

/// Відповідь дашборда Аналітики: заголовок, csub, елементи.
struct MetricDashboard: Codable, Hashable, Sendable {
    let key: String
    let titleKey: String?
    let csub: String?
    let heroValue: Int?
    let heroDeltaPct: Double?
    let currency: String?
    let elements: [MetricElement]
}

enum MetricElement: Codable, Hashable, Sendable {
    case bars(BarsElement)
    case list(ListElement)
    case matrix(MatrixElement)
    case funnel(BarsElement)
    case stub(StubElement)

    enum CodingKeys: String, CodingKey { case type }

    enum ElementType: String, Codable {
        case bars, list, matrix, funnel, stub
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(ElementType.self, forKey: .type)
        switch type {
        case .bars: self = .bars(try BarsElement(from: decoder))
        case .list: self = .list(try ListElement(from: decoder))
        case .matrix: self = .matrix(try MatrixElement(from: decoder))
        case .funnel: self = .funnel(try BarsElement(from: decoder))
        case .stub: self = .stub(try StubElement(from: decoder))
        }
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .bars(let e): try e.encode(to: encoder)
        case .list(let e): try e.encode(to: encoder)
        case .matrix(let e): try e.encode(to: encoder)
        case .funnel(let e): try e.encode(to: encoder)
        case .stub(let e): try e.encode(to: encoder)
        }
    }
}

struct BarsElement: Codable, Hashable, Sendable {
    let type: String
    let titleKey: String?
    let rows: [BarRow]
    let noteKey: String?
}

struct BarRow: Codable, Identifiable, Hashable, Sendable {
    var id: String { label }
    let label: String
    let pct: Double
    let valueLabel: String?
}

struct ListElement: Codable, Hashable, Sendable {
    let type: String
    let titleKey: String?
    let items: [TopListItem]
}

struct MatrixElement: Codable, Hashable, Sendable {
    let type: String
    let titleKey: String?
    let quadrants: [MatrixQuadrant]
}

struct MatrixQuadrant: Codable, Identifiable, Hashable, Sendable {
    var id: String { key }
    let key: String
    let titleKey: String
    let count: Int
    let bodyKey: String
    let tone: String
}

struct StubElement: Codable, Hashable, Sendable {
    let type: String
    let titleKey: String?
    let bodyKey: String?
}

struct UserProfile: Codable, Sendable {
    let id: String
    let email: String
    let name: String
    /// Роль поточного користувача. MVP UI — тільки owner.
    let role: TeamRole?
    let businesses: [Business]
    let team: [TeamMember]?
}
