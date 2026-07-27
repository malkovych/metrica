import Foundation
import SwiftUI
import Combine

/// Глобальний стан: бізнес, мова, тема, навігація (таби + deep-link).
@MainActor
final class AppState: ObservableObject {
    @Published var businesses: [Business] = []
    @Published var selectedBusinessID: String? {
        didSet { onBusinessChange?(selectedBusinessID) }
    }
    @Published var profileName: String?
    @Published var profileEmail: String?
    @Published var profileRole: TeamRole = .owner
    @Published var team: [TeamMember] = []
    @Published var themeID: ThemeID = .aSoft
    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: Keys.language) }
    }
    @Published var unreadAlertCount: Int = 0
    @Published var selectedTab: AppTab = .today
    /// Ключ дашборда з deep-link (Analytics підхоплює).
    @Published var pendingDashboardKey: String?
    @Published var sourceConnectMessage: String?

    var onBusinessChange: ((String?) -> Void)?

    private enum Keys {
        static let language = "app_language"
        static let theme = "theme_id"
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: Keys.language),
           let lang = AppLanguage(rawValue: raw) {
            language = lang
        } else {
            language = .system
        }
        if let raw = UserDefaults.standard.string(forKey: Keys.theme),
           let theme = ThemeID(rawValue: raw) {
            themeID = theme
        }
    }

    var selectedBusiness: Business? {
        businesses.first { $0.id == selectedBusinessID } ?? businesses.first
    }

    var mode: BusinessMode {
        selectedBusiness?.mode ?? .resto
    }

    var theme: any Theme {
        ThemeRegistry.theme(for: themeID)
    }

    var resolvedLanguage: AppLanguage {
        switch language {
        case .system:
            let code = Locale.current.language.languageCode?.identifier ?? "uk"
            return code.hasPrefix("uk") ? .uk : .en
        default:
            return language
        }
    }

    var locale: Locale {
        switch resolvedLanguage {
        case .uk: return Locale(identifier: "uk_UA")
        case .en: return Locale(identifier: "en_US")
        case .system: return .current
        }
    }

    func selectBusiness(_ id: String) {
        guard id != selectedBusinessID else { return }
        selectedBusinessID = id
    }

    func setTheme(_ id: ThemeID) {
        guard id.isAvailable else { return }
        themeID = id
        UserDefaults.standard.set(id.rawValue, forKey: Keys.theme)
    }

    func apply(profile: UserProfile, preferredBusinessID: String?) {
        profileName = profile.name
        profileEmail = profile.email
        profileRole = profile.role ?? .owner
        team = profile.team ?? []
        businesses = profile.businesses
        if let preferred = preferredBusinessID,
           profile.businesses.contains(where: { $0.id == preferred }) {
            selectedBusinessID = preferred
        } else if selectedBusinessID == nil || !profile.businesses.contains(where: { $0.id == selectedBusinessID }) {
            selectedBusinessID = profile.businesses.first?.id
        }
    }

    func clearSessionData() {
        businesses = []
        selectedBusinessID = nil
        profileName = nil
        profileEmail = nil
        profileRole = .owner
        team = []
        unreadAlertCount = 0
        selectedTab = .today
        pendingDashboardKey = nil
    }

    func open(_ url: URL) {
        guard let link = DeepLink.parse(url) else { return }
        open(link)
    }

    func open(_ link: DeepLink) {
        switch link {
        case .today(let businessID):
            selectBusiness(businessID)
            selectedTab = .today
        case .dashboard(let businessID, let key):
            selectBusiness(businessID)
            pendingDashboardKey = key
            selectedTab = .analytics
        case .reports(let businessID):
            selectBusiness(businessID)
            selectedTab = .reports
        case .alerts(let businessID):
            selectBusiness(businessID)
            selectedTab = .alerts
        case .sourceCallback:
            sourceConnectMessage = String(localized: "source_connected_toast")
            selectedTab = .settings
        }
        #if DEBUG
        AppLog.info("deeplink_open", ["name": link.analyticsName])
        #endif
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case uk
    case en

    var id: String { rawValue }
}

enum AppTab: Hashable {
    case today, analytics, reports, alerts, settings

    var analyticsName: String {
        switch self {
        case .today: return "today"
        case .analytics: return "analytics"
        case .reports: return "reports"
        case .alerts: return "alerts"
        case .settings: return "settings"
        }
    }
}
