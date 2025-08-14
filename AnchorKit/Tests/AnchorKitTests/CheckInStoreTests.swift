@testable import AnchorKit
import Foundation
import Testing

@Suite("Check-In Store", .tags(.stores))
@MainActor
struct CheckInStoreTests {
    let store: CheckInStore
    let mockAuthStore: MockAuthStore
    let mockCheckinsService: MockAnchorCheckinsService

    init() {
        mockAuthStore = MockAuthStore()
        mockCheckinsService = MockAnchorCheckinsService()

        store = CheckInStore(
            authStore: mockAuthStore,
            checkinsService: mockCheckinsService
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
        mockCheckinsService.createCheckinResult = CheckinResult(success: true, checkinId: "test-checkin-id")
        let place = TestUtilities.createSamplePlace()
        let customMessage = "Great climbing session!"

        // When: Creating check-in
        let result = try await store.createCheckin(place: place, customMessage: customMessage)

        // Then: Should succeed and call checkins service with correct parameters
        #expect(result.success, "Check-in creation should succeed")
        #expect(result.checkinId == "test-checkin-id", "Should return checkin ID")
        #expect(mockCheckinsService.createCheckinCallCount == 1, "Should call checkins service once")
        #expect(mockCheckinsService.lastCreateCheckinPlace?.name == place.name, "Should pass correct place")
        #expect(mockCheckinsService.lastCreateCheckinMessage == customMessage, "Should pass correct message")
        #expect(mockCheckinsService.lastCreateCheckinSessionId == "test-session-id", "Should pass session ID from credentials")
    }

    @Test("Create checkin - backend failure")
    func createCheckinBackendFailure() async {
        // Given: Checkins service will fail
        mockCheckinsService.shouldThrowError = true
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
