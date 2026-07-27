import SwiftUI

struct RegisterView: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var appState: AppState
    @Environment(\.bizTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(String(localized: "auth_register_title"))
                    .font(.system(size: 29, weight: .heavy))
                    .foregroundStyle(theme.text)
                    .accessibilityIdentifier("register_title")

                VStack(spacing: 12) {
                    AuthField(title: String(localized: "auth_name"), text: $name, contentType: .name)
                        .accessibilityIdentifier("register_name")
                    AuthField(
                        title: String(localized: "auth_email"),
                        text: $email,
                        contentType: .username,
                        keyboard: .emailAddress
                    )
                    .accessibilityIdentifier("register_email")
                    AuthField(
                        title: String(localized: "auth_password"),
                        text: $password,
                        contentType: .newPassword,
                        isSecure: true
                    )
                    .accessibilityIdentifier("register_password")
                }

                if let error = auth.lastError {
                    Text(error)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.red)
                }

                Button {
                    Task { await submit() }
                } label: {
                    AuthPrimaryButtonLabel(
                        title: String(localized: "auth_register"),
                        isLoading: isLoading
                    )
                }
                .disabled(isLoading)
                .accessibilityIdentifier("register_button")

                Button {
                    dismiss()
                } label: {
                    Text(String(localized: "auth_go_login"))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(theme.accent(for: .resto))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(20)
        }
        .background(theme.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    private func submit() async {
        isLoading = true
        defer { isLoading = false }
        if await auth.register(name: name, email: email, password: password) {
            auth.applyProfile(to: appState)
        }
    }
}
