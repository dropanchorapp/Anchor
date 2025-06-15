@testable import AnchorKit
import Foundation
import Testing

@Suite("Bluesky Service", .tags(.auth, .network))
@MainActor
struct BlueskyServiceTests {
    let service: BlueskyService

    init() {
        let mockSession = MockURLSession()
        let storage = InMemoryCredentialsStorage()
        service = BlueskyService(session: mockSession, storage: storage)
    }

    // MARK: - Authentication Tests

    @Test("Initial authentication state is unauthenticated")
    func initialAuthenticationState() async {
        // Given: A new service
        // When: Checking authentication state
        let isAuthenticated = service.isAuthenticated

        // Then: Should not be authenticated initially
        #expect(!isAuthenticated)
        #expect(service.credentials == nil)
    }

    @Test("Load stored credentials when none exist")
    func loadStoredCredentialsWhenNoneExist() async {
        // Given: No stored credentials
        // When: Loading stored credentials
        let credentials = await service.loadStoredCredentials()

        // Then: Should return nil
        #expect(credentials == nil)
        #expect(!service.isAuthenticated)
    }

    @Test("Successful authentication updates state")
    func successfulAuthentication() async throws {
        // Given: Mock successful login response
        let loginResponse = ATProtoLoginResponse(
            accessJwt: "test-access-token",
            refreshJwt: "test-refresh-token",
            handle: "test.bsky.social",
            did: "did:plc:test123"
        )

        let responseData = try JSONEncoder().encode(loginResponse)
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://bsky.social/xrpc/com.atproto.server.createSession")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        let mockSession = MockURLSession(data: responseData, response: mockResponse)
        let storage = InMemoryCredentialsStorage()
        let testService = BlueskyService(session: mockSession, storage: storage)

        // When: Authenticating
        let success = try await testService.authenticate(handle: "test.bsky.social", appPassword: "test-password")

        // Then: Should succeed and update state
        #expect(success)
        #expect(testService.isAuthenticated)
        #expect(testService.credentials != nil)
        #expect(testService.credentials?.handle == "test.bsky.social")
    }

    @Test("Authentication failure throws error")
    func authenticationFailure() async {
        // Given: Mock failed login response
        let mockSession = MockURLSession(error: ATProtoError.authenticationFailed("Invalid credentials"))
        let storage = InMemoryCredentialsStorage()
        let testService = BlueskyService(session: mockSession, storage: storage)

        // When/Then: Authentication should throw
        await #expect(throws: ATProtoError.self) {
            try await testService.authenticate(handle: "test.bsky.social", appPassword: "wrong-password")
        }
    }

    @Test("Sign out clears authentication state")
    func signOut() async throws {
        // Given: Authenticated service
        let loginResponse = ATProtoLoginResponse(
            accessJwt: "test-access-token",
            refreshJwt: "test-refresh-token",
            handle: "test.bsky.social",
            did: "did:plc:test123"
        )

        let responseData = try JSONEncoder().encode(loginResponse)
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://bsky.social/xrpc/com.atproto.server.createSession")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        let mockSession = MockURLSession(data: responseData, response: mockResponse)
        let storage = InMemoryCredentialsStorage()
        let testService = BlueskyService(session: mockSession, storage: storage)

        // Authenticate first
        _ = try await testService.authenticate(handle: "test.bsky.social", appPassword: "test-password")

        // When: Signing out
        await testService.signOut()

        // Then: Should clear authentication state
        #expect(!testService.isAuthenticated)
        #expect(testService.credentials == nil)
    }

    // MARK: - Check-in Tests

    @Test("Create checkin without authentication fails")
    func createCheckinWithoutAuthentication() async {
        // Given: Unauthenticated service
        let place = TestUtilities.createSamplePlace()

        // When/Then: Creating check-in should fail
        await #expect(throws: ATProtoError.self) {
            try await service.createCheckinWithPost(place: place, customMessage: "Test message")
        }
    }

    // MARK: - Utility Tests

    @Test("Get app password URL returns correct URL")
    func getAppPasswordURL() {
        // When: Getting app password URL
        let url = service.getAppPasswordURL()

        // Then: Should return correct URL
        #expect(url.absoluteString == "https://bsky.app/settings/app-passwords")
    }

    @Test("Build check-in text with facets contains expected content")
    func buildCheckInTextWithFacets() {
        // Given: A place and custom message
        let place = TestUtilities.createSamplePlace()
        let customMessage = "Great climbing session!"

        // When: Building check-in text
        let (text, facets) = service.buildCheckInTextWithFacets(place: place, customMessage: customMessage)

        // Then: Should contain expected content
        #expect(text.contains("Test Climbing Gym"))
        #expect(text.contains("Great climbing session!"))
        #expect(!facets.isEmpty)
    }
}
