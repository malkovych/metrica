import SwiftUI

/// 5 табів MVP: Сьогодні / Аналітика / Звіти / Сповіщення / Налаштування
struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.bizTheme) private var theme

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            TodayView()
                .tabItem {
                    Label(String(localized: "t_today"), systemImage: "sun.max.fill")
                }
                .tag(AppTab.today)

            AnalyticsView()
                .tabItem {
                    Label(String(localized: "t_analytics"), systemImage: "chart.bar.fill")
                }
                .tag(AppTab.analytics)

            ReportsView()
                .tabItem {
                    Label(String(localized: "t_reports"), systemImage: "doc.text.fill")
                }
                .tag(AppTab.reports)

            AlertsView()
                .tabItem {
                    Label(String(localized: "t_alerts"), systemImage: "bell.fill")
                }
                .tag(AppTab.alerts)
                .badge(appState.unreadAlertCount > 0 ? appState.unreadAlertCount : 0)

            SettingsView()
                .tabItem {
                    Label(String(localized: "t_settings"), systemImage: "gearshape.fill")
                }
                .tag(AppTab.settings)
        }
        .background(theme.bg.ignoresSafeArea())
        .onAppear {
            AnalyticsEvents.screenView(appState.selectedTab.analyticsName)
        }
        .onChange(of: appState.selectedTab) { _, tab in
            AnalyticsEvents.screenView(tab.analyticsName)
        }
    }
}
