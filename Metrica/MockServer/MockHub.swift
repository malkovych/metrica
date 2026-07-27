import Foundation

/// Локальний хаб з JSON-фікстур. Дзеркалить Hub API v1 (§5 ТЗ).
struct MockHub: Sendable {
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func login(email: String, password: String) throws -> AuthTokens {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !email.isEmpty, email.contains("@"), !password.isEmpty else {
            throw APIError.http(status: 400, code: "invalid_credentials", message: "Invalid email or password")
        }
        // UI-тест / демо: owner@metrica.app / password; також будь-який валідний email у mock.
        return AuthTokens(accessToken: "mock-access-\(email)", refreshToken: "mock-refresh", expiresIn: 3600)
    }

    func register(email: String, password: String, name: String) throws -> AuthTokens {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw APIError.http(status: 400, code: "invalid_name", message: "Name required")
        }
        guard password.count >= 6 else {
            throw APIError.http(status: 400, code: "weak_password", message: "Password too short")
        }
        return try login(email: email, password: password)
    }

    func apple(identityToken: String) throws -> AuthTokens {
        guard !identityToken.isEmpty else {
            throw APIError.http(status: 400, code: "invalid_apple_token", message: "Missing identity token")
        }
        return AuthTokens(accessToken: "mock-apple-access", refreshToken: "mock-apple-refresh", expiresIn: 3600)
    }

    func me() throws -> UserProfile {
        try load("me")
    }

    func summary(businessID: String) throws -> Summary {
        let name = businessID == "biz-ecom" ? "summary_ecom" : "summary_resto"
        return try load(name)
    }

    func metrics(businessID: String, dashboard: String, period: String) throws -> MetricDashboard {
        _ = period
        let mode = businessID == "biz-ecom" ? "ecom" : "resto"
        let stubKeys: Set<String> = [
            "foodcost", "staff", "control", "locations",
            "products", "orders", "channels"
        ]
        if stubKeys.contains(dashboard) {
            return MetricDashboard(
                key: dashboard,
                titleKey: dashboard,
                csub: nil,
                heroValue: nil,
                heroDeltaPct: nil,
                currency: "UAH",
                elements: [
                    .stub(StubElement(type: "stub", titleKey: "in_development", bodyKey: "stub_body"))
                ]
            )
        }
        let file = "metrics_\(mode)_\(dashboard.replacingOccurrences(of: "-", with: "_"))"
        do {
            return try load(file)
        } catch {
            throw APIError.notImplemented
        }
    }

    func alerts(businessID: String, cursor: String? = nil) throws -> AlertsPage {
        if cursor == "page2" {
            let name = businessID == "biz-ecom" ? "alerts_ecom_page2" : "alerts_resto_page2"
            return try load(name)
        }
        let name = businessID == "biz-ecom" ? "alerts_ecom" : "alerts_resto"
        return try load(name)
    }

    func reports(businessID: String) throws -> [Report] {
        _ = businessID
        return try load("reports")
    }

    private func load<T: Decodable>(_ name: String) throws -> T {
        guard let url = bundle.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
                ?? bundle.url(forResource: name, withExtension: "json") else {
            throw APIError.http(status: 404, code: "fixture_missing", message: "Missing fixture \(name).json")
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }
}
