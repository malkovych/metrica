import SwiftUI

struct MetricElementView: View {
    @Environment(\.bizTheme) private var theme
    @Environment(\.businessMode) private var mode
    let element: MetricElement
    var currency: String = "UAH"

    var body: some View {
        switch element {
        case .bars(let e), .funnel(let e):
            card {
                if let key = e.titleKey {
                    sectionTitle(key)
                }
                ForEach(e.rows) { row in
                    BarRowView(row: row)
                }
                if let note = e.noteKey {
                    Text(String(localized: String.LocalizationValue(note)))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.sub)
                        .padding(.top, 4)
                }
            }
        case .list(let e):
            TopListCard(
                block: TopListBlock(type: "topList", titleKey: e.titleKey, items: e.items),
                currency: currency,
                ranked: true
            )
        case .matrix(let e):
            card {
                if let key = e.titleKey {
                    sectionTitle(key)
                }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(e.quadrants) { q in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(String(localized: String.LocalizationValue(q.titleKey)))
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text("\(q.count)")
                                    .font(.subheadline.weight(.heavy))
                            }
                            Text(String(localized: String.LocalizationValue(q.bodyKey)))
                                .font(.caption)
                                .opacity(0.7)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, minHeight: 84, alignment: .topLeading)
                        .background(toneColor(q.tone))
                        .clipShape(RoundedRectangle(cornerRadius: theme.radiusS, style: .continuous))
                    }
                }
            }
        case .stub(let e):
            StubCard(
                title: String(localized: String.LocalizationValue(e.titleKey ?? "in_development")),
                message: String(localized: String.LocalizationValue(e.bodyKey ?? "stub_body"))
            )
        }
    }

    private func sectionTitle(_ key: String) -> some View {
        Text(String(localized: String.LocalizationValue(key)))
            .font(.system(size: 10.5, weight: .bold))
            .foregroundStyle(theme.sub)
            .textCase(.uppercase)
            .padding(.bottom, 4)
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            content()
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .themeCardChrome(theme)
        .padding(.bottom, 4)
    }

    private func toneColor(_ tone: String) -> Color {
        switch tone {
        case "green": return theme.successSoft
        case "amber": return theme.warnSoft
        case "blue": return theme.infoSoft
        case "red": return theme.dangerSoft
        default: return theme.bg
        }
    }
}

struct BarRowView: View {
    @Environment(\.bizTheme) private var theme
    @Environment(\.businessMode) private var mode
    let row: BarRow

    var body: some View {
        HStack(spacing: 10) {
            Text(row.label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.text)
                .frame(width: 92, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(theme.barTrack)
                    Capsule()
                        .fill(barFill)
                        .frame(width: geo.size.width * min(max(row.pct, 0), 100) / 100)
                }
            }
            .frame(height: theme.barHeight)
            Text(row.valueLabel ?? "")
                .font(.caption.weight(.heavy))
                .foregroundStyle(theme.text)
                .frame(width: 52, alignment: .trailing)
        }
    }

    private var barFill: some ShapeStyle {
        switch theme.id {
        case .bDarkFintech:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [theme.accent(for: .resto), theme.accent(for: .ecom)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        case .cCleanOps, .dCommercePro:
            return AnyShapeStyle(theme.accent(for: mode))
        case .aSoft:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [theme.accent(for: mode), theme.accent2(for: mode)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
    }
}
