import SwiftUI

/// Рендерери типів блоків з `/summary`. Клієнт не містить resto/ecom логіки.
struct BlockRenderer: View {
    let block: ContentBlock
    let currency: String

    var body: some View {
        switch block {
        case .shiftStatus(let b):
            ShiftStatusCard(block: b)
        case .topList(let b):
            TopListCard(block: b, currency: currency, ranked: true)
        case .sourceList(let b):
            TopListCard(block: b, currency: currency, ranked: false)
        case .paymentSplit(let b):
            PaymentSplitCard(block: b)
        case .stockAlert(let b):
            StockAlertInline(block: b)
        }
    }
}

struct ShiftStatusCard: View {
    @Environment(\.bizTheme) private var theme
    let block: ShiftStatusBlock

    var body: some View {
        HStack(spacing: 11) {
            Text("✅").font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(String(format: String(localized: "shift_open"), block.openedAt ?? ""))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.text)
                Text(String(format: String(localized: "shift_meta"), block.register ?? "", block.lead ?? ""))
                    .font(.caption)
                    .foregroundStyle(theme.shiftMeta)
            }
            Spacer()
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
        .background(theme.shiftSurface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusM, style: .continuous))
        .overlay(alignment: .leading) {
            if theme.id == .bDarkFintech {
                RoundedRectangle(cornerRadius: 2)
                    .fill(theme.green)
                    .frame(width: 2)
            }
        }
        .overlay {
            if theme.id == .cCleanOps {
                RoundedRectangle(cornerRadius: theme.radiusM, style: .continuous)
                    .strokeBorder(theme.shiftBorder, lineWidth: 1)
            } else if let border = theme.cardBorder, theme.id == .bDarkFintech {
                RoundedRectangle(cornerRadius: theme.radiusM, style: .continuous)
                    .strokeBorder(border, lineWidth: 1)
            }
        }
    }
}

struct TopListCard: View {
    @Environment(\.bizTheme) private var theme
    let block: TopListBlock
    let currency: String
    let ranked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let key = block.titleKey {
                Text(String(localized: String.LocalizationValue(key)))
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(theme.sub)
                    .textCase(.uppercase)
            }
            ForEach(Array(block.items.enumerated()), id: \.offset) { idx, item in
                ListRow(item: item, rank: ranked ? idx + 1 : nil, currency: currency)
                if idx < block.items.count - 1 {
                    Divider().overlay(theme.line)
                }
            }
        }
        .padding(15)
        .themeCardChrome(theme)
    }
}

struct ListRow: View {
    @Environment(\.bizTheme) private var theme
    @Environment(\.businessMode) private var mode
    let item: TopListItem
    let rank: Int?
    let currency: String

    var body: some View {
        HStack {
            HStack(spacing: 10) {
                if let rank {
                    Text("\(rank)")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(theme.accent(for: mode))
                        .frame(width: 22, height: 22)
                        .background(theme.accentSoft(for: mode))
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                } else if let emoji = item.emoji {
                    Text(emoji)
                        .frame(width: 32, height: 32)
                        .background(theme.bg)
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.text)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(theme.sub)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(valueText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.text)
                if let badge = item.badge {
                    Text(badge)
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(trendColor)
                } else if let trend = item.trend {
                    Text(trend == .up ? "▲" : (trend == .down ? "▼" : "–"))
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(trendColor)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var subtitle: String {
        if let label = item.sub?.label { return label }
        var parts: [String] = []
        if let sold = item.sub?.sold {
            parts.append(String(format: String(localized: "sold_count"), sold))
        }
        if let m = item.sub?.marginPct {
            parts.append(String(format: String(localized: "margin_pct"), Int(m)))
        }
        return parts.joined(separator: " · ")
    }

    private var valueText: String {
        if let label = item.valueLabel { return label }
        if let v = item.value {
            return MoneyFormatter.string(minorUnits: v, currencyCode: currency)
        }
        return ""
    }

    private var trendColor: Color {
        switch item.trend {
        case .up: return theme.green
        case .down: return theme.red
        case .warn: return theme.amber
        case .neutral, .none: return theme.sub
        }
    }
}

struct PaymentSplitCard: View {
    @Environment(\.bizTheme) private var theme
    @Environment(\.businessMode) private var mode
    let block: PaymentSplitBlock

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "payments"))
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(theme.sub)
                .textCase(.uppercase)
            GeometryReader { geo in
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(theme.accent(for: mode))
                        .frame(width: geo.size.width * block.card / 100)
                    Rectangle()
                        .fill(theme.accentSoft(for: mode))
                        .frame(width: geo.size.width * block.cash / 100)
                }
            }
            .frame(height: 10)
            .clipShape(Capsule())
            HStack {
                Text("💳 \(String(localized: "card")) · \(Int(block.card))%")
                Spacer()
                Text("💵 \(String(localized: "cash")) · \(Int(block.cash))%")
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(theme.sub)
        }
        .padding(15)
        .themeCardChrome(theme)
    }
}

struct StockAlertInline: View {
    @Environment(\.bizTheme) private var theme
    let block: StockAlertBlock

    var body: some View {
        AlertCard(alert: AlertItem(
            id: block.title,
            icon: "⚠️",
            title: block.title,
            body: block.body,
            severity: block.severity,
            deepLink: nil,
            createdAt: .now,
            isRead: nil
        ))
    }
}
