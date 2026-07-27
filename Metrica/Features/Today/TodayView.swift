import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.bizTheme) private var theme
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 29
    @StateObject private var vm = TodayViewModel()
    @State private var opsPeriod: AnalyticsPeriod = .day

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if theme.heroVariant != .opsGrid {
                        header
                    }

                    BusinessChips(
                        businesses: appState.businesses,
                        selectedID: appState.selectedBusinessID,
                        onSelect: { id in
                            appState.selectBusiness(id)
                        }
                    )
                    .accessibilityIdentifier("business_chips")

                    if vm.isOffline {
                        OfflineBanner()
                    }

                    TodayBody(
                        vm: vm,
                        businessName: appState.selectedBusiness?.name ?? String(localized: "app_name"),
                        opsPeriod: $opsPeriod,
                        onRetry: {
                            guard let id = appState.selectedBusinessID else { return }
                            Task { await vm.refresh(businessID: id) }
                        }
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(theme.bg.ignoresSafeArea())
            .refreshable {
                if let id = appState.selectedBusinessID {
                    await vm.refresh(businessID: id)
                }
            }
            .task(id: appState.selectedBusinessID) {
                if let id = appState.selectedBusinessID {
                    await vm.load(businessID: id)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                .font(.caption.weight(.bold))
                .foregroundStyle(theme.sub)
                .textCase(.uppercase)
            Text(String(localized: "today"))
                .font(.system(size: titleSize, weight: .heavy))
                .foregroundStyle(theme.text)
                .accessibilityIdentifier("today_title")
        }
        .padding(.top, 6)
    }
}

/// Винесено для snapshot-тестів (без network).
struct TodayBody: View {
    @ObservedObject var vm: TodayViewModel
    var businessName: String = String(localized: "app_name")
    var onRetry: (() -> Void)? = nil
    @Binding var opsPeriod: AnalyticsPeriod

    init(
        vm: TodayViewModel,
        businessName: String = "Metrica",
        opsPeriod: Binding<AnalyticsPeriod> = .constant(.day),
        onRetry: (() -> Void)? = nil
    ) {
        self.vm = vm
        self.businessName = businessName
        self._opsPeriod = opsPeriod
        self.onRetry = onRetry
    }

    var body: some View {
        Group {
            if vm.isLoading && vm.summary == nil {
                TodaySkeleton()
            } else if let summary = vm.summary {
                TodaySummaryContent(
                    summary: summary,
                    updatedLabel: vm.updatedLabel,
                    businessName: businessName,
                    opsPeriod: $opsPeriod
                )
            } else if let error = vm.errorMessage {
                EmptyStateView(
                    symbol: "exclamationmark.triangle",
                    title: String(localized: "today_unavailable"),
                    message: error,
                    onRetry: onRetry
                )
            } else {
                TodaySkeleton()
            }
        }
    }
}

struct TodaySummaryContent: View {
    @Environment(\.bizTheme) private var theme
    let summary: Summary
    var updatedLabel: String? = nil
    var businessName: String = String(localized: "app_name")
    @Binding var opsPeriod: AnalyticsPeriod

    init(
        summary: Summary,
        updatedLabel: String? = nil,
        businessName: String = "Metrica",
        opsPeriod: Binding<AnalyticsPeriod> = .constant(.day)
    ) {
        self.summary = summary
        self.updatedLabel = updatedLabel
        self.businessName = businessName
        self._opsPeriod = opsPeriod
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if theme.heroVariant == .opsGrid {
                OpsTodayHeader(businessName: businessName, period: $opsPeriod)
                    .accessibilityIdentifier("today_ops_header")
                OpsKPIGrid(summary: summary)
                // Погодинні бари на картці (тема C)
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "rev_today"))
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundStyle(theme.sub)
                        .textCase(.uppercase)
                    HourlyBars(points: summary.hourly, style: .greenOnCard)
                        .frame(height: 56)
                }
                .padding(15)
                .themeCardChrome(theme)
            } else {
                HeroCard(summary: summary)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(heroA11y)
                KPIGrid(kpis: summary.kpis)
            }

            ForEach(Array(summary.blocks.enumerated()), id: \.offset) { _, block in
                BlockRenderer(block: block, currency: summary.revenue.currency)
            }

            if let updated = updatedLabel {
                Text(updated)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(theme.sub)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("today_updated")
            }
        }
    }

    private var heroA11y: String {
        let money = MoneyFormatter.string(
            minorUnits: summary.revenue.value,
            currencyCode: summary.revenue.currency
        )
        return AccessibilityCopy.kpi(
            title: String(localized: "rev_today"),
            value: money,
            deltaPct: summary.revenue.deltaPct,
            delta: nil,
            trend: nil
        )
    }
}

struct TodaySkeleton: View {
    @Environment(\.bizTheme) private var theme

    var body: some View {
        VStack(spacing: 12) {
            SkeletonCard()
            SkeletonGrid()
            RoundedRectangle(cornerRadius: theme.radiusM, style: .continuous)
                .fill(theme.card)
                .frame(height: 72)
                .shadow(color: theme.shadowCard.color, radius: theme.shadowCard.radius, y: theme.shadowCard.y)
            RoundedRectangle(cornerRadius: theme.radiusM, style: .continuous)
                .fill(theme.card)
                .frame(height: 140)
                .shadow(color: theme.shadowCard.color, radius: theme.shadowCard.radius, y: theme.shadowCard.y)
        }
        .redacted(reason: .placeholder)
        .accessibilityIdentifier("today_skeleton")
    }
}
