import SwiftUI

struct KPIGrid: View {
    @Environment(\.bizTheme) private var theme
    let kpis: [KPI]

    var body: some View {
        let cols = theme.kpiVariant == .ops ? 3 : 2
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: cols == 3 ? 8 : 10), count: cols),
            spacing: cols == 3 ? 8 : 10
        ) {
            ForEach(Array(kpis.enumerated()), id: \.element.id) { idx, kpi in
                KPICard(kpi: kpi, compact: theme.kpiVariant == .ops, iconIndex: idx)
            }
        }
    }
}

struct KPICard: View {
    @Environment(\.bizTheme) private var theme
    @ScaledMetric(relativeTo: .caption2) private var labelSize: CGFloat = 10.5
    @ScaledMetric(relativeTo: .title3) private var valueSize: CGFloat = 21
    let kpi: KPI
    var compact = false
    var iconIndex = 0

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 3) {
            if theme.kpiVariant == .commerce {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(tileColor.opacity(0.18))
                    .frame(width: 26, height: 26)
                    .overlay {
                        Image(systemName: tileSymbol)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(tileColor)
                    }
                    .padding(.bottom, 2)
                    .accessibilityHidden(true)
            }

            Text(title)
                .font(.system(size: compact ? labelSize * 0.9 : labelSize, weight: .bold))
                .foregroundStyle(theme.sub)
                .textCase(.uppercase)
                .tracking(theme.kpiVariant == .fintech ? 1.2 : 0)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            Text(displayValue)
                .font(.system(size: compact ? valueSize * 0.8 : valueSize, weight: .heavy))
                .foregroundStyle(theme.text)
                .monospacedDigit()
                .minimumScaleFactor(0.65)
                .lineLimit(2)

            Text(deltaText)
                .font(.caption.weight(.heavy))
                .foregroundStyle(trendColor)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, compact ? 11 : 14)
        .padding(.vertical, compact ? 11 : 13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .themeCardChrome(theme)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(a11yLabel)
        .accessibilityIdentifier("kpi_\(kpi.key)")
    }

    private var a11yLabel: String {
        AccessibilityCopy.kpi(
            title: title,
            value: displayValue,
            deltaPct: kpi.deltaPct,
            delta: kpi.delta,
            trend: kpi.trend
        )
    }

    private var title: String {
        if let t = kpi.title { return t }
        return String(localized: String.LocalizationValue(kpi.key))
    }

    private var displayValue: String {
        if let unit = kpi.unitKey {
            return "\(kpi.value) \(String(localized: String.LocalizationValue(unit)))"
        }
        return kpi.value
    }

    private var deltaText: String {
        if let d = kpi.delta { return d }
        if let pct = kpi.deltaPct { return MoneyFormatter.deltaPct(pct) }
        return "–"
    }

    private var trendColor: Color {
        switch kpi.trend {
        case .up: return theme.green
        case .down: return theme.red
        case .warn: return theme.amber
        case .neutral: return theme.sub
        }
    }

    private var tileColor: Color {
        let palette = theme.commerceTiles
        return palette[iconIndex % max(palette.count, 1)]
    }

    private var tileSymbol: String {
        let symbols = ["chart.bar.fill", "cart.fill", "person.2.fill", "arrow.triangle.2.circlepath"]
        return symbols[iconIndex % symbols.count]
    }
}

struct SkeletonCard: View {
    @Environment(\.bizTheme) private var theme
    var body: some View {
        RoundedRectangle(cornerRadius: theme.radiusL, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [theme.card, theme.line, theme.card],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 200)
            .overlay {
                if let border = theme.cardBorder {
                    RoundedRectangle(cornerRadius: theme.radiusL, style: .continuous)
                        .strokeBorder(border, lineWidth: 1)
                }
            }
            .shadow(color: theme.shadowCard.color, radius: theme.shadowCard.radius, y: theme.shadowCard.y)
    }
}

struct SkeletonGrid: View {
    @Environment(\.bizTheme) private var theme

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(0..<4, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 4).fill(theme.line).frame(width: 64, height: 10)
                    RoundedRectangle(cornerRadius: 4).fill(theme.line).frame(width: 88, height: 22)
                    RoundedRectangle(cornerRadius: 4).fill(theme.line).frame(width: 48, height: 12)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .frame(maxWidth: .infinity, alignment: .leading)
                .themeCardChrome(theme)
            }
        }
    }
}
