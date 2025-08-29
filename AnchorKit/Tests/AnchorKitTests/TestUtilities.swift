@testable import AnchorKit
import Foundation
import Testing

// MARK: - Test Utilities

/// Utilities for creating test instances and mock data
public enum TestUtilities {
    // MARK: - Service Creation

    /// Creates a CheckInStore with in-memory storage for testing
    @MainActor
    public static func createTestCheckInStore(session: URLSessionProtocol = MockURLSession()) -> CheckInStore {
        let authStore = AuthStore(storage: createTestStorage())
        return CheckInStore(authStore: authStore, session: session)
    }

    /// Creates in-memory credentials storage for testing
    @MainActor
    public static func createTestStorage() -> CredentialsStorageProtocol {
        InMemoryCredentialsStorage()
    }

    /// Creates a CheckInStore with custom storage for advanced testing scenarios
    @MainActor
    public static func createTestCheckInStore(
        session: URLSessionProtocol = MockURLSession(),
        storage: CredentialsStorageProtocol
    ) -> CheckInStore {
        let authStore = AuthStore(storage: storage)
        return CheckInStore(authStore: authStore, session: session)
    }

    // MARK: - Mock Data

    /// Creates a sample Place for testing
    public static func createSamplePlace() -> Place {
        Place(
            elementType: .way,
            elementId: 123_456_789,
            name: "Test Climbing Gym",
            latitude: 37.7749,
            longitude: -122.4194,
            tags: [
                "leisure": "climbing",
                "name": "Test Climbing Gym",
                "sport": "climbing"
            ]
        )
    }

    // AuthCredentials creation methods removed to avoid SwiftData ModelContainer issues in CI.
    // Tests that need credentials use mock storage or service-level mocking instead.
}

// MARK: - Mock AuthStore for Testing

@MainActor
public final class MockAuthStore: AuthStoreProtocol {
    public var isAuthenticated: Bool = false
    public var credentials: AuthCredentials?
    public var handle: String?
    public var shouldThrowAuthError: Bool = false

    // Test credentials for mocking authentication
    public var testCredentials: TestAuthCredentials?

    public init() {
        // Set up default test credentials
        testCredentials = TestAuthCredentials.valid()
        isAuthenticated = true
    }

    public func loadStoredCredentials() async -> AuthCredentials? {
        return credentials
    }


    
    public func startDirectOAuthFlow() async throws -> URL {
        if shouldThrowAuthError {
            throw AuthStoreError.authenticationFailed
        }
        return URL(string: "https://dropanchor.app/mobile-auth")!
    }

    public func handleSecureOAuthCallback(_ callbackURL: URL) async throws -> Bool {
        if shouldThrowAuthError {
            throw AuthStoreError.authenticationFailed
        }
        isAuthenticated = true
        testCredentials = TestAuthCredentials.valid()
        return true
    }

    public func signOut() async {
        credentials = nil
        testCredentials = nil
        isAuthenticated = false
    }

    public func getValidCredentials() async throws -> AuthCredentialsProtocol {
        if shouldThrowAuthError {
            throw AuthStoreError.notAuthenticated
        }

        guard let testCredentials = testCredentials else {
            throw AuthStoreError.notAuthenticated
        }

        return testCredentials
    }

    public func validateSessionOnAppLaunch() async {
        // Mock implementation - no action needed
    }

    public func validateSessionOnAppResume() async {
        // Mock implementation - no action needed
    }
}

// MARK: - Mock Backend Service

public class MockAnchorCheckinsService: AnchorCheckinsServiceProtocol {
    public var shouldThrowError = false
    public var createCheckinResult = CheckinResult(success: true, checkinId: "test-checkin-id")
    public var createCheckinCallCount = 0
    public var lastCreateCheckinPlace: Place?
    public var lastCreateCheckinMessage: String?
    // lastCreateCheckinAccessToken removed - no longer needed with Iron Session auth

    public func createCheckin(place: Place, message: String?) async throws -> CheckinResult {
        createCheckinCallCount += 1
        lastCreateCheckinPlace = place
        lastCreateCheckinMessage = message

        if shouldThrowError {
            throw NSError(domain: "MockCheckinsService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock checkins service error"])
        }

        return createCheckinResult
    }

    public func reset() {
        shouldThrowError = false
        createCheckinResult = CheckinResult(success: true, checkinId: "test-checkin-id")
        createCheckinCallCount = 0
        lastCreateCheckinPlace = nil
        lastCreateCheckinMessage = nil
    }
}

// MARK: - Test Credentials Implementation

/// Test implementation of AuthCredentialsProtocol that doesn't require SwiftData
public struct TestAuthCredentials: AuthCredentialsProtocol {
    public let handle: String
    public let accessToken: String
    public let refreshToken: String
    public let did: String
    public let pdsURL: String
    public let expiresAt: Date
    public let appPassword: String?
    public let sessionId: String?

    public var isExpired: Bool {
        expiresAt.timeIntervalSinceNow < 300 // 5 minutes buffer
    }

    public var isValid: Bool {
        !handle.isEmpty && !accessToken.isEmpty && !did.isEmpty && !pdsURL.isEmpty && !isExpired
    }

    public init(handle: String, accessToken: String, refreshToken: String, did: String, pdsURL: String, expiresAt: Date, appPassword: String? = nil, sessionId: String? = nil) {
        self.handle = handle
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.did = did
        self.pdsURL = pdsURL
        self.expiresAt = expiresAt
        self.appPassword = appPassword
        self.sessionId = sessionId
    }

    // Convenience initializers for common test scenarios
    public static func valid() -> TestAuthCredentials {
        TestAuthCredentials(
            handle: "test.bsky.social",
            accessToken: "test-access-token",
            refreshToken: "test-refresh-token",
            did: "did:plc:test123",
            pdsURL: "https://bsky.social",
            expiresAt: Date().addingTimeInterval(3600), // 1 hour from now
            appPassword: "test-app-password",
            sessionId: "test-session-id"
        )
    }

    public static func expired() -> TestAuthCredentials {
        TestAuthCredentials(
            handle: "expired.bsky.social",
            accessToken: "expired-token",
            refreshToken: "expired-refresh",
            did: "did:plc:expired",
            pdsURL: "https://bsky.social",
            expiresAt: Date().addingTimeInterval(-3600), // 1 hour ago
            appPassword: "expired-app-password",
            sessionId: "expired-session-id"
        )
    }
}

// MARK: - Mock Storage for Advanced Testing

/// Mock storage that allows inspection and control of storage operations
@MainActor
public final class MockCredentialsStorage: CredentialsStorageProtocol {
    public var credentials: AuthCredentials?
    public var saveCallCount = 0
    public var loadCallCount = 0
    public var clearCallCount = 0
    public var shouldThrowOnSave = false
    public var shouldThrowOnClear = false

    public init(initialCredentials: AuthCredentials? = nil) {
        credentials = initialCredentials
    }

    public func save(_ credentials: AuthCredentialsProtocol) async throws {
        saveCallCount += 1
        if shouldThrowOnSave {
            throw NSError(domain: "MockStorage", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock save error"])
        }
        // Convert protocol to concrete type for storage
        self.credentials = AuthCredentials(
            handle: credentials.handle,
            accessToken: credentials.accessToken,
            refreshToken: credentials.refreshToken,
            did: credentials.did,
            pdsURL: credentials.pdsURL,
            expiresAt: credentials.expiresAt,
            appPassword: credentials.appPassword,
            sessionId: credentials.sessionId
        )
    }

    public func load() async -> AuthCredentials? {
        loadCallCount += 1
        return credentials
    }

    public func clear() async throws {
        clearCallCount += 1
        if shouldThrowOnClear {
            throw NSError(domain: "MockStorage", code: 2, userInfo: [NSLocalizedDescriptionKey: "Mock clear error"])
        }
        credentials = nil
    }

    /// Reset all counters for a fresh test
    public func reset() {
        saveCallCount = 0
        loadCallCount = 0
        clearCallCount = 0
        shouldThrowOnSave = false
        shouldThrowOnClear = false
        credentials = nil
    }
}

// MARK: - Mock URL Session

/// Mock URLSession for testing network requests
public final class MockURLSession: URLSessionProtocol, @unchecked Sendable {
    private let _data: Data?
    private let _response: URLResponse?
    private let _error: Error?
    private let _responses: [(Data, URLResponse)]
    private var responseIndex = 0

    public var data: Data? { _data }
    public var response: URLResponse? { _response }
    public var error: Error? { _error }
    public var responses: [(Data, URLResponse)] { _responses }

    public init(data: Data? = nil, response: URLResponse? = nil, error: Error? = nil, responses: [(Data, URLResponse)] = []) {
        _data = data
        _response = response
        _error = error
        _responses = responses
    }

    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = _error {
            throw error
        }

        // If we have multiple responses configured, use them in sequence
        if !_responses.isEmpty {
            let currentIndex = responseIndex
            responseIndex += 1

            if currentIndex < _responses.count {
                return _responses[currentIndex]
            } else {
                // Fall back to last response if we've exhausted the list
                return _responses.last ?? (Data(), URLResponse())
            }
        }

        let data = _data ?? Data()
        let response = _response ?? HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        return (data, response)
    }
}

/// Mutable MockURLSession for tests that need to change responses during execution
public final class MutableMockURLSession: URLSessionProtocol, @unchecked Sendable {
    public var data: Data?
    public var response: URLResponse?
    public var error: Error?
    public var responses: [(Data, URLResponse)] = []
    private var responseIndex = 0

    public init(data: Data? = nil, response: URLResponse? = nil, error: Error? = nil) {
        self.data = data
        self.response = response
        self.error = error
    }

    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error {
            throw error
        }

        // If we have multiple responses configured, use them in sequence
        if !responses.isEmpty {
            let currentIndex = responseIndex
            responseIndex += 1

            if currentIndex < responses.count {
                return responses[currentIndex]
            } else {
                // Fall back to last response if we've exhausted the list
                return responses.last ?? (Data(), URLResponse())
            }
        }

        let data = data ?? Data()
        let response = response ?? HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        return (data, response)
    }

    // Reset for new test
    public func reset() {
        data = nil
        response = nil
        error = nil
        responses = []
        responseIndex = 0
    }
}

// MARK: - Mock HTTP Response Helper

/// Helper for creating mock HTTP responses
public enum MockHTTPResponse {
    public static func success(data: Data, statusCode: Int = 200) -> (Data, URLResponse) {
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (data, response)
    }

    public static func failure(statusCode: Int, data: Data = Data()) -> (Data, URLResponse) {
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (data, response)
    }
}
