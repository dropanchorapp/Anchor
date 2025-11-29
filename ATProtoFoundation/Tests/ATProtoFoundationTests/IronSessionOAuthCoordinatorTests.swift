//
//  IronSessionOAuthCoordinatorTests.swift
//  AnchorKit
//
//  Comprehensive tests for Iron Session OAuth authentication flow
//

import Foundation
import Testing
@testable import ATProtoFoundation

// MARK: - Iron Session OAuth Coordinator Tests

@Suite("IronSessionMobileOAuthCoordinator", .tags(.unit, .oauth, .auth))
@MainActor
struct IronSessionOAuthCoordinatorTests {

    // MARK: - Start OAuth Flow Tests

    @Test("Start direct OAuth flow generates correct URL")
    func startDirectOAuthFlowGeneratesCorrectURL() async throws {
        let storage = InMemoryCredentialsStorage()
        let session = MockURLSession()
        let config = OAuthConfiguration.default
        let coordinator = IronSessionMobileOAuthCoordinator(
            credentialsStorage: storage,
            session: session,
            config: config,
            cookieManager: MockCookieManager(),
            logger: MockLogger()
        )

        let oauthURL = try await coordinator.startDirectOAuthFlow()

        #expect(oauthURL.absoluteString == "https://dropanchor.app/mobile-auth")
        #expect(oauthURL.scheme == "https")
        #expect(oauthURL.host == "dropanchor.app")
        #expect(oauthURL.path == "/mobile-auth")
    }

    @Test("Start OAuth flow uses custom configuration")
    func startOAuthFlowUsesCustomConfiguration() async throws {
        let storage = InMemoryCredentialsStorage()
        let session = MockURLSession()
        let customConfig = OAuthConfiguration(
            baseURL: URL(string: "https://test.example.com")!,
            userAgent: "TestApp/1.0",
            sessionCookieName: "test-sid",
            cookieDomain: "test.example.com",
            callbackURLScheme: "test-app",
            sessionDuration: 3600,
            refreshThreshold: 600,
            maxRetryAttempts: 2,
            maxRetryDelay: 4.0
        )
        let coordinator = IronSessionMobileOAuthCoordinator(
            credentialsStorage: storage,
            session: session,
            config: customConfig,
            cookieManager: MockCookieManager(),
            logger: MockLogger()
        )

        let oauthURL = try await coordinator.startDirectOAuthFlow()

        #expect(oauthURL.absoluteString == "https://test.example.com/mobile-auth")
    }

    // MARK: - Complete OAuth Flow Tests

    @Test("Complete OAuth flow with valid callback succeeds")
    func completeOAuthFlowWithValidCallbackSucceeds() async throws {
        let storage = InMemoryCredentialsStorage()
        let cookieManager = MockCookieManager()
        let logger = MockLogger()

        // Mock session response for validation
        let sessionJSON: [String: Any] = [
            "userHandle": "test.bsky.social",
            "did": "did:plc:test123"
        ]
        let sessionData = try JSONSerialization.data(withJSONObject: sessionJSON)
        let sessionResponse = HTTPURLResponse(
            url: URL(string: "https://dropanchor.app/api/auth/session")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        let session = MockURLSession(data: sessionData, response: sessionResponse)
        let coordinator = IronSessionMobileOAuthCoordinator(
            credentialsStorage: storage,
            session: session,
            config: .default,
            cookieManager: cookieManager,
            logger: logger
        )

        // Valid callback URL with required parameters
        let callbackURL = URL(string: "anchor-app://auth-callback?did=did:plc:test123&session_token=test-session-token-12345")!

        let credentials = try await coordinator.completeIronSessionOAuthFlow(callbackURL: callbackURL)

        // Verify credentials
        #expect(credentials.handle == "test.bsky.social")
        #expect(credentials.did == "did:plc:test123")
        #expect(credentials.sessionId == "test-session-token-12345")
        #expect(credentials.accessToken == "iron-session-backend-managed")
        #expect(credentials.refreshToken == "iron-session-backend-managed")

        // Verify cookie was saved
        #expect(cookieManager.savedCookies.count == 1)
        #expect(cookieManager.savedCookies[0].token == "test-session-token-12345")
        #expect(cookieManager.savedCookies[0].domain == "dropanchor.app")

        // Verify logging
        let logs = logger.entries(for: .oauth)
        #expect(logs.contains { $0.message.contains("Completing Iron Session OAuth flow") })
        #expect(logs.contains { $0.message.contains("Successfully parsed callback parameters") })
        #expect(logs.contains { $0.message.contains("Retrieved handle: @test.bsky.social") })
    }

    @Test("Complete OAuth flow with missing DID fails")
    func completeOAuthFlowWithMissingDIDFails() async throws {
        let storage = InMemoryCredentialsStorage()
        let session = MockURLSession()
        let coordinator = IronSessionMobileOAuthCoordinator(
            credentialsStorage: storage,
            session: session,
            config: .default,
            cookieManager: MockCookieManager(),
            logger: MockLogger()
        )

        // Callback URL missing DID parameter
        let callbackURL = URL(string: "anchor-app://auth-callback?session_token=test-session-token")!

        await #expect(throws: AuthenticationError.self) {
            try await coordinator.completeIronSessionOAuthFlow(callbackURL: callbackURL)
        }
    }

    @Test("Complete OAuth flow with missing session token fails")
    func completeOAuthFlowWithMissingSessionTokenFails() async throws {
        let storage = InMemoryCredentialsStorage()
        let session = MockURLSession()
        let logger = MockLogger()
        let coordinator = IronSessionMobileOAuthCoordinator(
            credentialsStorage: storage,
            session: session,
            config: .default,
            cookieManager: MockCookieManager(),
            logger: logger
        )

        // Callback URL missing session_token parameter
        let callbackURL = URL(string: "anchor-app://auth-callback?did=did:plc:test123")!

        await #expect(throws: AuthenticationError.self) {
            try await coordinator.completeIronSessionOAuthFlow(callbackURL: callbackURL)
        }

        // Verify error logging
        let logs = logger.entries(for: .oauth)
        #expect(logs.contains { $0.message.contains("Missing required parameters in callback") })
    }

    @Test("Complete OAuth flow with invalid callback URL fails")
    func completeOAuthFlowWithInvalidCallbackURLFails() async throws {
        let storage = InMemoryCredentialsStorage()
        let session = MockURLSession()
        let coordinator = IronSessionMobileOAuthCoordinator(
            credentialsStorage: storage,
            session: session,
            config: .default,
            cookieManager: MockCookieManager(),
            logger: MockLogger()
        )

        // Invalid callback URL with no query parameters
        let callbackURL = URL(string: "anchor-app://auth-callback")!

        await #expect(throws: AuthenticationError.self) {
            try await coordinator.completeIronSessionOAuthFlow(callbackURL: callbackURL)
        }
    }

    @Test("Complete OAuth flow with session validation failure fails")
    func completeOAuthFlowWithSessionValidationFailureFails() async throws {
        let storage = InMemoryCredentialsStorage()
        let logger = MockLogger()

        // Mock 401 Unauthorized response for session validation
        let sessionResponse = HTTPURLResponse(
            url: URL(string: "https://dropanchor.app/api/auth/session")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )!

        let session = MockURLSession(data: Data(), response: sessionResponse)
        let coordinator = IronSessionMobileOAuthCoordinator(
            credentialsStorage: storage,
            session: session,
            config: .default,
            cookieManager: MockCookieManager(),
            logger: logger
        )

        let callbackURL = URL(string: "anchor-app://auth-callback?did=did:plc:test123&session_token=test-session-token")!

        await #expect(throws: AuthenticationError.self) {
            try await coordinator.completeIronSessionOAuthFlow(callbackURL: callbackURL)
        }

        // Verify error logging
        let logs = logger.entries(for: .oauth)
        #expect(logs.contains { $0.message.contains("Session validation failed: 401") })
    }

    @Test("Complete OAuth flow with malformed session response fails")
    func completeOAuthFlowWithMalformedSessionResponseFails() async throws {
        let storage = InMemoryCredentialsStorage()

        // Mock malformed JSON response
        let malformedData = "not valid json".data(using: .utf8)!
        let sessionResponse = HTTPURLResponse(
            url: URL(string: "https://dropanchor.app/api/auth/session")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        let session = MockURLSession(data: malformedData, response: sessionResponse)
        let coordinator = IronSessionMobileOAuthCoordinator(
            credentialsStorage: storage,
            session: session,
            config: .default,
            cookieManager: MockCookieManager(),
            logger: MockLogger()
        )

        let callbackURL = URL(string: "anchor-app://auth-callback?did=did:plc:test123&session_token=test-session-token")!

        await #expect(throws: AuthenticationError.self) {
            try await coordinator.completeIronSessionOAuthFlow(callbackURL: callbackURL)
        }
    }

    @Test("Complete OAuth flow with missing handle in session response fails")
    func completeOAuthFlowWithMissingHandleInSessionResponseFails() async throws {
        let storage = InMemoryCredentialsStorage()
        let logger = MockLogger()

        // Mock session response without userHandle
        let sessionJSON: [String: Any] = [
            "did": "did:plc:test123"
        ]
        let sessionData = try JSONSerialization.data(withJSONObject: sessionJSON)
        let sessionResponse = HTTPURLResponse(
            url: URL(string: "https://dropanchor.app/api/auth/session")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        let session = MockURLSession(data: sessionData, response: sessionResponse)
        let coordinator = IronSessionMobileOAuthCoordinator(
            credentialsStorage: storage,
            session: session,
            config: .default,
            cookieManager: MockCookieManager(),
            logger: logger
        )

        let callbackURL = URL(string: "anchor-app://auth-callback?did=did:plc:test123&session_token=test-session-token")!

        await #expect(throws: AuthenticationError.self) {
            try await coordinator.completeIronSessionOAuthFlow(callbackURL: callbackURL)
        }

        // Verify error logging
        let logs = logger.entries(for: .oauth)
        #expect(logs.contains { $0.message.contains("Could not get handle from session") })
    }

    // MARK: - Refresh Session Tests

    @Test("Refresh session succeeds with valid response")
    func refreshSessionSucceedsWithValidResponse() async throws {
        let storage = InMemoryCredentialsStorage()
        let cookieManager = MockCookieManager()
        let logger = MockLogger()

        // Store initial credentials
        let initialCredentials = AuthCredentials(
            handle: "test.bsky.social",
            accessToken: "old-token",
            refreshToken: "old-refresh",
            did: "did:plc:test123",
            pdsURL: "https://bsky.social",
            expiresAt: Date().addingTimeInterval(-100), // Expired
            sessionId: "old-session-id"
        )
        try await storage.save(initialCredentials)

        // Mock refresh response
        let refreshJSON: [String: Any] = [
            "success": true,
            "payload": [
                "did": "did:plc:test123",
                "sid": "new-session-token-67890"
            ]
        ]
        let refreshData = try JSONSerialization.data(withJSONObject: refreshJSON)
        let refreshResponse = HTTPURLResponse(
            url: URL(string: "https://dropanchor.app/mobile/refresh-token")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        let session = MockURLSession(data: refreshData, response: refreshResponse)
        let coordinator = IronSessionMobileOAuthCoordinator(
            credentialsStorage: storage,
            session: session,
            config: .default,
            cookieManager: cookieManager,
            logger: logger
        )

        let refreshedCredentials = try await coordinator.refreshIronSession()

        // Verify refreshed credentials
        #expect(refreshedCredentials.handle == "test.bsky.social")
        #expect(refreshedCredentials.did == "did:plc:test123")
        #expect(refreshedCredentials.sessionId == "new-session-token-67890")
        #expect(refreshedCredentials.accessToken == "iron-session-backend-managed")

        // Verify new expiration is in the future
        #expect(refreshedCredentials.expiresAt > Date())

        // Verify new cookie was saved
        #expect(cookieManager.savedCookies.count == 1)
        #expect(cookieManager.savedCookies[0].token == "new-session-token-67890")

        // Verify logging
        let logs = logger.entries(for: .session)
        #expect(logs.contains { $0.message.contains("Refreshing Iron Session") })
        #expect(logs.contains { $0.message.contains("Session refreshed successfully") })
    }

    @Test("Refresh session fails when no current credentials")
    func refreshSessionFailsWhenNoCurrentCredentials() async throws {
        let storage = InMemoryCredentialsStorage()
        let session = MockURLSession()
        let logger = MockLogger()
        let coordinator = IronSessionMobileOAuthCoordinator(
            credentialsStorage: storage,
            session: session,
            config: .default,
            cookieManager: MockCookieManager(),
            logger: logger
        )

        await #expect(throws: AuthenticationError.sessionExpiredUnrecoverable) {
            try await coordinator.refreshIronSession()
        }

        // Verify error logging
        let logs = logger.entries(for: .session)
        #expect(logs.contains { $0.message.contains("No current session to refresh") })
    }

    @Test("Refresh session fails with 401 response")
    func refreshSessionFailsWith401Response() async throws {
        let storage = InMemoryCredentialsStorage()
        let logger = MockLogger()

        // Store expired credentials
        let credentials = AuthCredentials(
            handle: "test.bsky.social",
            accessToken: "old-token",
            refreshToken: "old-refresh",
            did: "did:plc:test123",
            pdsURL: "https://bsky.social",
            expiresAt: Date().addingTimeInterval(-100),
            sessionId: "old-session-id"
        )
        try await storage.save(credentials)

        // Mock 401 Unauthorized response
        let refreshResponse = HTTPURLResponse(
            url: URL(string: "https://dropanchor.app/mobile/refresh-token")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )!

        let session = MockURLSession(data: Data(), response: refreshResponse)
        let coordinator = IronSessionMobileOAuthCoordinator(
            credentialsStorage: storage,
            session: session,
            config: .default,
            cookieManager: MockCookieManager(),
            logger: logger
        )

        await #expect(throws: AuthenticationError.sessionExpiredUnrecoverable) {
            try await coordinator.refreshIronSession()
        }

        // Verify error logging
        let logs = logger.entries(for: .session)
        #expect(logs.contains { $0.message.contains("Session refresh failed: 401") })
    }

    @Test("Refresh session fails with malformed response")
    func refreshSessionFailsWithMalformedResponse() async throws {
        let storage = InMemoryCredentialsStorage()

        // Store credentials
        let credentials = AuthCredentials(
            handle: "test.bsky.social",
            accessToken: "old-token",
            refreshToken: "old-refresh",
            did: "did:plc:test123",
            pdsURL: "https://bsky.social",
            expiresAt: Date().addingTimeInterval(-100),
            sessionId: "old-session-id"
        )
        try await storage.save(credentials)

        // Mock malformed JSON response
        let malformedData = "not valid json".data(using: .utf8)!
        let refreshResponse = HTTPURLResponse(
            url: URL(string: "https://dropanchor.app/mobile/refresh-token")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        let session = MockURLSession(data: malformedData, response: refreshResponse)
        let coordinator = IronSessionMobileOAuthCoordinator(
            credentialsStorage: storage,
            session: session,
            config: .default,
            cookieManager: MockCookieManager(),
            logger: MockLogger()
        )

        do {
            try await coordinator.refreshIronSession()
            Issue.record("Expected error to be thrown")
        } catch let error as AuthenticationError {
            if case .networkError = error {
                // Success - expected network error for malformed JSON
            } else {
                Issue.record("Expected networkError but got \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Refresh session fails with missing session token in response")
    func refreshSessionFailsWithMissingSessionTokenInResponse() async throws {
        let storage = InMemoryCredentialsStorage()
        let logger = MockLogger()

        // Store credentials
        let credentials = AuthCredentials(
            handle: "test.bsky.social",
            accessToken: "old-token",
            refreshToken: "old-refresh",
            did: "did:plc:test123",
            pdsURL: "https://bsky.social",
            expiresAt: Date().addingTimeInterval(-100),
            sessionId: "old-session-id"
        )
        try await storage.save(credentials)

        // Mock response without session token (sid)
        let refreshJSON: [String: Any] = [
            "success": true,
            "payload": [
                "did": "did:plc:test123"
                // Missing "sid" field
            ]
        ]
        let refreshData = try JSONSerialization.data(withJSONObject: refreshJSON)
        let refreshResponse = HTTPURLResponse(
            url: URL(string: "https://dropanchor.app/mobile/refresh-token")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        let session = MockURLSession(data: refreshData, response: refreshResponse)
        let coordinator = IronSessionMobileOAuthCoordinator(
            credentialsStorage: storage,
            session: session,
            config: .default,
            cookieManager: MockCookieManager(),
            logger: logger
        )

        await #expect(throws: AuthenticationError.sessionExpiredUnrecoverable) {
            try await coordinator.refreshIronSession()
        }

        // Verify error logging
        let logs = logger.entries(for: .session)
        #expect(logs.contains { $0.message.contains("Invalid refresh response format") })
    }

    @Test("Refresh session fails with network error")
    func refreshSessionFailsWithNetworkError() async throws {
        let storage = InMemoryCredentialsStorage()
        let logger = MockLogger()

        // Store credentials
        let credentials = AuthCredentials(
            handle: "test.bsky.social",
            accessToken: "old-token",
            refreshToken: "old-refresh",
            did: "did:plc:test123",
            pdsURL: "https://bsky.social",
            expiresAt: Date().addingTimeInterval(-100),
            sessionId: "old-session-id"
        )
        try await storage.save(credentials)

        // Mock network error
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        let session = MockURLSession(data: nil, response: nil, error: networkError)
        let coordinator = IronSessionMobileOAuthCoordinator(
            credentialsStorage: storage,
            session: session,
            config: .default,
            cookieManager: MockCookieManager(),
            logger: logger
        )

        await #expect(throws: AuthenticationError.self) {
            try await coordinator.refreshIronSession()
        }

        // Verify error logging
        let logs = logger.entries(for: .session)
        #expect(logs.contains { $0.message.contains("Network error during refresh") })
    }

    // MARK: - Cookie Management Tests

    @Test("OAuth completion saves session cookie with correct parameters")
    func oAuthCompletionSavesSessionCookieWithCorrectParameters() async throws {
        let storage = InMemoryCredentialsStorage()
        let cookieManager = MockCookieManager()

        // Mock successful session response
        let sessionJSON: [String: Any] = [
            "userHandle": "test.bsky.social",
            "did": "did:plc:test123"
        ]
        let sessionData = try JSONSerialization.data(withJSONObject: sessionJSON)
        let sessionResponse = HTTPURLResponse(
            url: URL(string: "https://dropanchor.app/api/auth/session")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        let session = MockURLSession(data: sessionData, response: sessionResponse)
        let coordinator = IronSessionMobileOAuthCoordinator(
            credentialsStorage: storage,
            session: session,
            config: .default,
            cookieManager: cookieManager,
            logger: MockLogger()
        )

        let callbackURL = URL(string: "anchor-app://auth-callback?did=did:plc:test123&session_token=my-secure-token-abc123")!
        _ = try await coordinator.completeIronSessionOAuthFlow(callbackURL: callbackURL)

        // Verify cookie was saved with correct parameters
        #expect(cookieManager.savedCookies.count == 1)
        let savedCookie = cookieManager.savedCookies[0]
        #expect(savedCookie.token == "my-secure-token-abc123")
        #expect(savedCookie.domain == "dropanchor.app")
        #expect(savedCookie.expiresAt > Date()) // Future expiration
    }

    @Test("Session refresh updates cookie with new token")
    func sessionRefreshUpdatesCookieWithNewToken() async throws {
        let storage = InMemoryCredentialsStorage()
        let cookieManager = MockCookieManager()

        // Store credentials
        let credentials = AuthCredentials(
            handle: "test.bsky.social",
            accessToken: "old-token",
            refreshToken: "old-refresh",
            did: "did:plc:test123",
            pdsURL: "https://bsky.social",
            expiresAt: Date().addingTimeInterval(-100),
            sessionId: "old-session-id"
        )
        try await storage.save(credentials)

        // Mock refresh response
        let refreshJSON: [String: Any] = [
            "success": true,
            "payload": [
                "did": "did:plc:test123",
                "sid": "brand-new-session-token"
            ]
        ]
        let refreshData = try JSONSerialization.data(withJSONObject: refreshJSON)
        let refreshResponse = HTTPURLResponse(
            url: URL(string: "https://dropanchor.app/mobile/refresh-token")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        let session = MockURLSession(data: refreshData, response: refreshResponse)
        let coordinator = IronSessionMobileOAuthCoordinator(
            credentialsStorage: storage,
            session: session,
            config: .default,
            cookieManager: cookieManager,
            logger: MockLogger()
        )

        _ = try await coordinator.refreshIronSession()

        // Verify new cookie was saved
        #expect(cookieManager.savedCookies.count == 1)
        #expect(cookieManager.savedCookies[0].token == "brand-new-session-token")
    }
}
