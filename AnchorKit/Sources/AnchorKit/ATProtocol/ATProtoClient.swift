import Foundation

// MARK: - AT Protocol Client Protocol

@MainActor
public protocol ATProtoClientProtocol: Sendable {
    func login(request: ATProtoLoginRequest) async throws -> ATProtoLoginResponse
    func refresh(request: ATProtoRefreshRequest) async throws -> ATProtoRefreshResponse
    func createPost(request: ATProtoCreatePostRequest, credentials: AuthCredentials) async throws -> ATProtoCreateRecordResponse
    func createCheckin(request: ATProtoCreateCheckinRequest, credentials: AuthCredentials) async throws -> ATProtoCreateRecordResponse
}

// MARK: - AT Protocol Client Implementation

@MainActor
public final class ATProtoClient: ATProtoClientProtocol {

    // MARK: - Properties

    private let session: URLSessionProtocol
    private let baseURL: String

    // MARK: - Initialization

    public init(baseURL: String = "https://bsky.social", session: URLSessionProtocol = URLSession.shared) {
        self.baseURL = baseURL
        self.session = session
    }

    // MARK: - Authentication

    public func login(request: ATProtoLoginRequest) async throws -> ATProtoLoginResponse {
        let httpRequest = try buildRequest(
            endpoint: "/xrpc/com.atproto.server.createSession",
            method: "POST",
            body: request
        )

        let (data, response) = try await session.data(for: httpRequest)
        try validateResponse(response)

        do {
            return try JSONDecoder().decode(ATProtoLoginResponse.self, from: data)
        } catch {
            throw ATProtoError.decodingError(error)
        }
    }

    public func refresh(request: ATProtoRefreshRequest) async throws -> ATProtoRefreshResponse {
        let httpRequest = try buildRequest(
            endpoint: "/xrpc/com.atproto.server.refreshSession",
            method: "POST",
            body: request
        )

        let (data, response) = try await session.data(for: httpRequest)
        try validateResponse(response)

        do {
            return try JSONDecoder().decode(ATProtoRefreshResponse.self, from: data)
        } catch {
            throw ATProtoError.decodingError(error)
        }
    }

    // MARK: - Record Creation

    public func createPost(request: ATProtoCreatePostRequest, credentials: AuthCredentials) async throws -> ATProtoCreateRecordResponse {
        let httpRequest = try buildAuthenticatedRequest(
            endpoint: "/xrpc/com.atproto.repo.createRecord",
            method: "POST",
            body: request,
            accessToken: credentials.accessToken
        )

        let (data, response) = try await session.data(for: httpRequest)
        try validateResponse(response)

        do {
            return try JSONDecoder().decode(ATProtoCreateRecordResponse.self, from: data)
        } catch {
            throw ATProtoError.decodingError(error)
        }
    }

    public func createCheckin(request: ATProtoCreateCheckinRequest, credentials: AuthCredentials) async throws -> ATProtoCreateRecordResponse {
        let httpRequest = try buildAuthenticatedRequest(
            endpoint: "/xrpc/com.atproto.repo.createRecord",
            method: "POST",
            body: request,
            accessToken: credentials.accessToken
        )

        let (data, response) = try await session.data(for: httpRequest)
        try validateResponse(response)

        do {
            return try JSONDecoder().decode(ATProtoCreateRecordResponse.self, from: data)
        } catch {
            throw ATProtoError.decodingError(error)
        }
    }

    // MARK: - Private Methods

    private func buildRequest<T: Codable>(
        endpoint: String,
        method: String,
        body: T? = nil
    ) throws -> URLRequest {
        guard let url = URL(string: baseURL + endpoint) else {
            throw ATProtoError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Anchor/1.0 (macOS)", forHTTPHeaderField: "User-Agent")

        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                throw ATProtoError.decodingError(error)
            }
        }

        return request
    }

    private func buildAuthenticatedRequest<T: Codable>(
        endpoint: String,
        method: String,
        body: T? = nil,
        accessToken: String
    ) throws -> URLRequest {
        var request = try buildRequest(endpoint: endpoint, method: method, body: body)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ATProtoError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {
            throw ATProtoError.httpError(httpResponse.statusCode)
        }
    }
}
