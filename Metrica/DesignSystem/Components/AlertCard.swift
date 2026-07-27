import SwiftUI

struct AlertCard: View {
    @Environment(\.bizTheme) private var theme
    @Environment(\.businessMode) private var mode
    let alert: AlertItem

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Text(alert.icon)
                .frame(width: 36, height: 36)
                .background(theme.accentSoft(for: mode))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(alert.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.text)
                Text(alert.body)
                    .font(.caption)
                    .foregroundStyle(theme.sub)
                    .lineSpacing(2)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 14)
        .themeCardChrome(theme)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(borderColor)
                .frame(width: theme.alertBorderWidth)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            AccessibilityCopy.alert(
                title: alert.title,
                body: alert.body,
                severity: alert.severity,
                isUnread: !(alert.isRead ?? true)
            )
        )
    }

    private var borderColor: Color {
        switch alert.severity {
        case .critical: return theme.red
        case .warning: return theme.amber
        case .positive: return theme.green
        }
    }
}
