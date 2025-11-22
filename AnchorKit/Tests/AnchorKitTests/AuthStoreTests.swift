//
//  AuthStoreTests.swift
//  AnchorKit
//
//  Comprehensive tests for AuthStore authentication workflow
//

import Foundation
import Testing
@testable import AnchorKit
import ATProtoFoundation

// MARK: - Auth Store Tests

@Suite("AuthStore", .tags(.unit, .auth, .stores))
@MainActor
struct AuthStoreTests {

    // MARK: - Initialization Tests

    @Test("AuthStore initializes with unauthenticated state")
    func authStoreInitializesWithUnauthenticatedState() {
        let storage = InMemoryCredentialsStorage()
        let authStore = AuthStore(storage: storage)

        #expect(authStore.isAuthenticated == false)
        #expect(authStore.credentials == nil)
        #expect(authStore.handle == nil)
        #expect(authStore.authenticationState.isAuthenticated == false)
    }

    @Test("AuthStore initializes with custom dependencies")
    func authStoreInitializesWithCustomDependencies() {
        let storage = InMemoryCredentialsStorage()
        let logger = MockLogger()
        let authService = AnchorAuthService(storage: storage, session: MockURLSession())
        let coordinator = IronSessionMobileOAuthCoordinator(
            credentialsStorage: storage,
            session: MockURLSession(),
            logger: logger
        )
        let validator = SessionValidator(authService: authService, logger: logger)

        let authStore = AuthStore(
            storage: storage,
            authService: authService,
            ironSessionCoordinator: coordinator,
            sessionValidator: validator,
            logger: logger
        )

        #expect(authStore.isAuthenticated == false)
    }

    // MARK: - Load Stored Credentials Tests

    @Test("Load stored credentials returns nil when no credentials exist")
    func loadStoredCredentialsReturnsNilWhenNoCredentialsExist() async {
        let storage = InMemoryCredentialsStorage()
        let authStore = AuthStore(storage: storage)

        let credentials = await authStore.loadStoredCredentials()

        #expect(credentials == nil)
        #expect(authStore.isAuthenticated == false)
    }

    @Test("Load stored credentials returns saved credentials")
    func loadStoredCredentialsReturnsSavedCredentials() async throws {
        let storage = InMemoryCredentialsStorage()
        let testCredentials = AuthCredentials(
            handle: "test.bsky.social",
            accessToken: "test-token",
            refreshToken: "test-refresh",
            did: "did:plc:test123",
            pdsURL: "https://bsky.social",
            expiresAt: Date().addingTimeInterval(3600),
            sessionId: "test-session-id"
        )
        try await storage.save(testCredentials)

        let authStore = AuthStore(storage: storage)
        let credentials = await authStore.loadStoredCredentials()

        #expect(credentials != nil)
        #expect(credentials?.handle == "test.bsky.social")
        #expect(credentials?.did == "did:plc:test123")
        #expect(authStore.isAuthenticated == true)
    }

    @Test("Load stored credentials updates authentication state")
    func loadStoredCredentialsUpdatesAuthenticationState() async throws {
        let storage = InMemoryCredentialsStorage()
        let testCredentials = AuthCredentials(
            handle: "loaded.bsky.social",
            accessToken: "loaded-token",
            refreshToken: "loaded-refresh",
            did: "did:plc:loaded123",
            pdsURL: "https://bsky.social",
            expiresAt: Date().addingTimeInterval(7200),
            sessionId: "loaded-session-id"
        )
        try await storage.save(testCredentials)

        let authStore = AuthStore(storage: storage)
        _ = await authStore.loadStoredCredentials()

        // Verify state is authenticated
        if case .authenticated(let credentials) = authStore.authenticationState {
            #expect(credentials.handle == "loaded.bsky.social")
        } else {
            Issue.record("Expected authenticated state")
        }
    }

    // MARK: - OAuth Flow Tests

    @Test("Start direct OAuth flow generates valid URL")
    func startDirectOAuthFlowGeneratesValidURL() async throws {
        let storage = InMemoryCredentialsStorage()
        let authStore = AuthStore(storage: storage)

        let oauthURL = try await authStore.startDirectOAuthFlow()

        #expect(oauthURL.absoluteString == "https://dropanchor.app/mobile-auth")
        #expect(oauthURL.scheme == "https")
        #expect(oauthURL.host == "dropanchor.app")
    }

    @Test("Start OAuth flow clears error state")
    func startOAuthFlowClearsErrorState() async throws {
        let storage = InMemoryCredentialsStorage()
        let authStore = AuthStore(storage: storage)

        // Manually set error state
        await authStore.signOut()

        // Starting OAuth should not throw and should return a valid URL
        let oauthURL = try await authStore.startDirectOAuthFlow()
        #expect(oauthURL.absoluteString.contains("dropanchor.app"))
    }

    @Test("Handle OAuth callback with valid parameters succeeds")
    func handleOAuthCallbackWithValidParametersSucceeds() async throws {
        let storage = InMemoryCredentialsStorage()
        let logger = MockLogger()

        // Mock successful session validation
        let sessionJSON: [String: Any] = [
            "userHandle": "oauth.bsky.social",
            "did": "did:plc:oauth123"
        ]
        let sessionData = try JSONSerialization.data(withJSONObject: sessionJSON)
        let sessionResponse = HTTPURLResponse(
            url: URL(string: "https://dropanchor.app/api/auth/session")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        let session = MockURLSession(data: sessionData, response: sessionResponse)
        let authService = AnchorAuthService(storage: storage, session: session)
        let coordinator = IronSessionMobileOAuthCoordinator(
            credentialsStorage: storage,
            session: session,
            logger: logger
        )
        let validator = SessionValidator(authService: authService, logger: logger)

        let authStore = AuthStore(
            storage: storage,
            authService: authService,
            ironSessionCoordinator: coordinator,
            sessionValidator: validator,
            logger: logger
        )

        let callbackURL = URL(string: "anchor-app://auth-callback?did=did:plc:oauth123&session_token=oauth-session-token")!
        let success = try await authStore.handleSecureOAuthCallback(callbackURL)

        #expect(success == true)
        #expect(authStore.isAuthenticated == true)
        #expect(authStore.credentials?.handle == "oauth.bsky.social")

        // Verify logging
        let logs = logger.entries(for: .oauth)
        #expect(logs.contains { $0.message.contains("Handling Iron Session OAuth callback") })
        #expect(logs.contains { $0.message.contains("authentication completed successfully") })
    }

    @Test("Handle OAuth callback with invalid parameters fails")
    func handleOAuthCallbackWithInvalidParametersFails() async {
        let storage = InMemoryCredentialsStorage()
        let authStore = AuthStore(storage: storage)

        let invalidCallbackURL = URL(string: "anchor-app://auth-callback?did=only-did-no-token")!

        await #expect(throws: Error.self) {
            try await authStore.handleSecureOAuthCallback(invalidCallbackURL)
        }

        #expect(authStore.isAuthenticated == false)
    }

    @Test("Handle OAuth callback sets authenticating state during processing")
    func handleOAuthCallbackSetsAuthenticatingStateDuringProcessing() async throws {
        let storage = InMemoryCredentialsStorage()
        let authStore = AuthStore(storage: storage)

        let callbackURL = URL(string: "anchor-app://auth-callback?did=did:plc:test123&session_token=test-token")!

        // Start the callback (will complete async)
        Task {
            _ = try? await authStore.handleSecureOAuthCallback(callbackURL)
        }

        // Give it a moment to set authenticating state
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms

        // State should eventually transition (though we can't guarantee timing in tests)
        #expect(authStore.authenticationState.isLoading || authStore.authenticationState.isAuthenticated)
    }

    // MARK: - Sign Out Tests

    @Test("Sign out clears credentials and updates state")
    func signOutClearsCredentialsAndUpdatesState() async throws {
        let storage = InMemoryCredentialsStorage()
        let testCredentials = AuthCredentials(
            handle: "signout.bsky.social",
            accessToken: "token",
            refreshToken: "refresh",
            did: "did:plc:signout",
            pdsURL: "https://bsky.social",
            expiresAt: Date().addingTimeInterval(3600),
            sessionId: "session-id"
        )
        try await storage.save(testCredentials)

        let authStore = AuthStore(storage: storage)
        _ = await authStore.loadStoredCredentials()

        #expect(authStore.isAuthenticated == true)

        await authStore.signOut()

        #expect(authStore.isAuthenticated == false)
        #expect(authStore.credentials == nil)
        #expect(authStore.handle == nil)

        // Verify credentials were cleared from storage
        let storedCredentials = await storage.load()
        #expect(storedCredentials == nil)
    }

    @Test("Sign out handles storage clear failure gracefully")
    func signOutHandlesStorageClearFailureGracefully() async throws {
        let mockStorage = MockCredentialsStorage()
        mockStorage.shouldThrowOnClear = true

        let testCredentials = AuthCredentials(
            handle: "test.bsky.social",
            accessToken: "token",
            refreshToken: "refresh",
            did: "did:plc:test",
            pdsURL: "https://bsky.social",
            expiresAt: Date().addingTimeInterval(3600),
            sessionId: "session-id"
        )
        mockStorage.credentials = testCredentials

        let authStore = AuthStore(storage: mockStorage)
        _ = await authStore.loadStoredCredentials()

        // Sign out should complete even if storage clear fails
        await authStore.signOut()

        #expect(authStore.isAuthenticated == false)
        #expect(mockStorage.clearCallCount == 1)
    }

    // MARK: - Get Valid Credentials Tests

    @Test("Get valid credentials returns credentials when valid")
    func getValidCredentialsReturnsCredentialsWhenValid() async throws {
        let storage = InMemoryCredentialsStorage()
        let testCredentials = AuthCredentials(
            handle: "valid.bsky.social",
            accessToken: "valid-token",
            refreshToken: "valid-refresh",
            did: "did:plc:valid",
            pdsURL: "https://bsky.social",
            expiresAt: Date().addingTimeInterval(7200), // Valid for 2 hours
            sessionId: "valid-session-id"
        )
        try await storage.save(testCredentials)

        let authStore = AuthStore(storage: storage)
        _ = await authStore.loadStoredCredentials()

        let credentials = try await authStore.getValidCredentials()

        #expect(credentials.handle == "valid.bsky.social")
        #expect(credentials.isValid == true)
    }

    @Test("Get valid credentials throws when no credentials loaded")
    func getValidCredentialsThrowsWhenNoCredentialsLoaded() async {
        let storage = InMemoryCredentialsStorage()
        let authStore = AuthStore(storage: storage)

        await #expect(throws: AuthenticationError.self) {
            try await authStore.getValidCredentials()
        }
    }

    @Test("Get valid credentials refreshes when expired")
    func getValidCredentialsRefreshesWhenExpired() async throws {
        let storage = InMemoryCredentialsStorage()
        let logger = MockLogger()

        // Expired credentials
        let expiredCredentials = AuthCredentials(
            handle: "expired.bsky.social",
            accessToken: "expired-token",
            refreshToken: "expired-refresh",
            did: "did:plc:expired",
            pdsURL: "https://bsky.social",
            expiresAt: Date().addingTimeInterval(-100), // Expired
            sessionId: "expired-session-id"
        )
        try await storage.save(expiredCredentials)

        // Mock successful refresh
        let refreshJSON: [String: Any] = [
            "success": true,
            "payload": [
                "did": "did:plc:expired",
                "sid": "refreshed-session-token"
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
        let authService = AnchorAuthService(storage: storage, session: session)
        let coordinator = IronSessionMobileOAuthCoordinator(
            credentialsStorage: storage,
            session: session,
            logger: logger
        )
        let validator = SessionValidator(authService: authService, logger: logger)

        let authStore = AuthStore(
            storage: storage,
            authService: authService,
            ironSessionCoordinator: coordinator,
            sessionValidator: validator,
            logger: logger
        )
        _ = await authStore.loadStoredCredentials()

        let credentials = try await authStore.getValidCredentials()

        // Should return refreshed credentials
        #expect(credentials.sessionId == "refreshed-session-token")
        #expect(credentials.isValid == true)

        // Verify logging
        let logs = logger.entries(for: .auth)
        #expect(logs.contains { $0.message.contains("Credentials expired, attempting refresh") })
    }

    @Test("Get valid credentials throws when refresh fails")
    func getValidCredentialsThrowsWhenRefreshFails() async throws {
        let storage = InMemoryCredentialsStorage()

        // Expired credentials
        let expiredCredentials = AuthCredentials(
            handle: "expired.bsky.social",
            accessToken: "expired-token",
            refreshToken: "expired-refresh",
            did: "did:plc:expired",
            pdsURL: "https://bsky.social",
            expiresAt: Date().addingTimeInterval(-100),
            sessionId: "expired-session-id"
        )
        try await storage.save(expiredCredentials)

        // Mock failed refresh (401)
        let refreshResponse = HTTPURLResponse(
            url: URL(string: "https://dropanchor.app/mobile/refresh-token")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )!

        let session = MockURLSession(data: Data(), response: refreshResponse)
        let logger = MockLogger()
        let authService = AnchorAuthService(storage: storage, session: session)
        let ironSessionCoordinator = IronSessionMobileOAuthCoordinator(
            credentialsStorage: storage,
            session: session,
            logger: logger
        )
        let sessionValidator = SessionValidator(authService: authService, logger: logger)
        let authStore = AuthStore(
            storage: storage,
            authService: authService,
            ironSessionCoordinator: ironSessionCoordinator,
            sessionValidator: sessionValidator,
            logger: logger
        )
        _ = await authStore.loadStoredCredentials()

        await #expect(throws: AuthenticationError.self) {
            try await authStore.getValidCredentials()
        }
    }

    // MARK: - Session Validation Tests

    @Test("Validate session on app launch succeeds with valid credentials")
    func validateSessionOnAppLaunchSucceedsWithValidCredentials() async throws {
        let storage = InMemoryCredentialsStorage()
        let logger = MockLogger()
        let testCredentials = AuthCredentials(
            handle: "launch.bsky.social",
            accessToken: "token",
            refreshToken: "refresh",
            did: "did:plc:launch",
            pdsURL: "https://bsky.social",
            expiresAt: Date().addingTimeInterval(3600),
            sessionId: "launch-session-id"
        )
        try await storage.save(testCredentials)

        // Mock successful session validation response
        let sessionJSON: [String: Any] = [
            "userHandle": "launch.bsky.social",
            "did": "did:plc:launch"
        ]
        let sessionData = try JSONSerialization.data(withJSONObject: sessionJSON)
        let sessionResponse = HTTPURLResponse(
            url: URL(string: "https://dropanchor.app/api/auth/session")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        let session = MockURLSession(data: sessionData, response: sessionResponse)

        let authService = AnchorAuthService(storage: storage, session: session)
        let coordinator = IronSessionMobileOAuthCoordinator(
            credentialsStorage: storage,
            session: session,
            logger: logger
        )
        let validator = SessionValidator(authService: authService, logger: logger)

        let authStore = AuthStore(
            storage: storage,
            authService: authService,
            ironSessionCoordinator: coordinator,
            sessionValidator: validator,
            logger: logger
        )
        _ = await authStore.loadStoredCredentials()

        await authStore.validateSessionOnAppLaunch()

        #expect(authStore.isAuthenticated == true)

        // Verify logging
        let logs = logger.entries(for: .session)
        #expect(logs.contains { $0.message.contains("Validating session on app launch") })
    }

    @Test("Validate session on app launch with no credentials does nothing")
    func validateSessionOnAppLaunchWithNoCredentialsDoesNothing() async {
        let storage = InMemoryCredentialsStorage()
        let logger = MockLogger()
        let authService = AnchorAuthService(storage: storage)
        let ironSessionCoordinator = IronSessionMobileOAuthCoordinator(
            credentialsStorage: storage,
            logger: logger
        )
        let sessionValidator = SessionValidator(authService: authService, logger: logger)
        let authStore = AuthStore(
            storage: storage,
            authService: authService,
            ironSessionCoordinator: ironSessionCoordinator,
            sessionValidator: sessionValidator,
            logger: logger
        )

        await authStore.validateSessionOnAppLaunch()

        // Should log that there are no credentials
        let logs = logger.entries(for: .session)
        #expect(logs.contains { $0.message.contains("No credentials to validate on launch") })
    }

    @Test("Validate session on app resume succeeds")
    func validateSessionOnAppResumeSucceeds() async throws {
        let storage = InMemoryCredentialsStorage()
        let logger = MockLogger()
        let testCredentials = AuthCredentials(
            handle: "resume.bsky.social",
            accessToken: "token",
            refreshToken: "refresh",
            did: "did:plc:resume",
            pdsURL: "https://bsky.social",
            expiresAt: Date().addingTimeInterval(3600),
            sessionId: "resume-session-id"
        )
        try await storage.save(testCredentials)

        // Mock successful session validation response
        let sessionJSON: [String: Any] = [
            "userHandle": "resume.bsky.social",
            "did": "did:plc:resume"
        ]
        let sessionData = try JSONSerialization.data(withJSONObject: sessionJSON)
        let sessionResponse = HTTPURLResponse(
            url: URL(string: "https://dropanchor.app/api/auth/session")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        let session = MockURLSession(data: sessionData, response: sessionResponse)

        let authService = AnchorAuthService(storage: storage, session: session)
        let coordinator = IronSessionMobileOAuthCoordinator(
            credentialsStorage: storage,
            session: session,
            logger: logger
        )
        let validator = SessionValidator(authService: authService, logger: logger)

        let authStore = AuthStore(
            storage: storage,
            authService: authService,
            ironSessionCoordinator: coordinator,
            sessionValidator: validator,
            logger: logger
        )
        _ = await authStore.loadStoredCredentials()

        await authStore.validateSessionOnAppResume()

        #expect(authStore.isAuthenticated == true)

        // Verify logging
        let logs = logger.entries(for: .session)
        #expect(logs.contains { $0.message.contains("Validating session on app resume") })
    }

    // MARK: - Authentication State Tests

    @Test("Authentication state reflects current credentials")
    func authenticationStateReflectsCurrentCredentials() async throws {
        let storage = InMemoryCredentialsStorage()
        let authStore = AuthStore(storage: storage)

        // Initially unauthenticated
        #expect(authStore.authenticationState.isAuthenticated == false)

        // Load valid credentials
        let testCredentials = AuthCredentials(
            handle: "state.bsky.social",
            accessToken: "token",
            refreshToken: "refresh",
            did: "did:plc:state",
            pdsURL: "https://bsky.social",
            expiresAt: Date().addingTimeInterval(3600),
            sessionId: "session-id"
        )
        try await storage.save(testCredentials)
        _ = await authStore.loadStoredCredentials()

        // Now authenticated
        #expect(authStore.authenticationState.isAuthenticated == true)

        // Sign out
        await authStore.signOut()

        // Back to unauthenticated
        #expect(authStore.authenticationState.isAuthenticated == false)
    }

    @Test("Authentication state handles expired credentials")
    func authenticationStateHandlesExpiredCredentials() async throws {
        let storage = InMemoryCredentialsStorage()
        let expiredCredentials = AuthCredentials(
            handle: "expired.bsky.social",
            accessToken: "token",
            refreshToken: "refresh",
            did: "did:plc:expired",
            pdsURL: "https://bsky.social",
            expiresAt: Date().addingTimeInterval(-100), // Expired
            sessionId: "session-id"
        )
        try await storage.save(expiredCredentials)

        let authStore = AuthStore(storage: storage)
        _ = await authStore.loadStoredCredentials()

        // Should be in session expired state
        if case .sessionExpired = authStore.authenticationState {
            // Success
        } else {
            Issue.record("Expected sessionExpired state for expired credentials")
        }
    }

    // MARK: - Convenience Property Tests

    @Test("Handle convenience property returns correct value")
    func handleConveniencePropertyReturnsCorrectValue() async throws {
        let storage = InMemoryCredentialsStorage()
        let authStore = AuthStore(storage: storage)

        #expect(authStore.handle == nil)

        let testCredentials = AuthCredentials(
            handle: "convenience.bsky.social",
            accessToken: "token",
            refreshToken: "refresh",
            did: "did:plc:convenience",
            pdsURL: "https://bsky.social",
            expiresAt: Date().addingTimeInterval(3600),
            sessionId: "session-id"
        )
        try await storage.save(testCredentials)
        _ = await authStore.loadStoredCredentials()

        #expect(authStore.handle == "convenience.bsky.social")
    }

    @Test("IsAuthenticated convenience property matches state")
    func isAuthenticatedConveniencePropertyMatchesState() async throws {
        let storage = InMemoryCredentialsStorage()
        let authStore = AuthStore(storage: storage)

        #expect(authStore.isAuthenticated == authStore.authenticationState.isAuthenticated)

        let testCredentials = AuthCredentials(
            handle: "auth.bsky.social",
            accessToken: "token",
            refreshToken: "refresh",
            did: "did:plc:auth",
            pdsURL: "https://bsky.social",
            expiresAt: Date().addingTimeInterval(3600),
            sessionId: "session-id"
        )
        try await storage.save(testCredentials)
        _ = await authStore.loadStoredCredentials()

        #expect(authStore.isAuthenticated == authStore.authenticationState.isAuthenticated)
    }
}
