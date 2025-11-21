//
//  SessionValidatorTests.swift
//  AnchorKit
//
//  Tests for SessionValidator
//

import Foundation
import Testing
@testable import AnchorKit
import ATProtoFoundation

// MARK: - Mock Auth Service for Testing

@MainActor
final class MockAnchorAuthService: AnchorAuthServiceProtocol {
    var shouldFailValidation = false
    var shouldFailRefresh = false
    var validateCallCount = 0
    var refreshCallCount = 0

    func validateSession(_ credentials: AuthCredentials) async throws -> AuthCredentials {
        validateCallCount += 1
        if shouldFailValidation {
            throw AuthenticationError.invalidCredentials("Validation failed")
        }
        return credentials
    }

    func refreshTokens(_ credentials: AuthCredentials) async throws -> AuthCredentials {
        refreshCallCount += 1
        if shouldFailRefresh {
            throw AuthenticationError.sessionExpiredUnrecoverable
        }
        // Return new credentials with extended expiration
        return AuthCredentials(
            handle: credentials.handle,
            accessToken: "refreshed-token",
            refreshToken: "new-refresh-token",
            did: credentials.did,
            pdsURL: credentials.pdsURL,
            expiresAt: Date().addingTimeInterval(3600),
            sessionId: credentials.sessionId
        )
    }

    func shouldRefreshTokens(_ credentials: AuthCredentials) -> Bool {
        return credentials.expiresAt < Date().addingTimeInterval(3600)
    }
}

// MARK: - SessionValidator Tests

@Suite("SessionValidator", .tags(.unit, .session, .auth))
@MainActor
struct SessionValidatorTests {

    // Helper to create test credentials
    private func makeTestCredentials() -> AuthCredentials {
        AuthCredentials(
            handle: "test.bsky.social",
            accessToken: "test-token",
            refreshToken: "test-refresh",
            did: "did:plc:test123",
            pdsURL: "https://test.pds.example",
            expiresAt: Date().addingTimeInterval(7200),
            sessionId: "session-123"
        )
    }

    @Test("Validates session successfully")
    func validatesSessionSuccessfully() async {
        let mockAuthService = MockAnchorAuthService()
        let logger = MockLogger()
        let validator = SessionValidator(authService: mockAuthService, logger: logger)

        let credentials = makeTestCredentials()
        var stateChanges: [SessionValidationState] = []

        let result = await validator.validateSession(credentials, reason: "test") { state in
            stateChanges.append(state)
        }

        #expect(result != nil)
        #expect(result?.handle == credentials.handle)
        #expect(mockAuthService.validateCallCount == 1)
        #expect(stateChanges.isEmpty) // No state changes on success

        // Check logging
        let logs = logger.entries(for: .session)
        #expect(logs.contains { $0.message.contains("Validating session") })
        #expect(logs.contains { $0.message.contains("validation successful") })
    }

    @Test("Falls back to refresh when validation fails")
    func fallsBackToRefreshWhenValidationFails() async {
        let mockAuthService = MockAnchorAuthService()
        mockAuthService.shouldFailValidation = true
        let logger = MockLogger()
        let validator = SessionValidator(authService: mockAuthService, logger: logger)

        let credentials = makeTestCredentials()
        var stateChanges: [SessionValidationState] = []

        let result = await validator.validateSession(credentials, reason: "test") { state in
            stateChanges.append(state)
        }

        #expect(result != nil)
        #expect(mockAuthService.validateCallCount == 1)
        #expect(mockAuthService.refreshCallCount == 1)
        #expect(stateChanges.count == 1)

        // Should have called refreshing state
        if case .refreshing = stateChanges[0] {
            // Success
        } else {
            Issue.record("Expected refreshing state")
        }

        // Check logging
        let logs = logger.entries(for: .session)
        #expect(logs.contains { $0.message.contains("validation failed") })
        #expect(logs.contains { $0.message.contains("Attempting token refresh") })
    }

    @Test("Returns nil when both validation and refresh fail")
    func returnsNilWhenBothFail() async {
        let mockAuthService = MockAnchorAuthService()
        mockAuthService.shouldFailValidation = true
        mockAuthService.shouldFailRefresh = true
        let logger = MockLogger()
        let validator = SessionValidator(authService: mockAuthService, logger: logger)

        let credentials = makeTestCredentials()
        var stateChanges: [SessionValidationState] = []

        let result = await validator.validateSession(credentials, reason: "test") { state in
            stateChanges.append(state)
        }

        #expect(result == nil)
        #expect(mockAuthService.validateCallCount == 1)
        #expect(mockAuthService.refreshCallCount == 1)
        #expect(stateChanges.count == 2)

        // Should have refreshing and refreshFailed states
        if case .refreshing = stateChanges[0] {
            // Success
        } else {
            Issue.record("Expected refreshing state")
        }

        if case .refreshFailed = stateChanges[1] {
            // Success
        } else {
            Issue.record("Expected refreshFailed state")
        }
    }

    @Test("Refreshes credentials successfully")
    func refreshesCredentialsSuccessfully() async throws {
        let mockAuthService = MockAnchorAuthService()
        let logger = MockLogger()
        let validator = SessionValidator(authService: mockAuthService, logger: logger)

        let credentials = makeTestCredentials()
        var stateChanges: [SessionValidationState] = []

        let result = try await validator.refreshCredentials(credentials) { state in
            stateChanges.append(state)
        }

        #expect(result.accessToken == "refreshed-token")
        #expect(mockAuthService.refreshCallCount == 1)
        #expect(stateChanges.count == 1)

        if case .refreshing = stateChanges[0] {
            // Success
        } else {
            Issue.record("Expected refreshing state")
        }

        // Check logging
        let logs = logger.entries(for: .session)
        #expect(logs.contains { $0.message.contains("Refreshing expired credentials") })
        #expect(logs.contains { $0.message.contains("Credentials refreshed successfully") })
    }

    @Test("Throws when refresh fails")
    func throwsWhenRefreshFails() async {
        let mockAuthService = MockAnchorAuthService()
        mockAuthService.shouldFailRefresh = true
        let logger = MockLogger()
        let validator = SessionValidator(authService: mockAuthService, logger: logger)

        let credentials = makeTestCredentials()
        var stateChanges: [SessionValidationState] = []
        var didThrow = false

        do {
            _ = try await validator.refreshCredentials(credentials) { state in
                stateChanges.append(state)
            }
        } catch {
            didThrow = true
        }

        #expect(didThrow)
        #expect(mockAuthService.refreshCallCount == 1)
        #expect(stateChanges.count == 2)

        if case .refreshing = stateChanges[0] {
            // Success
        } else {
            Issue.record("Expected refreshing state")
        }

        if case .refreshFailed = stateChanges[1] {
            // Success
        } else {
            Issue.record("Expected refreshFailed state")
        }

        // Check logging
        let logs = logger.entries(for: .session)
        #expect(logs.contains { $0.message.contains("Failed to refresh credentials") })
    }

    @Test("State change callbacks are called on MainActor")
    func stateChangeCallbacksOnMainActor() async {
        let mockAuthService = MockAnchorAuthService()
        let validator = SessionValidator(authService: mockAuthService, logger: MockLogger())

        let credentials = makeTestCredentials()
        var callbackWasOnMainActor = false

        _ = try? await validator.refreshCredentials(credentials) { state in
            // This callback should be on MainActor
            callbackWasOnMainActor = Thread.isMainThread
        }

        #expect(callbackWasOnMainActor)
    }
}
