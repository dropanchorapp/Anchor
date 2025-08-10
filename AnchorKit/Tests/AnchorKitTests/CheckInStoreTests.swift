@testable import AnchorKit
import Foundation
import Testing

@Suite("Check-In Store", .tags(.stores))
@MainActor
struct CheckInStoreTests {
    let store: CheckInStore
    let mockAuthStore: MockAuthStore
    let mockBackendService: MockAnchorBackendService

    init() {
        mockAuthStore = MockAuthStore()
        mockBackendService = MockAnchorBackendService()

        store = CheckInStore(
            authStore: mockAuthStore,
            backendService: mockBackendService
        )
    }

    // MARK: - Check-in Tests

    @Test("Create checkin without authentication fails")
    func createCheckinWithoutAuthentication() async {
        // Given: No authentication
        mockAuthStore.shouldThrowAuthError = true
        let place = TestUtilities.createSamplePlace()

        // When/Then: Creating check-in should fail with auth error
        await #expect(throws: AuthStoreError.self) {
            try await store.createCheckin(place: place, customMessage: "Test message")
        }
    }

    @Test("Create checkin - success")
    func createCheckinSuccess() async throws {
        // Given: Authenticated user and backend will succeed
        mockBackendService.createCheckinResult = true
        let place = TestUtilities.createSamplePlace()
        let customMessage = "Great climbing session!"

        // When: Creating check-in
        let result = try await store.createCheckin(place: place, customMessage: customMessage)

        // Then: Should succeed and call backend service with correct parameters
        #expect(result, "Check-in creation should succeed")
        #expect(mockBackendService.createCheckinCallCount == 1, "Should call backend service once")
        #expect(mockBackendService.lastCreateCheckinPlace?.name == place.name, "Should pass correct place")
        #expect(mockBackendService.lastCreateCheckinMessage == customMessage, "Should pass correct message")
        #expect(mockBackendService.lastCreateCheckinSessionId == "test-session-id", "Should pass session ID from credentials")
    }

    @Test("Create checkin - backend failure")
    func createCheckinBackendFailure() async {
        // Given: Backend service will fail
        mockBackendService.shouldThrowError = true
        let place = TestUtilities.createSamplePlace()

        // When/Then: Creating check-in should fail with backend error
        await #expect(throws: NSError.self) {
            try await store.createCheckin(place: place, customMessage: "Test message")
        }
    }

    @Test("Create checkin - missing session ID fails")
    func createCheckinMissingSessionId() async {
        // Given: Credentials without session ID
        mockAuthStore.testCredentials = TestAuthCredentials(
            handle: "test.bsky.social",
            accessToken: "test-token",
            refreshToken: "test-refresh",
            did: "did:plc:test",
            pdsURL: "https://bsky.social",
            expiresAt: Date().addingTimeInterval(3600),
            sessionId: nil // No session ID
        )
        let place = TestUtilities.createSamplePlace()

        // When/Then: Creating check-in should fail with missing session ID error
        await #expect(throws: CheckInError.self) {
            try await store.createCheckin(place: place, customMessage: "Test message")
        }
    }
}