import Foundation
import OSLog

/// Логи без PII (§10): без email/токенів/імен.
enum AppLog {
    private static let logger = Logger(subsystem: "com.metrica.app", category: "app")

    static func debug(_ message: String, _ fields: [String: String] = [:]) {
        logger.debug("\(message, privacy: .public) \(sanitize(fields), privacy: .public)")
    }

    static func info(_ message: String, _ fields: [String: String] = [:]) {
        logger.info("\(message, privacy: .public) \(sanitize(fields), privacy: .public)")
    }

    static func error(_ message: String, _ fields: [String: String] = [:]) {
        logger.error("\(message, privacy: .public) \(sanitize(fields), privacy: .public)")
    }

    static func fault(_ message: String, _ fields: [String: String] = [:]) {
        logger.fault("\(message, privacy: .public) \(sanitize(fields), privacy: .public)")
    }

    private static let banned = ["email", "password", "token", "jwt", "authorization", "name", "phone"]

    private static func sanitize(_ fields: [String: String]) -> String {
        fields
            .filter { key, _ in !banned.contains(where: { key.lowercased().contains($0) }) }
            .map { "\($0.key)=\($0.value)" }
            .sorted()
            .joined(separator: " ")
    }
}
