import Foundation
import Combine

/// Сесія користувача: login/register/Apple → Keychain → /me → бізнеси.
@MainActor
final class AuthService: ObservableObject {
    @Published private(set) var phase: AuthPhase = .unauthenticated
    @Published private(set) var profile: UserProfile?
    @Published var lastError: String?

    private let client: APIClient
    private let defaults: UserDefaults
    private let selectedBusinessKey = "selectedBusinessID"

    init(client: APIClient = .shared, defaults: UserDefaults = .standard) {
        self.client = client
        self.defaults = defaults
    }

    var isAuthenticated: Bool {
        if case .authenticated = phase { return true }
        return false
    }

    var persistedBusinessID: String? {
        get { defaults.string(forKey: selectedBusinessKey) }
        set {
            if let newValue {
                defaults.set(newValue, forKey: selectedBusinessKey)
            } else {
                defaults.removeObject(forKey: selectedBusinessKey)
            }
        }
    }

    func bootstrap() async {
        phase = .bootstrapping
        guard let access = KeychainStore.get(.accessToken) else {
            phase = .unauthenticated
            return
        }
        await client.setAccessToken(access)
        do {
            try await loadProfile()
            phase = .authenticated
        } catch APIError.unauthorized {
            if await refreshSession() {
                do {
                    try await loadProfile()
                    phase = .authenticated
                    return
                } catch {
                    await logout(clearError: false)
                }
            } else {
                await logout(clearError: false)
            }
        } catch {
            // Офлайн / mock: якщо токен є — лишаємось «у сесії» з порожнім профілем
            lastError = error.localizedDescription
            phase = .unauthenticated
            KeychainStore.clearAuth()
            await client.setAccessToken(nil)
        }
    }

    func login(email: String, password: String) async -> Bool {
        lastError = nil
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !password.isEmpty else {
            lastError = String(localized: "auth_error_empty")
            return false
        }
        do {
            let tokens = try await client.login(email: trimmed, password: password)
            try await persist(tokens)
            try await loadProfile()
            phase = .authenticated
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    func register(name: String, email: String, password: String) async -> Bool {
        lastError = nil
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty, !trimmedName.isEmpty else {
            lastError = String(localized: "auth_error_empty")
            return false
        }
        guard password.count >= 6 else {
            lastError = String(localized: "auth_error_password_short")
            return false
        }
        do {
            let tokens = try await client.register(email: trimmedEmail, password: password, name: trimmedName)
            try await persist(tokens)
            try await loadProfile()
            phase = .authenticated
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    func loginWithApple(identityToken: String, authorizationCode: String?, fullName: String?) async -> Bool {
        lastError = nil
        do {
            let tokens = try await client.apple(
                identityToken: identityToken,
                authorizationCode: authorizationCode,
                fullName: fullName
            )
            try await persist(tokens)
            try await loadProfile()
            phase = .authenticated
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    /// DEBUG/UITest: Sign in with Apple без ASAuthorization (мок).
    func loginWithAppleMock() async -> Bool {
        await loginWithApple(
            identityToken: "mock-apple-identity",
            authorizationCode: "mock-apple-code",
            fullName: "Apple User"
        )
    }

    func logout() async {
        await logout(clearError: true)
    }

    /// Скидання сесії для UI-тестів (до bootstrap).
    func resetForUITests() {
        KeychainStore.clearAuth()
        profile = nil
        lastError = nil
        phase = .unauthenticated
        persistedBusinessID = nil
    }

    func loadProfile() async throws {
        let me = try await client.me()
        profile = me
    }

    func applyProfile(to appState: AppState) {
        guard let profile else { return }
        appState.apply(profile: profile, preferredBusinessID: persistedBusinessID)
    }

    func rememberSelectedBusiness(_ id: String?) {
        persistedBusinessID = id
    }

    // MARK: - Private

    private func persist(_ tokens: AuthTokens) async throws {
        try KeychainStore.set(tokens.accessToken, for: .accessToken)
        try KeychainStore.set(tokens.refreshToken, for: .refreshToken)
        await client.setAccessToken(tokens.accessToken)
    }

    private func refreshSession() async -> Bool {
        guard let refresh = KeychainStore.get(.refreshToken) else { return false }
        do {
            let tokens = try await client.refresh(refreshToken: refresh)
            try await persist(tokens)
            return true
        } catch {
            return false
        }
    }

    private func logout(clearError: Bool) async {
        KeychainStore.clearAuth()
        await client.setAccessToken(nil)
        profile = nil
        if clearError { lastError = nil }
        phase = .unauthenticated
    }
}

enum AuthPhase: Equatable {
    case bootstrapping
    case unauthenticated
    case authenticated
}
