import Foundation

/// VoiceOver-тексти за §10 ТЗ (без символів ▲/▼ у мові).
enum AccessibilityCopy {
    /// «Виручка 48 250 гривень, плюс 12 відсотків»
    static func kpi(title: String, value: String, deltaPct: Double?, delta: String?, trend: Trend?) -> String {
        var parts = [title, spokenDigits(value)]
        if let deltaPct {
            parts.append(spokenDeltaPct(deltaPct))
        } else if let delta, !delta.isEmpty, delta != "–" {
            parts.append(spokenDigits(delta))
        } else if let trend {
            switch trend {
            case .up: parts.append(String(localized: "a11y_trend_up"))
            case .down: parts.append(String(localized: "a11y_trend_down"))
            case .warn: parts.append(String(localized: "a11y_trend_warn"))
            case .neutral: break
            }
        }
        return parts.joined(separator: ", ")
    }

    static func alert(title: String, body: String, severity: AlertSeverity, isUnread: Bool) -> String {
        var parts = [severityLabel(severity), title, body]
        if isUnread {
            parts.insert(String(localized: "a11y_unread"), at: 0)
        }
        return parts.joined(separator: ". ")
    }

    static func spokenDeltaPct(_ value: Double) -> String {
        let n = Int(abs(value).rounded())
        if value > 0 {
            return String(format: String(localized: "a11y_plus_pct"), n)
        }
        if value < 0 {
            return String(format: String(localized: "a11y_minus_pct"), n)
        }
        return String(localized: "a11y_flat_pct")
    }

    private static func spokenDigits(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "▲", with: "")
            .replacingOccurrences(of: "▼", with: "")
            .replacingOccurrences(of: "–", with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    private static func severityLabel(_ severity: AlertSeverity) -> String {
        switch severity {
        case .critical: return String(localized: "a11y_sev_critical")
        case .warning: return String(localized: "a11y_sev_warning")
        case .positive: return String(localized: "a11y_sev_positive")
        }
    }
}
