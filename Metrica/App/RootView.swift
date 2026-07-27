import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var auth: AuthService

    var body: some View {
        Group {
            switch auth.phase {
            case .bootstrapping:
                ZStack {
                    ThemeA().bg.ignoresSafeArea()
                    ProgressView()
                }
                .accessibilityIdentifier("auth_bootstrap")
            case .unauthenticated:
                LoginView()
            case .authenticated:
                MainTabView()
            }
        }
        .environment(\.bizTheme, appState.theme)
        .environment(\.businessMode, appState.mode)
        .environment(\.locale, appState.locale)
        .tint(appState.theme.accent(for: appState.mode))
        .preferredColorScheme(appState.theme.preferredColorScheme)
        .animation(.easeInOut(duration: 0.2), value: auth.phase)
        .animation(.easeInOut(duration: 0.15), value: appState.resolvedLanguage)
        .animation(.easeInOut(duration: 0.2), value: appState.themeID)
    }
}
