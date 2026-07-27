import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var auth: AuthService
    @Environment(\.bizTheme) private var theme
    @State private var showAddSource = false

    private var connectURL: URL {
        AppConfig.hubBaseURL
            .appendingPathComponent("connect")
            .appendingPathComponent("sources")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "settings"))
                        .font(.system(size: 29, weight: .heavy))
                        .foregroundStyle(theme.text)
                        .accessibilityIdentifier("settings_title")

                    if let toast = appState.sourceConnectMessage {
                        Text(toast)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(theme.green)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(theme.successSoft)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    appState.sourceConnectMessage = nil
                                }
                            }
                    }

                    if let name = appState.profileName {
                        SettingsCard(title: String(localized: "account")) {
                            SettingsRow(icon: "👤", title: name) {
                                Text(String(localized: String.LocalizationValue(appState.profileRole.localizationKey)))
                                    .foregroundStyle(theme.sub)
                                    .font(.subheadline)
                            }
                            if let email = appState.profileEmail {
                                Text(email)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(theme.sub)
                                    .padding(.bottom, 4)
                            }
                        }
                    }

                    SettingsCard(title: String(localized: "sources")) {
                        ForEach(appState.businesses) { biz in
                            SettingsRow(
                                icon: biz.emoji,
                                title: "\(biz.name) — \(biz.sourceType.rawValue.capitalized)"
                            ) {
                                Text(String(localized: "connected"))
                                    .font(.caption.weight(.heavy))
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 3)
                                    .background(theme.successSoft)
                                    .foregroundStyle(theme.connectedBadgeForeground)
                                    .clipShape(Capsule())
                            }
                        }
                        Button {
                            showAddSource = true
                        } label: {
                            SettingsRow(icon: "➕", title: String(localized: "add_source")) {
                                Image(systemName: "chevron.right").foregroundStyle(theme.sub)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("add_source_button")
                    }

                    SettingsCard(title: String(localized: "theme")) {
                        ForEach(ThemeID.allCases) { id in
                            ThemeOptionRow(
                                id: id,
                                selected: appState.themeID == id,
                                enabled: id.isAvailable
                            ) {
                                appState.setTheme(id)
                            }
                        }
                    }

                    SettingsCard(title: String(localized: "lang")) {
                        SettingsRow(icon: "🌐", title: String(localized: "app_lang")) {
                            LanguageSegment(selection: Binding(
                                get: { appState.language },
                                set: { newValue in
                                    appState.language = newValue
                                    AnalyticsEvents.languageChange(newValue)
                                }
                            ))
                        }
                    }

                    SettingsCard(title: String(localized: "team")) {
                        ForEach(displayTeam) { member in
                            SettingsRow(icon: "👤", title: member.name) {
                                Text(String(localized: String.LocalizationValue(member.role.localizationKey)))
                                    .foregroundStyle(theme.sub)
                                    .font(.subheadline)
                            }
                        }
                    }

                    Button {
                        Task {
                            await auth.logout()
                            appState.clearSessionData()
                        }
                    } label: {
                        Text(String(localized: "auth_logout"))
                            .font(.subheadline.weight(.heavy))
                            .foregroundStyle(theme.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(theme.card)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radiusM, style: .continuous))
                    }
                    .accessibilityIdentifier("logout_button")

                    Text("USE_MOCKS = \(AppConfig.useMocks ? "ON" : "OFF")")
                        .font(.caption2)
                        .foregroundStyle(theme.sub)
                        .frame(maxWidth: .infinity)
                }
                .padding(16)
            }
            .background(theme.bg.ignoresSafeArea())
            .sheet(isPresented: $showAddSource) {
                // Web-флоу підключення джерела (SFSafariViewController)
                if AppConfig.useMocks {
                    MockSourceConnectSheet {
                        showAddSource = false
                        appState.open(URL(string: "metrica://sources/callback")!)
                    }
                } else {
                    SafariView(url: connectURL)
                }
            }
        }
    }

    private var displayTeam: [TeamMember] {
        if appState.team.isEmpty {
            return [
                TeamMember(id: "t1", name: appState.profileName ?? "Павло М.", email: appState.profileEmail, role: .owner),
                TeamMember(id: "t2", name: "Ірина К.", email: nil, role: .manager),
                TeamMember(id: "t3", name: "invest@fund.ua", email: "invest@fund.ua", role: .investor),
            ]
        }
        return appState.team
    }
}

/// Mock-заміна Safari для підключення джерела (без реального хаба).
struct MockSourceConnectSheet: View {
    @Environment(\.bizTheme) private var theme
    let onComplete: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("🔗")
                    .font(.system(size: 48))
                Text(String(localized: "add_source"))
                    .font(.title3.weight(.heavy))
                Text(String(localized: "source_connect_mock_body"))
                    .font(.subheadline)
                    .foregroundStyle(theme.sub)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Button(action: onComplete) {
                    Text(String(localized: "source_connect_done"))
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(theme.heroGradient(for: .resto))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 24)
                .accessibilityIdentifier("source_connect_done")
                Spacer()
            }
            .padding(.top, 40)
            .background(theme.bg.ignoresSafeArea())
            .navigationTitle(String(localized: "sources"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ThemeOptionRow: View {
    @Environment(\.bizTheme) private var theme
    @Environment(\.businessMode) private var mode
    let id: ThemeID
    let selected: Bool
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(swatch)
                    .frame(width: 34, height: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.text)
                    Text(String(localized: String.LocalizationValue(id.subtitleKey)))
                        .font(.caption)
                        .foregroundStyle(theme.sub)
                }
                Spacer()
                Circle()
                    .strokeBorder(selected ? theme.accent(for: mode) : theme.line, lineWidth: selected ? 6 : 2)
                    .frame(width: 20, height: 20)
            }
            .padding(.vertical, 10)
            .opacity(enabled ? 1 : 0.55)
        }
        .disabled(!enabled)
        .buttonStyle(.plain)
        .accessibilityIdentifier("theme_option_\(id.rawValue)")
    }

    private var name: String { id.displayName }

    private var swatch: AnyShapeStyle {
        let colors = ThemeRegistry.theme(for: id).previewSwatch
        if colors.count >= 2 {
            return AnyShapeStyle(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        return AnyShapeStyle(colors.first ?? .gray)
    }
}
