import SwiftUI

struct HeroCard: View {
    @Environment(\.bizTheme) private var theme
    @Environment(\.businessMode) private var mode
    let summary: Summary

    var body: some View {
        switch theme.heroVariant {
        case .opsGrid:
            EmptyView()
        case .gradientSoft:
            softHero
        case .darkNeon:
            neonHero
        case .darkSolid:
            solidHero
        }
    }

    // MARK: A

    private var softHero: some View {
        VStack(alignment: .leading, spacing: 0) {
            heroHeader(deltaStyle: .pillWhite)
            HourlyBars(points: summary.hourly, style: .whiteOnHero)
                .frame(height: 60)
                .padding(.top, 12)
            heroFooter(divider: Color.white.opacity(0.25), labelOpacity: 0.8)
        }
        .foregroundStyle(.white)
        .padding(18)
        .background(theme.heroGradient(for: mode))
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusL, style: .continuous))
        .shadow(color: theme.accent2(for: mode).opacity(0.26), radius: 16, y: 10)
    }

    // MARK: B

    private var neonHero: some View {
        VStack(alignment: .leading, spacing: 0) {
            heroHeader(deltaStyle: .accentText)
            HourlyLineChart(points: summary.hourly, accent: theme.accent(for: mode))
                .frame(height: 64)
                .padding(.top, 12)
            heroFooter(divider: theme.line, labelOpacity: 1)
        }
        .foregroundStyle(theme.text)
        .padding(18)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusL, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: theme.radiusL, style: .continuous)
                .strokeBorder(theme.cardBorder ?? theme.line, lineWidth: 1)
        }
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(theme.accent(for: mode).opacity(0.13))
                .frame(width: 140, height: 140)
                .blur(radius: 30)
                .offset(x: 40, y: -40)
                .allowsHitTesting(false)
        }
        .clipped()
    }

    // MARK: D

    private var solidHero: some View {
        VStack(alignment: .leading, spacing: 0) {
            heroHeader(deltaStyle: .accentPill)
            HourlyBars(points: summary.hourly, style: .greyPeakAccent)
                .frame(height: 60)
                .padding(.top, 12)
            heroFooter(divider: Color.white.opacity(0.12), labelOpacity: 0.7)
        }
        .foregroundStyle(.white)
        .padding(18)
        .background(theme.heroSolid)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusL, style: .continuous))
    }

    // MARK: Shared

    private enum DeltaStyle { case pillWhite, accentText, accentPill }

    private func heroHeader(deltaStyle: DeltaStyle) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(String(localized: "rev_today"))
                .font(.caption.weight(.bold))
                .opacity(theme.heroVariant == .darkNeon ? 1 : 0.85)
                .foregroundStyle(theme.heroVariant == .darkNeon ? theme.sub : .white)
                .textCase(.uppercase)

            Text(MoneyFormatter.string(minorUnits: summary.revenue.value, currencyCode: summary.revenue.currency))
                .font(.system(size: 38, weight: .heavy).monospacedDigit())
                .padding(.top, 3)
                .foregroundStyle(theme.heroVariant == .darkNeon ? theme.text : .white)

            if let delta = summary.revenue.deltaPct {
                let text = MoneyFormatter.deltaPct(delta) + " " + String(localized: "vs_last_same_weekday")
                switch deltaStyle {
                case .pillWhite:
                    Text(text)
                        .font(.caption.weight(.heavy))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.22))
                        .clipShape(Capsule())
                case .accentText:
                    Text(text)
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(theme.accent(for: mode))
                case .accentPill:
                    Text(text)
                        .font(.caption.weight(.heavy))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(theme.accent(for: mode).opacity(0.22))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private func heroFooter(divider: Color, labelOpacity: Double) -> some View {
        HStack {
            ForEach(Array(labels.enumerated()), id: \.offset) { idx, item in
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.value)
                        .font(.system(size: 17, weight: .heavy).monospacedDigit())
                    Text(item.label)
                        .font(.system(size: 10.5, weight: .bold))
                        .opacity(labelOpacity)
                        .textCase(.uppercase)
                }
                if idx < labels.count - 1 { Spacer() }
            }
        }
        .padding(.top, 12)
        .overlay(alignment: .top) {
            Rectangle().fill(divider).frame(height: 1)
        }
        .padding(.top, 12)
    }

    private var labels: [(value: String, label: String)] {
        let currency = summary.revenue.currency
        switch mode {
        case .resto:
            return [
                (MoneyFormatter.string(minorUnits: summary.profit?.value ?? 0, currencyCode: currency), String(localized: "profit")),
                ("\(Int(summary.marginPct ?? 0))%", String(localized: "margin")),
                (MoneyFormatter.string(minorUnits: summary.cashOnHand ?? 0, currencyCode: currency), String(localized: "cash_register")),
            ]
        case .ecom:
            return [
                (MoneyFormatter.string(minorUnits: summary.profit?.value ?? 0, currencyCode: currency), String(localized: "gross_profit")),
                ("\(Int(summary.marginPct ?? 0))%", String(localized: "margin")),
                ("\(summary.ordersCount ?? 0)", String(localized: "orders_count")),
            ]
        }
    }
}

enum HourlyBarStyle {
    case whiteOnHero
    case greyPeakAccent
    case greenOnCard
}

struct HourlyBars: View {
    @Environment(\.bizTheme) private var theme
    @Environment(\.businessMode) private var mode
    let points: [HourPoint]
    var style: HourlyBarStyle = .whiteOnHero

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(Array(points.enumerated()), id: \.offset) { _, p in
                RoundedRectangle(cornerRadius: 3)
                    .fill(fill(for: p.v))
                    .frame(maxWidth: .infinity)
                    .frame(height: max(4, 60 * p.v / 100))
            }
        }
    }

    private func fill(for v: Double) -> Color {
        let peak = v >= 88
        switch style {
        case .whiteOnHero:
            return Color.white.opacity(peak ? 1 : 0.5)
        case .greyPeakAccent:
            return peak ? theme.accent(for: mode) : theme.chartMuted
        case .greenOnCard:
            return peak ? theme.accent(for: mode) : theme.chartMuted
        }
    }
}

/// Тема B: лінія + градієнтна заливка.
struct HourlyLineChart: View {
    let points: [HourPoint]
    let accent: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let maxV = max(points.map(\.v).max() ?? 1, 1)
            let coords: [CGPoint] = points.enumerated().map { idx, p in
                let x = points.count == 1 ? w / 2 : w * CGFloat(idx) / CGFloat(points.count - 1)
                let y = h - h * CGFloat(p.v / maxV)
                return CGPoint(x: x, y: y)
            }

            ZStack {
                Path { path in
                    guard let first = coords.first else { return }
                    path.move(to: CGPoint(x: first.x, y: h))
                    for c in coords { path.addLine(to: c) }
                    if let last = coords.last {
                        path.addLine(to: CGPoint(x: last.x, y: h))
                    }
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.32), accent.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                Path { path in
                    guard let first = coords.first else { return }
                    path.move(to: first)
                    for c in coords.dropFirst() { path.addLine(to: c) }
                }
                .stroke(accent, style: StrokeStyle(lineWidth: 2, lineJoin: .round))
            }
        }
    }
}

/// Тема C: шапка замість героя + сітка 3×2.
struct OpsTodayHeader: View {
    @Environment(\.bizTheme) private var theme
    @Environment(\.businessMode) private var mode
    let businessName: String
    @Binding var period: AnalyticsPeriod

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(theme.sub)
                        .textCase(.uppercase)
                    HStack(spacing: 8) {
                        Text(businessName)
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundStyle(theme.text)
                        Text(mode == .resto ? "resto" : "ecom")
                            .font(.caption2.weight(.heavy))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(theme.accentSoft(for: mode))
                            .foregroundStyle(theme.accent(for: mode))
                            .clipShape(Capsule())
                    }
                }
                Spacer()
            }
            PeriodSegment(selection: $period)
        }
        .padding(14)
        .themeCardChrome(theme)
    }
}

struct OpsKPIGrid: View {
    @Environment(\.bizTheme) private var theme
    @Environment(\.businessMode) private var mode
    let summary: Summary

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
            ],
            spacing: 8
        ) {
            ForEach(opsKPIs) { kpi in
                KPICard(kpi: kpi, compact: true)
            }
        }
    }

    private var opsKPIs: [KPI] {
        let currency = summary.revenue.currency
        let rev = MoneyFormatter.string(minorUnits: summary.revenue.value, currencyCode: currency)
        let profit = MoneyFormatter.string(minorUnits: summary.profit?.value ?? 0, currencyCode: currency)
        var base: [KPI] = [
            KPI(key: "ops_rev", title: String(localized: "rev_today"), value: rev, unitKey: nil, deltaPct: summary.revenue.deltaPct, delta: nil, trend: .up),
            KPI(
                key: "ops_profit",
                title: String(localized: String.LocalizationValue(mode == .resto ? "profit" : "gross_profit")),
                value: profit,
                unitKey: nil,
                deltaPct: nil,
                delta: nil,
                trend: .neutral
            ),
        ]
        for k in summary.kpis.prefix(4) {
            base.append(k)
        }
        return Array(base.prefix(6))
    }
}
