import SwiftUI

/// Порожній / помилковий стан з опційним Retry (M6).
struct EmptyStateView: View {
    @Environment(\.bizTheme) private var theme
    @Environment(\.businessMode) private var mode
    var symbol: String = "wifi.exclamationmark"
    var title: String
    var message: String
    var retryTitle: String? = String(localized: "retry")
    var onRetry: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.title.weight(.semibold))
                .foregroundStyle(theme.sub)
                .accessibilityHidden(true)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.text)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(message)
                .font(.caption)
                .foregroundStyle(theme.sub)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let onRetry, let retryTitle {
                Button(action: onRetry) {
                    Text(retryTitle)
                        .font(.subheadline.weight(.bold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .foregroundStyle(theme.text)
                        .background(theme.accentSoft(for: mode))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
                .accessibilityIdentifier("empty_retry")
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .themeCardChrome(theme)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("empty_state")
    }
}

struct OfflineBanner: View {
    @Environment(\.bizTheme) private var theme

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.caption.weight(.bold))
            Text(String(localized: "offline_banner"))
                .font(.caption.weight(.bold))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundStyle(theme.amber)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(theme.amber.opacity(theme.preferredColorScheme == .dark ? 0.18 : 0.14))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityIdentifier("offline_banner")
        .accessibilityLabel(String(localized: "offline_banner"))
    }
}
