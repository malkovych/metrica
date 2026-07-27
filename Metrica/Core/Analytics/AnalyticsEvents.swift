import Foundation

/// Аналітика подій (§10). Без PII — лише ключі/ідентифікатори сутностей.
enum AnalyticsEvents {
    private static let sink: AnalyticsSink = InMemoryAnalyticsSink.shared

    static func screenView(_ name: String) {
        track("screen_view", ["screen": name])
    }

    static func dashboardOpen(key: String) {
        track("dashboard_open", ["key": key])
    }

    static func alertTap(id: String) {
        track("alert_tap", ["id": id])
    }

    static func reportShare(id: String) {
        track("report_share", ["id": id])
    }

    static func languageChange(_ lang: AppLanguage) {
        track("language_change", ["lang": lang.rawValue])
    }

    private static func track(_ name: String, _ props: [String: String]) {
        sink.track(name: name, properties: props)
        AppLog.debug("analytics", ["event": name] .merging(props) { _, n in n })
    }
}

protocol AnalyticsSink: AnyObject {
    func track(name: String, properties: [String: String])
}

/// Кільцевий буфер для тестів / майбутнього експорту.
final class InMemoryAnalyticsSink: AnalyticsSink {
    static let shared = InMemoryAnalyticsSink()

    private let lock = NSLock()
    private(set) var events: [(name: String, props: [String: String])] = []
    private let capacity = 200

    func track(name: String, properties: [String: String]) {
        lock.lock()
        defer { lock.unlock() }
        events.append((name, properties))
        if events.count > capacity {
            events.removeFirst(events.count - capacity)
        }
    }

    func reset() {
        lock.lock()
        events.removeAll()
        lock.unlock()
    }
}
