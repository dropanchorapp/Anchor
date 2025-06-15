@testable import AnchorKit
import Foundation
import SwiftData
import Testing

// MARK: - Test Utilities

/// Utilities for creating test instances and mock data
public enum TestUtilities {
    // MARK: - Service Creation

    /// Creates a BlueskyService with in-memory storage for testing
    @MainActor
    public static func createTestBlueskyService(session: URLSessionProtocol = MockURLSession()) -> BlueskyService {
        BlueskyService(session: session, storage: createTestStorage())
    }

    /// Creates an ATProtoAuthService with in-memory storage for testing
    @MainActor
    public static func createTestAuthService(session: URLSessionProtocol = MockURLSession()) -> ATProtoAuthService {
        let client = ATProtoClient(session: session)
        return ATProtoAuthService(client: client, storage: createTestStorage())
    }

    /// Creates in-memory credentials storage for testing
    @MainActor
    public static func createTestStorage() -> CredentialsStorageProtocol {
        InMemoryCredentialsStorage()
    }

    /// Creates a BlueskyService with custom storage for advanced testing scenarios
    @MainActor
    public static func createTestBlueskyService(
        session: URLSessionProtocol = MockURLSession(),
        storage: CredentialsStorageProtocol
    ) -> BlueskyService {
        BlueskyService(session: session, storage: storage)
    }

    /// Creates an ATProtoAuthService with custom storage for advanced testing scenarios
    @MainActor
    public static func createTestAuthService(
        session: URLSessionProtocol = MockURLSession(),
        storage: CredentialsStorageProtocol
    ) -> ATProtoAuthService {
        let client = ATProtoClient(session: session)
        return ATProtoAuthService(client: client, storage: storage)
    }
    
    /// Creates a SwiftData-based service with in-memory ModelContainer for testing
    /// This follows the pattern from Hacking with Swift for testing SwiftData code
    /// Reference: https://www.hackingwithswift.com/quick-start/swiftdata/how-to-write-unit-tests-for-your-swiftdata-code
    @MainActor
    public static func createTestBlueskyServiceWithSwiftData(session: URLSessionProtocol = MockURLSession()) throws -> BlueskyService {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: AuthCredentials.self, configurations: config)
        let storage = SwiftDataCredentialsStorage(context: container.mainContext)
        return BlueskyService(session: session, storage: storage)
    }
    
    /// Creates an in-memory ModelContainer for testing SwiftData operations
    /// This is useful for tests that need to verify SwiftData persistence behavior
    @MainActor
    public static func createTestModelContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: AuthCredentials.self, configurations: config)
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
                "sport": "climbing",
            ]
        )
    }

    /// Creates sample AuthCredentials for testing
    public static func createSampleCredentials() -> AuthCredentials {
        AuthCredentials(
            handle: "test.bsky.social",
            accessToken: "test-access-token",
            refreshToken: "test-refresh-token",
            did: "did:plc:test123",
            expiresAt: Date().addingTimeInterval(3600) // 1 hour from now
        )
    }

    /// Creates expired AuthCredentials for testing token refresh
    public static func createExpiredCredentials() -> AuthCredentials {
        AuthCredentials(
            handle: "test.bsky.social",
            accessToken: "expired-access-token",
            refreshToken: "test-refresh-token",
            did: "did:plc:test123",
            expiresAt: Date().addingTimeInterval(-3600) // 1 hour ago
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

    public func save(_ credentials: AuthCredentials) async throws {
        saveCallCount += 1
        if shouldThrowOnSave {
            throw NSError(domain: "MockStorage", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock save error"])
        }
        self.credentials = credentials
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
