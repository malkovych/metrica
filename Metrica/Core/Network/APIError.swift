import Foundation

struct APIErrorBody: Codable, Sendable {
    struct Payload: Codable, Sendable {
        let code: String
        let message: String
    }
    let error: Payload
}

enum APIError: LocalizedError {
    case invalidURL
    case http(status: Int, code: String?, message: String?)
    case decoding(Error)
    case unauthorized
    case notImplemented
    case offline
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .http(_, let code, let message): return message ?? code ?? "HTTP error"
        case .decoding(let e): return "Decoding: \(e.localizedDescription)"
        case .unauthorized: return "Unauthorized"
        case .notImplemented: return "Not implemented"
        case .offline: return "Offline"
        case .unknown(let e): return e.localizedDescription
        }
    }
}
