import Foundation

/// Feature-flags і конфіг середовища.
enum AppConfig {
    /// Контракт-перший: до готовності Хаба працюємо проти mock / фікстур.
    static let useMocks: Bool = {
        #if DEBUG
        if let env = ProcessInfo.processInfo.environment["USE_MOCKS"] {
            return env != "0"
        }
        return true
        #else
        return false
        #endif
    }()

    static let hubBaseURL: URL = {
        if let raw = ProcessInfo.processInfo.environment["HUB_BASE_URL"],
           let url = URL(string: raw) {
            return url
        }
        // Локальний mock-сервер (MockServer/serve.py)
        return URL(string: "http://127.0.0.1:8787/v1")!
    }()

    /// M9: TLS pinning (SPKI). Увімкнути: `ENABLE_TLS_PINNING=1`.
    static var enableTLSPinning: Bool {
        if let env = ProcessInfo.processInfo.environment["ENABLE_TLS_PINNING"] {
            return env == "1" || env.lowercased() == "true"
        }
        #if DEBUG
        return false
        #else
        return !pinnedSPKIHashes.isEmpty
        #endif
    }

    /// Хости, для яких застосовується pin (без локального mock).
    static let pinnedHosts: Set<String> = ["api.hub.example"]

    /// Base64 SHA-256 SPKI leaf-сертифіката. Порожньо = pinning не жорсткий (див. TLSPinningDelegate).
    static let pinnedSPKIHashes: [String] = {
        if let raw = ProcessInfo.processInfo.environment["TLS_SPKI_HASHES"], !raw.isEmpty {
            return raw.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        }
        return []
    }()
}
