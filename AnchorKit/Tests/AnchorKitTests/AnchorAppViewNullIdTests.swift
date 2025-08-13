import Testing
import Foundation
@testable import AnchorKit

@Suite("AnchorFeed Null ID Handling")
struct AnchorFeedNullIdTests {
    
    @Test("Checkin with null id uses uri as fallback")
    func nullIdUsesUriFallback() throws {
        let json = """
        {
            "id": null,
            "uri": "at://did:plc:test/app.dropanchor.checkin/123",
            "author": {
                "did": "did:plc:test",
                "handle": "test.bsky.social"
            },
            "text": "Test checkin",
            "createdAt": "2025-08-10T14:29:35.566Z"
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let checkin = try decoder.decode(AnchorFeedCheckin.self, from: data)
        
        // Should use URI as ID when null
        #expect(checkin.id == "at://did:plc:test/app.dropanchor.checkin/123")
        #expect(checkin.uri == "at://did:plc:test/app.dropanchor.checkin/123")
    }
    
    @Test("Checkin with valid id uses provided id")
    func validIdIsUsed() throws {
        let json = """
        {
            "id": "custom-id-123",
            "uri": "at://did:plc:test/app.dropanchor.checkin/456",
            "author": {
                "did": "did:plc:test",
                "handle": "test.bsky.social"
            },
            "text": "Test checkin",
            "createdAt": "2025-08-10T14:29:35.566Z"
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let checkin = try decoder.decode(AnchorFeedCheckin.self, from: data)
        
        // Should use provided ID when not null
        #expect(checkin.id == "custom-id-123")
        #expect(checkin.uri == "at://did:plc:test/app.dropanchor.checkin/456")
    }
    
    @Test("Feed response with mixed null and valid ids decodes correctly")
    func feedResponseWithMixedIds() throws {
        let json = """
        {
            "checkins": [
                {
                    "id": null,
                    "uri": "at://did:plc:test/app.dropanchor.checkin/null-id",
                    "author": {
                        "did": "did:plc:test1",
                        "handle": "test1.bsky.social"
                    },
                    "text": "Null ID checkin",
                    "createdAt": "2025-08-10T14:29:35.566Z"
                },
                {
                    "id": "valid-id-456",
                    "uri": "at://did:plc:test/app.dropanchor.checkin/valid-id",
                    "author": {
                        "did": "did:plc:test2",
                        "handle": "test2.bsky.social"
                    },
                    "text": "Valid ID checkin",
                    "createdAt": "2025-08-10T13:29:35.566Z"
                }
            ],
            "cursor": "2025-08-10T12:14:27.145Z"
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let response = try decoder.decode(AnchorFeedResponse.self, from: data)
        
        #expect(response.checkins.count == 2)
        
        // First checkin should use uri as id
        #expect(response.checkins[0].id == "at://did:plc:test/app.dropanchor.checkin/null-id")
        #expect(response.checkins[0].uri == "at://did:plc:test/app.dropanchor.checkin/null-id")
        
        // Second checkin should use provided id
        #expect(response.checkins[1].id == "valid-id-456")
        #expect(response.checkins[1].uri == "at://did:plc:test/app.dropanchor.checkin/valid-id")
    }
}