@testable import AnchorKit
import Foundation
import Testing

@Suite("AT Protocol Models", .tags(.unit, .models))
struct ATProtoModelsTests {
    // MARK: - ATProtoCreatePostRequest Tests

    @Test("ATProtoCreatePostRequest includes collection field in JSON")
    func createPostRequest_includesCollectionField() throws {
        // Given
        let postRecord = ATProtoPostRecord(
            text: "Test post",
            createdAt: "2025-01-15T12:00:00Z",
            facets: nil,
            embed: nil
        )

        let request = ATProtoCreatePostRequest(
            repo: "did:plc:test123",
            record: postRecord
        )

        // When
        let jsonData = try JSONEncoder().encode(request)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]

        // Then
        guard let jsonObject else {
            Issue.record("JSON object should not be nil")
            return
        }
        #expect(jsonObject["collection"] as? String == "app.bsky.feed.post")
        #expect(jsonObject["repo"] as? String == "did:plc:test123")
        #expect(jsonObject["record"] != nil)
    }

    @Test("ATProtoCreatePostRequest decodes collection field from JSON")
    func createPostRequest_decodesCollectionField() throws {
        // Given
        let json = """
        {
            "collection": "app.bsky.feed.post",
            "repo": "did:plc:test123",
            "record": {
                "$type": "app.bsky.feed.post",
                "text": "Test post",
                "createdAt": "2025-01-15T12:00:00Z"
            }
        }
        """

        // When
        let jsonData = json.data(using: .utf8)!
        let request = try JSONDecoder().decode(ATProtoCreatePostRequest.self, from: jsonData)

        // Then
        #expect(request.collection == "app.bsky.feed.post")
        #expect(request.repo == "did:plc:test123")
        #expect(request.record.text == "Test post")
    }
}
