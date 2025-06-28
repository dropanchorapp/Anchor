import Testing
import Foundation
@testable import AnchorKit

@Suite("AnchorPDS Service Tests")
struct AnchorPDSServiceTests {

    @Test("Check-in record contains only user's original message")
    @MainActor
    func testCheckinRecordOnlyContainsUserMessage() async throws {
        // Given: Mock client and service
        let mockClient = MockAnchorPDSClient()
        let service = AnchorPDSService(client: mockClient)

        let place = TestUtilities.createSamplePlace()
        let customMessage = "Great climbing session today!"
        let credentials = TestAuthCredentials.valid()

        // When: Creating a check-in
        _ = try await service.createCheckin(
            place: place,
            customMessage: customMessage,
            credentials: credentials
        )

        // Then: The record should only contain the user's message
        let capturedRequest = try #require(mockClient.lastCreateRequest)
        let checkinRecord = capturedRequest.record

        #expect(checkinRecord.text == customMessage)
        #expect(!checkinRecord.text.contains("at Test Climbing Gym"))
        #expect(!checkinRecord.text.contains("#checkin"))
        #expect(!checkinRecord.text.contains("#dropanchor"))
    }

    @Test("Check-in record with empty message stores empty string")
    @MainActor
    func testCheckinRecordWithEmptyMessage() async throws {
        // Given: Mock client and service
        let mockClient = MockAnchorPDSClient()
        let service = AnchorPDSService(client: mockClient)

        let place = TestUtilities.createSamplePlace()
        let credentials = TestAuthCredentials.valid()

        // When: Creating a check-in with no message
        _ = try await service.createCheckin(
            place: place,
            customMessage: nil,
            credentials: credentials
        )

        // Then: The record should have empty text
        let capturedRequest = try #require(mockClient.lastCreateRequest)
        let checkinRecord = capturedRequest.record

        #expect(checkinRecord.text == "")
    }
}

// MARK: - Mock AnchorPDS Client

@MainActor
class MockAnchorPDSClient: AnchorPDSClientProtocol {
    var lastCreateRequest: AnchorPDSCreateRecordRequest?

    func createRecord(request: AnchorPDSCreateRecordRequest, credentials: AuthCredentialsProtocol) async throws -> ATProtoCreateRecordResponse {
        lastCreateRequest = request
        return ATProtoCreateRecordResponse(uri: "at://test.did/com.anchor.checkin/test123", cid: "test-cid")
    }

    func listCheckins(user: String?, limit: Int, cursor: String?, credentials: AuthCredentialsProtocol) async throws -> AnchorPDSFeedResponse {
        return AnchorPDSFeedResponse(checkins: [], cursor: nil)
    }

    func getGlobalFeed(limit: Int, cursor: String?, credentials: AuthCredentialsProtocol) async throws -> AnchorPDSFeedResponse {
        return AnchorPDSFeedResponse(checkins: [], cursor: nil)
    }
}

// MARK: - Mock Implementation for Testing

/// Mock credentials implementation that doesn't require SwiftData ModelContainer
private struct MockCredentialsForTests: AuthCredentialsProtocol {
    let handle: String
    let accessToken: String
    let refreshToken: String
    let did: String
    let pdsURL: String
    let expiresAt: Date

    var isExpired: Bool {
        expiresAt.timeIntervalSinceNow < 300 // 5 minutes buffer
    }

    var isValid: Bool {
        !handle.isEmpty && !accessToken.isEmpty && !did.isEmpty && !isExpired
    }
}
