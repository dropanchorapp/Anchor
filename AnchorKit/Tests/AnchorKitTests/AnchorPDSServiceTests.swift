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
        let credentials = AuthCredentials(
            handle: "test.bsky.social",
            accessToken: "test-token",
            refreshToken: "test-refresh",
            did: "did:plc:test123",
            expiresAt: Date().addingTimeInterval(3600)
        )
        
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
        let credentials = AuthCredentials(
            handle: "test.bsky.social",
            accessToken: "test-token",
            refreshToken: "test-refresh",
            did: "did:plc:test123",
            expiresAt: Date().addingTimeInterval(3600)
        )
        
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
    
    func createRecord(request: AnchorPDSCreateRecordRequest, credentials: AuthCredentials) async throws -> ATProtoCreateRecordResponse {
        lastCreateRequest = request
        return ATProtoCreateRecordResponse(uri: "at://test.did/com.anchor.checkin/test123", cid: "test-cid")
    }
    
    func listCheckins(user: String?, limit: Int, cursor: String?, credentials: AuthCredentials) async throws -> AnchorPDSFeedResponse {
        return AnchorPDSFeedResponse(checkins: [], cursor: nil)
    }
    
    func getGlobalFeed(limit: Int, cursor: String?, credentials: AuthCredentials) async throws -> AnchorPDSFeedResponse {
        return AnchorPDSFeedResponse(checkins: [], cursor: nil)
    }
} 