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
        mockAuthStore.isAuthenticated = false
        let place = TestUtilities.createSamplePlace()

        // When/Then: Creating check-in should fail with not authenticated error
        await #expect(throws: CheckInError.notAuthenticated) {
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
        // Access token is now handled internally by Iron Session authentication
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

    @Test("Create checkin - unauthenticated user fails")
    func createCheckinUnauthenticatedUser() async {
        // Given: User is not authenticated (Iron Session manages tokens internally)
        mockAuthStore.isAuthenticated = false
        let place = TestUtilities.createSamplePlace()

        // When/Then: Creating check-in should fail with not authenticated error
        await #expect(throws: CheckInError.notAuthenticated) {
            try await store.createCheckin(place: place, customMessage: "Test message")
        }
    }
}
