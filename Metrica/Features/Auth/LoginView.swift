import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var appState: AppState
    @Environment(\.bizTheme) private var theme

    @State private var email = AppConfig.useMocks ? "owner@metrica.app" : ""
    @State private var password = AppConfig.useMocks ? "password" : ""
    @State private var isLoading = false
    @State private var showRegister = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(String(localized: "app_name"))
                            .font(.system(size: 34, weight: .heavy))
                            .foregroundStyle(theme.text)
                            .accessibilityIdentifier("auth_brand")
                        Text(String(localized: "auth_subtitle"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(theme.sub)
                    }
                    .padding(.top, 24)

                    VStack(spacing: 12) {
                        AuthField(
                            title: String(localized: "auth_email"),
                            text: $email,
                            contentType: .username,
                            keyboard: .emailAddress,
                            fieldIdentifier: "login_email"
                        )

                        AuthField(
                            title: String(localized: "auth_password"),
                            text: $password,
                            contentType: .password,
                            isSecure: true,
                            fieldIdentifier: "login_password"
                        )
                    }

                    if let error = auth.lastError {
                        Text(error)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(theme.red)
                            .accessibilityIdentifier("login_error")
                    }

                    Button {
                        Task { await submit() }
                    } label: {
                        AuthPrimaryButtonLabel(
                            title: String(localized: "auth_login"),
                            isLoading: isLoading
                        )
                    }
                    .disabled(isLoading)
                    .accessibilityIdentifier("login_button")

                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        Task { await handleApple(result) }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radiusS, style: .continuous))
                    .accessibilityIdentifier("login_apple")

                    if AppConfig.useMocks {
                        Button {
                            Task {
                                isLoading = true
                                defer { isLoading = false }
                                if await auth.loginWithAppleMock() {
                                    auth.applyProfile(to: appState)
                                }
                            }
                        } label: {
                            Text(String(localized: "auth_apple_mock"))
                                .font(.caption.weight(.bold))
                                .foregroundStyle(theme.sub)
                                .frame(maxWidth: .infinity)
                        }
                        .accessibilityIdentifier("login_apple_mock")
                    }

                    Button {
                        showRegister = true
                    } label: {
                        Text(String(localized: "auth_go_register"))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(theme.accent(for: .resto))
                            .frame(maxWidth: .infinity)
                    }
                    .accessibilityIdentifier("login_go_register")
                }
                .padding(20)
            }
            .background(theme.bg.ignoresSafeArea())
            .navigationDestination(isPresented: $showRegister) {
                RegisterView()
            }
        }
    }

    private func submit() async {
        isLoading = true
        defer { isLoading = false }
        if await auth.login(email: email, password: password) {
            auth.applyProfile(to: appState)
        }
    }

    private func handleApple(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .failure(let error):
            // Користувач скасував — не показуємо як фатальну помилку
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue { return }
            auth.lastError = error.localizedDescription
        case .success(let authResult):
            guard let cred = authResult.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = cred.identityToken,
                  let token = String(data: tokenData, encoding: .utf8) else {
                auth.lastError = String(localized: "auth_error_apple")
                return
            }
            let code = cred.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
            var name: String?
            if let full = cred.fullName {
                name = PersonNameComponentsFormatter().string(from: full)
            }
            isLoading = true
            defer { isLoading = false }
            if await auth.loginWithApple(identityToken: token, authorizationCode: code, fullName: name) {
                auth.applyProfile(to: appState)
            }
        }
    }
}

struct AuthField: View {
    @Environment(\.bizTheme) private var theme
    let title: String
    @Binding var text: String
    var contentType: UITextContentType? = nil
    var keyboard: UIKeyboardType = .default
    var isSecure = false
    var fieldIdentifier: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(theme.sub)
                .textCase(.uppercase)
            Group {
                if isSecure {
                    SecureField(title, text: $text)
                        .accessibilityIdentifier(fieldIdentifier ?? "secure_field")
                } else {
                    TextField(title, text: $text)
                        .keyboardType(keyboard)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier(fieldIdentifier ?? "text_field")
                }
            }
            .textContentType(contentType)
            .padding(14)
            .background(theme.card)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusS, style: .continuous))
            .shadow(color: theme.shadowCard.color, radius: theme.shadowCard.radius, y: theme.shadowCard.y)
            .foregroundStyle(theme.text)
        }
    }
}

struct AuthPrimaryButtonLabel: View {
    @Environment(\.bizTheme) private var theme
    let title: String
    var isLoading = false

    var body: some View {
        HStack {
            if isLoading { ProgressView().tint(.white) }
            Text(title)
                .font(.subheadline.weight(.heavy))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(theme.heroGradient(for: .resto))
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusM, style: .continuous))
        .shadow(color: theme.accent2(for: .resto).opacity(0.26), radius: 12, y: 8)
    }
}
