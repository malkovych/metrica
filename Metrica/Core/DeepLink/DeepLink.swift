import Foundation

/// Deep-link: `metrica://business/{id}/today` | `.../dashboard/{key}` | `.../reports` | `.../alerts` | `sources/callback`
enum DeepLink: Equatable {
    case today(businessID: String)
    case dashboard(businessID: String, key: String)
    case reports(businessID: String)
    case alerts(businessID: String)
    case sourceCallback

    private static let supportedSchemes: Set<String> = ["metrica", "bizpulse"]

    static func parse(_ url: URL) -> DeepLink? {
        let path: [String]
        if let scheme = url.scheme?.lowercased(), supportedSchemes.contains(scheme) {
            var parts: [String] = []
            if let host = url.host, !host.isEmpty { parts.append(host) }
            parts.append(contentsOf: url.path.split(separator: "/").map(String.init))
            path = parts
        } else {
            path = url.path.split(separator: "/").map(String.init)
        }

        guard !path.isEmpty else { return nil }

        if path.first == "sources", path.dropFirst().first == "callback" {
            return .sourceCallback
        }

        guard path.count >= 2, path[0] == "business" else { return nil }
        let businessID = path[1]
        if path.count == 2 { return .today(businessID: businessID) }

        switch path[2] {
        case "today":
            return .today(businessID: businessID)
        case "dashboard" where path.count >= 4:
            return .dashboard(businessID: businessID, key: path[3])
        case "reports":
            return .reports(businessID: businessID)
        case "alerts":
            return .alerts(businessID: businessID)
        default:
            return nil
        }
    }

    var analyticsName: String {
        switch self {
        case .today: return "today"
        case .dashboard(_, let key): return "dashboard:\(key)"
        case .reports: return "reports"
        case .alerts: return "alerts"
        case .sourceCallback: return "source_callback"
        }
    }
}
