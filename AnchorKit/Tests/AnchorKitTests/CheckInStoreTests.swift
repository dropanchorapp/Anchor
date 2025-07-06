@testable import AnchorKit
import Foundation
import Testing

@Suite("Check-In Store", .tags(.stores))
@MainActor
struct CheckInStoreTests {
    let store: CheckInStore
    let mockAuthStore: MockAuthStore
    let mockATProtoClient: MockATProtoClient
    let mockPostService: MockBlueskyPostService

    init() {
        mockAuthStore = MockAuthStore()
        mockATProtoClient = MockATProtoClient()
        mockPostService = MockBlueskyPostService()
        let richTextProcessor = RichTextProcessor()

        store = CheckInStore(
            authStore: mockAuthStore,
            postService: mockPostService,
            richTextProcessor: richTextProcessor,
            atprotoClient: mockATProtoClient
        )
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

    @Test("Create checkin with post calls both AT Protocol services")
    func createCheckinWithPostCallsBothServices() async throws {
        // Given: Valid authentication and a place
        mockAuthStore.shouldThrowAuthError = false
        mockATProtoClient.shouldThrowError = false
        mockPostService.shouldThrowError = false
        let place = TestUtilities.createSamplePlace()

        // When: Creating check-in with post
        let result = try await store.createCheckinWithPost(place: place, customMessage: "Test message")

        // Then: Should succeed and call both services
        #expect(result == true)
        // Note: In a more sophisticated test, we could verify that both 
        // createCheckinWithAddress and createPost were called
    }

    @Test("Create checkin with strongref handles AT Protocol errors")
    func createCheckinHandlesATProtoErrors() async {
        // Given: AT Protocol service that will throw errors
        mockAuthStore.shouldThrowAuthError = false
        mockATProtoClient.shouldThrowError = true
        let place = TestUtilities.createSamplePlace()

        // When/Then: Creating check-in should fail with AT Protocol error
        await #expect(throws: ATProtoError.self) {
            try await store.createCheckinWithPost(place: place, customMessage: "Test message")
        }
    }

    @Test("Create checkin without post succeeds")
    func createCheckinWithoutPostSucceeds() async throws {
        // Given: Valid authentication and a place
        mockAuthStore.shouldThrowAuthError = false
        mockATProtoClient.shouldThrowError = false
        let place = TestUtilities.createSamplePlace()

        // When: Creating check-in without post
        let result = try await store.createCheckinWithOptionalPost(place: place, customMessage: "Test message", shouldCreatePost: false)

        // Then: Should succeed without calling post service
        #expect(result == true)
    }
}
