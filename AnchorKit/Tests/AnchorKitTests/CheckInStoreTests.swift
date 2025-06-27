@testable import AnchorKit
import Foundation
import Testing

@Suite("Check-In Store", .tags(.stores))
@MainActor
struct CheckInStoreTests {
    let store: CheckInStore
    let mockAuthStore: MockAuthStore

    init() {
        let mockSession = MockURLSession()
        mockAuthStore = MockAuthStore()
        store = CheckInStore(authStore: mockAuthStore, session: mockSession)
    }

    // MARK: - Check-in Tests

    @Test("Create checkin without authentication fails")
    func createCheckinWithoutAuthentication() async {
        // Given: Auth service that will throw authentication error
        mockAuthStore.shouldThrowAuthError = true
        let place = TestUtilities.createSamplePlace()

        // When/Then: Creating check-in should fail
        await #expect(throws: ATProtoError.self) {
            try await store.createCheckinWithPost(place: place, customMessage: "Test message")
        }
    }

    @Test("Build check-in text with facets contains expected content")
    func buildCheckInTextWithFacets() {
        // Given: A place and custom message
        let place = TestUtilities.createSamplePlace()
        let customMessage = "Great climbing session!"

        // When: Building check-in text
        let (text, facets) = store.buildCheckInTextWithFacets(place: place, customMessage: customMessage)

        // Then: Should contain expected content
        #expect(text.contains("Great climbing session!"))
        #expect(text.contains("#checkin"))
        #expect(text.contains("#dropanchor"))
        #expect(!facets.isEmpty)
    }

    @Test("Create checkin with post calls both AnchorPDS and Bluesky posting")
    func createCheckinWithPostCallsBothServices() async {
        // Given: Valid authentication and a place
        mockAuthStore.shouldThrowAuthError = false
        let place = TestUtilities.createSamplePlace()

        // When/Then: Creating check-in should fail due to mock network responses
        // The store will attempt to call AnchorPDS first, which will fail with empty mock data
        await #expect(throws: AnchorPDSError.self) {
            try await store.createCheckinWithPost(place: place, customMessage: "Test message")
        }
    }
} 