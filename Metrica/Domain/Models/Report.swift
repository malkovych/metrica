import Foundation

enum ReportType: String, Codable, Sendable {
    case weekly
    case monthly
    case investor
}

enum ReportStatus: String, Codable, Sendable {
    case ready
    case generating
}

struct Report: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let type: ReportType
    let period: String
    let status: ReportStatus
    let pdfURL: URL?
    let titleKey: String?
}
