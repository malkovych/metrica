import SwiftUI

struct Chip: View {
    @Environment(\.bizTheme) private var theme
    @Environment(\.businessMode) private var mode
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .foregroundStyle(isActive ? theme.accent(for: mode) : theme.text)
                .background(isActive ? theme.accentSoft(for: mode) : theme.card)
                .clipShape(Capsule())
                .overlay {
                    if isActive {
                        Capsule().strokeBorder(theme.accent(for: mode), lineWidth: 1.5)
                    }
                }
                .shadow(color: isActive ? .clear : theme.shadowCard.color, radius: theme.shadowCard.radius, y: theme.shadowCard.y)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isActive ? .isSelected : [])
        .accessibilityLabel(title)
    }
}

struct PeriodSegment: View {
    @Environment(\.bizTheme) private var theme
    @Binding var selection: AnalyticsPeriod

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AnalyticsPeriod.allCases) { p in
                Button {
                    selection = p
                } label: {
                    Text(String(localized: String.LocalizationValue(p.titleKey)))
                        .font(.caption.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .foregroundStyle(selection == p ? theme.text : theme.sub)
                        .background(selection == p ? theme.card : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .shadow(color: selection == p ? theme.shadowCard.color : .clear, radius: 1.5, y: 1)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("period_\(p.rawValue)")
                .accessibilityAddTraits(selection == p ? .isSelected : [])
                .accessibilityLabel(String(localized: String.LocalizationValue(p.titleKey)))
            }
        }
        .padding(2)
        .background(theme.segmentTrack)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct LanguageSegment: View {
    @Environment(\.bizTheme) private var theme
    @Binding var selection: AppLanguage

    var body: some View {
        HStack(spacing: 0) {
            langButton("УКР", .uk)
            langButton("EN", .en)
        }
        .padding(2)
        .background(theme.segmentTrack)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    private func langButton(_ title: String, _ lang: AppLanguage) -> some View {
        let active = selection == lang || (selection == .system && lang == .uk)
        return Button {
            selection = lang
        } label: {
            Text(title)
                .font(.caption.weight(.heavy))
                .padding(.horizontal, 13)
                .padding(.vertical, 5)
                .foregroundStyle(active ? theme.text : theme.sub)
                .background(active ? theme.card : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(lang == .uk ? "lang_uk" : "lang_en")
        .accessibilityAddTraits(active ? .isSelected : [])
    }
}

struct StubCard: View {
    @Environment(\.bizTheme) private var theme
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Text("🚧").font(.largeTitle)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.text)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.caption)
                .foregroundStyle(theme.sub)
                .multilineTextAlignment(.center)
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .themeCardChrome(theme)
    }
}

struct SettingsCard<Content: View>: View {
    @Environment(\.bizTheme) private var theme
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(theme.sub)
                .textCase(.uppercase)
                .padding(.bottom, 8)
            content
        }
        .padding(15)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusM, style: .continuous))
        .shadow(color: theme.shadowCard.color, radius: theme.shadowCard.radius, y: theme.shadowCard.y)
    }
}

struct SettingsRow<Trailing: View>: View {
    @Environment(\.bizTheme) private var theme
    @Environment(\.businessMode) private var mode
    let icon: String
    let title: String
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Text(icon)
                    .frame(width: 30, height: 30)
                    .background(theme.accentSoft(for: mode))
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.text)
            }
            Spacer()
            trailing()
        }
        .padding(.vertical, 12)
    }
}
