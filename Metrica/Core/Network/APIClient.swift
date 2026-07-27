import Foundation

/// Обгортка URLSession. При `AppConfig.useMocks` — відповіді з фікстур MockServer.
actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let mock: MockHub
    private var accessToken: String?

    init(session: URLSession = URLSessionFactory.make()) {
        self.session = session
        self.mock = MockHub()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .useDefaultKeys
        self.decoder = decoder
    }

    func setAccessToken(_ token: String?) {
        accessToken = token
    }

    // MARK: - Auth

    func login(email: String, password: String) async throws -> AuthTokens {
        if AppConfig.useMocks {
            return try mock.login(email: email, password: password)
        }
        let body = ["email": email, "password": password]
        return try await post("/auth/login", body: body)
    }

    func register(email: String, password: String, name: String) async throws -> AuthTokens {
        if AppConfig.useMocks {
            return try mock.register(email: email, password: password, name: name)
        }
        let body = ["email": email, "password": password, "name": name]
        return try await post("/auth/register", body: body)
    }

    func apple(identityToken: String, authorizationCode: String?, fullName: String?) async throws -> AuthTokens {
        if AppConfig.useMocks {
            return try mock.apple(identityToken: identityToken)
        }
        struct Body: Encodable {
            let identityToken: String
            let authorizationCode: String?
            let fullName: String?
        }
        return try await post(
            "/auth/apple",
            body: Body(identityToken: identityToken, authorizationCode: authorizationCode, fullName: fullName)
        )
    }

    func refresh(refreshToken: String) async throws -> AuthTokens {
        if AppConfig.useMocks {
            return AuthTokens(accessToken: "mock-access", refreshToken: refreshToken, expiresIn: 3600)
        }
        return try await post("/auth/refresh", body: ["refreshToken": refreshToken])
    }

    // MARK: - Me / Businesses

    func me() async throws -> UserProfile {
        if AppConfig.useMocks { return try mock.me() }
        return try await get("/me")
    }

    func summary(businessID: String, date: String? = nil) async throws -> Summary {
        if AppConfig.useMocks { return try mock.summary(businessID: businessID) }
        var path = "/businesses/\(businessID)/summary"
        if let date { path += "?date=\(date)" }
        return try await get(path)
    }

    func metrics(
        businessID: String,
        dashboard: String,
        period: String,
        from: String? = nil,
        to: String? = nil,
        location: String? = nil
    ) async throws -> MetricDashboard {
        if AppConfig.useMocks {
            return try mock.metrics(businessID: businessID, dashboard: dashboard, period: period)
        }
        var comps = URLComponents(string: "/businesses/\(businessID)/metrics/\(dashboard)")!
        var items = [URLQueryItem(name: "period", value: period)]
        if let from { items.append(.init(name: "from", value: from)) }
        if let to { items.append(.init(name: "to", value: to)) }
        if let location { items.append(.init(name: "location", value: location)) }
        comps.queryItems = items
        return try await get(comps.string ?? "")
    }

    func alerts(businessID: String, cursor: String? = nil) async throws -> AlertsPage {
        if AppConfig.useMocks { return try mock.alerts(businessID: businessID, cursor: cursor) }
        var path = "/businesses/\(businessID)/alerts"
        if let cursor { path += "?cursor=\(cursor)" }
        return try await get(path)
    }

    func reports(businessID: String) async throws -> [Report] {
        if AppConfig.useMocks { return try mock.reports(businessID: businessID) }
        return try await get("/businesses/\(businessID)/reports")
    }

    func registerDevice(apnsToken: String) async throws {
        if AppConfig.useMocks { return }
        let _: EmptyResponse = try await post("/devices", body: ["token": apnsToken, "platform": "ios"])
    }

    // MARK: - HTTP

    private func get<T: Decodable>(_ path: String) async throws -> T {
        try await request(path, method: "GET", body: Optional<Data>.none)
    }

    private func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        let data = try JSONEncoder().encode(body)
        return try await request(path, method: "POST", body: data)
    }

    private func request<T: Decodable>(_ path: String, method: String, body: Data?) async throws -> T {
        guard let url = URL(string: path, relativeTo: AppConfig.hubBaseURL) else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            req.httpBody = body
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let accessToken {
            req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw APIError.unknown(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.unknown(URLError(.badServerResponse))
        }

        if http.statusCode == 401 { throw APIError.unauthorized }
        if http.statusCode == 501 { throw APIError.notImplemented }

        guard (200..<300).contains(http.statusCode) else {
            let err = try? decoder.decode(APIErrorBody.self, from: data)
            throw APIError.http(
                status: http.statusCode,
                code: err?.error.code,
                message: err?.error.message
            )
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }
}

struct AuthTokens: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
}

private struct EmptyResponse: Codable, Sendable {}
