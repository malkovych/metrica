import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.bizTheme) private var theme
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 29
    @StateObject private var vm = AnalyticsViewModel()

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(String(localized: "analytics"))
                    .font(.system(size: titleSize, weight: .heavy))
                    .foregroundStyle(theme.text)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .accessibilityIdentifier("analytics_title")

                PeriodSegment(selection: $vm.period)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .accessibilityIdentifier("analytics_period")

                ChipStrip(
                    items: vm.dashboards,
                    selectedKey: vm.selectedDashboard,
                    onSelect: { key in
                        vm.selectDashboard(key)
                    }
                )

                ScrollView {
                    AnalyticsDashboardBody(vm: vm)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                }
            }
            .background(theme.bg.ignoresSafeArea())
            .onAppear {
                vm.bind(mode: appState.mode)
                applyPendingDashboard()
            }
            .onChange(of: appState.mode) { _, newMode in
                vm.bind(mode: newMode)
            }
            .onChange(of: appState.pendingDashboardKey) { _, _ in
                applyPendingDashboard()
            }
            .task(id: loadToken) {
                await vm.load(businessID: appState.selectedBusinessID)
            }
        }
    }

    private func applyPendingDashboard() {
        guard let key = appState.pendingDashboardKey else { return }
        vm.selectDashboard(key)
        appState.pendingDashboardKey = nil
    }

    private var loadToken: String {
        "\(appState.selectedBusinessID ?? "")|\(vm.selectedDashboard)|\(vm.period.rawValue)|\(appState.mode.rawValue)"
    }
}

/// Горизонтальні чипи зі збереженням позиції скролу (ScrollViewReader → selected).
struct ChipStrip: View {
    let items: [AnalyticsDashboardDef]
    let selectedKey: String
    let onSelect: (String) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(items) { item in
                        Chip(
                            title: String(localized: String.LocalizationValue(item.titleKey)),
                            isActive: selectedKey == item.key
                        ) {
                            onSelect(item.key)
                        }
                        .id(item.key)
                        .accessibilityIdentifier("dash_chip_\(item.key)")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onAppear {
                proxy.scrollTo(selectedKey, anchor: .center)
            }
            .onChange(of: selectedKey) { _, key in
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(key, anchor: .center)
                }
            }
            .onChange(of: items.map(\.key)) { _, _ in
                proxy.scrollTo(selectedKey, anchor: .center)
            }
        }
    }
}

struct AnalyticsDashboardBody: View {
    @ObservedObject var vm: AnalyticsViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.bizTheme) private var theme

    var body: some View {
        Group {
            if vm.isLoading && vm.metric == nil && !vm.isStub {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 160)
                    .accessibilityIdentifier("analytics_loading")
            } else if vm.isStub {
                StubCard(
                    title: String(localized: "in_development"),
                    message: String(localized: String.LocalizationValue(vm.stubBodyKey))
                )
                .accessibilityIdentifier("analytics_stub")
            } else if let metric = vm.metric {
                AnalyticsDashboardContent(metric: metric)
                    .accessibilityIdentifier("analytics_content")
            } else if let error = vm.errorMessage {
                EmptyStateView(
                    symbol: "exclamationmark.triangle",
                    title: String(localized: "today_unavailable"),
                    message: error,
                    onRetry: {
                        Task { await vm.load(businessID: appState.selectedBusinessID) }
                    }
                )
            } else {
                ProgressView().frame(maxWidth: .infinity, minHeight: 120)
            }
        }
    }
}

/// Контент дашборда для UI + snapshot-тестів.
struct AnalyticsDashboardContent: View {
    @Environment(\.bizTheme) private var theme
    let metric: MetricDashboard

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let hero = metric.heroValue, let currency = metric.currency {
                heroCard(hero: hero, currency: currency)
            }

            ForEach(Array(metric.elements.enumerated()), id: \.offset) { _, el in
                MetricElementView(element: el, currency: metric.currency ?? "UAH")
            }
        }
    }

    private func heroCard(hero: Int, currency: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let key = metric.titleKey {
                Text(String(localized: String.LocalizationValue(key)))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.sub)
                    .textCase(.uppercase)
            }
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(MoneyFormatter.string(minorUnits: hero, currencyCode: currency))
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundStyle(theme.text)
                if let d = metric.heroDeltaPct {
                    Text(MoneyFormatter.deltaPct(d))
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(d >= 0 ? theme.green : theme.red)
                }
            }
            if let csub = metric.csub {
                Text(csub)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.sub)
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .themeCardChrome(theme)
    }
}
