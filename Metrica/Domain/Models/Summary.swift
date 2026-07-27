import Foundation

struct MoneyValue: Codable, Hashable, Sendable {
    /// Сума у мінорних одиницях (копійки).
    let value: Int
    let currency: String
    let deltaPct: Double?
    let compareLabelKey: String?
}

struct HourPoint: Codable, Hashable, Sendable {
    let h: Int
    let v: Double
}

enum Trend: String, Codable, Sendable {
    case up, down, neutral, warn
}

struct KPI: Codable, Identifiable, Hashable, Sendable {
    var id: String { key }
    let key: String
    let title: String?
    let value: String
    let unitKey: String?
    let deltaPct: Double?
    let delta: String?
    let trend: Trend
}

struct TopListItem: Codable, Identifiable, Hashable, Sendable {
    var id: String { name }
    let name: String
    let emoji: String?
    let sub: TopListSub?
    let value: Int?
    let valueLabel: String?
    let trend: Trend?
    let badge: String?
}

struct TopListSub: Codable, Hashable, Sendable {
    let sold: Int?
    let marginPct: Double?
    let label: String?
}

enum ContentBlock: Codable, Hashable, Sendable {
    case shiftStatus(ShiftStatusBlock)
    case topList(TopListBlock)
    case paymentSplit(PaymentSplitBlock)
    case stockAlert(StockAlertBlock)
    case sourceList(TopListBlock)

    enum CodingKeys: String, CodingKey {
        case type
    }

    enum BlockType: String, Codable {
        case shiftStatus, topList, paymentSplit, stockAlert, sourceList
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(BlockType.self, forKey: .type)
        switch type {
        case .shiftStatus:
            self = .shiftStatus(try ShiftStatusBlock(from: decoder))
        case .topList:
            self = .topList(try TopListBlock(from: decoder))
        case .paymentSplit:
            self = .paymentSplit(try PaymentSplitBlock(from: decoder))
        case .stockAlert:
            self = .stockAlert(try StockAlertBlock(from: decoder))
        case .sourceList:
            self = .sourceList(try TopListBlock(from: decoder))
        }
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .shiftStatus(let b): try b.encode(to: encoder)
        case .topList(let b): try b.encode(to: encoder)
        case .paymentSplit(let b): try b.encode(to: encoder)
        case .stockAlert(let b): try b.encode(to: encoder)
        case .sourceList(let b): try b.encode(to: encoder)
        }
    }
}

struct ShiftStatusBlock: Codable, Hashable, Sendable {
    let type: String
    let state: String
    let openedAt: String?
    let register: String?
    let lead: String?
}

struct TopListBlock: Codable, Hashable, Sendable {
    let type: String
    let titleKey: String?
    let items: [TopListItem]
}

struct PaymentSplitBlock: Codable, Hashable, Sendable {
    let type: String
    let card: Double
    let cash: Double
}

struct StockAlertBlock: Codable, Hashable, Sendable {
    let type: String
    let title: String
    let body: String
    let severity: AlertSeverity
}

struct Summary: Codable, Hashable, Sendable {
    let revenue: MoneyValue
    let hourly: [HourPoint]
    let profit: MoneyValue?
    let marginPct: Double?
    let cashOnHand: Int?
    let ordersCount: Int?
    let kpis: [KPI]
    let blocks: [ContentBlock]
    let updatedAt: Date?
}
