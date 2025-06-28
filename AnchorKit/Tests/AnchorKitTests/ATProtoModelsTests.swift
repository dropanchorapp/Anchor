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

    // MARK: - AnchorPDS Models Tests

    @Test("AnchorPDSCheckinRecord encodes with lexicon-compliant format")
    func anchorPDSCheckinRecord_encodesWithLexiconFormat() throws {
        // Given
        let geoLocation = CommunityGeoLocation(
            latitude: 52.0808732,
            longitude: 4.3629474
        )

        let addressLocation = CommunityAddressLocation(
            street: "123 Main St",
            locality: "Amsterdam",
            region: "NH",
            country: "NL",
            postalCode: "1000AA",
            name: "Test Venue"
        )

        let record = AnchorPDSCheckinRecord(
            text: "Test check-in",
            createdAt: "2025-01-15T12:00:00Z",
            locations: [.geo(geoLocation), .address(addressLocation)],
            category: "cafe",
            categoryGroup: "Food & Drink",
            categoryIcon: "☕"
        )

        // When
        let jsonData = try JSONEncoder().encode(record)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]

        // Then
        guard let jsonObject else {
            Issue.record("JSON object should not be nil")
            return
        }

        #expect(jsonObject["$type"] as? String == "app.dropanchor.checkin")
        #expect(jsonObject["text"] as? String == "Test check-in")
        #expect(jsonObject["createdAt"] as? String == "2025-01-15T12:00:00Z")
        #expect(jsonObject["category"] as? String == "cafe")
        #expect(jsonObject["categoryGroup"] as? String == "Food & Drink")
        #expect(jsonObject["categoryIcon"] as? String == "☕")

        guard let locations = jsonObject["locations"] as? [[String: Any]] else {
            Issue.record("Locations should be array of dictionaries")
            return
        }
        #expect(locations.count == 2)

        // Verify geo location
        let geoLocationJson = locations.first { ($0["$type"] as? String) == "community.lexicon.location.geo" }
        guard let geoLocationJson else {
            Issue.record("Should have geo location")
            return
        }
        #expect(geoLocationJson["latitude"] as? String == "52.0808732")
        #expect(geoLocationJson["longitude"] as? String == "4.3629474")

        // Verify address location
        let addressLocationJson = locations.first { ($0["$type"] as? String) == "community.lexicon.location.address" }
        guard let addressLocationJson else {
            Issue.record("Should have address location")
            return
        }
        #expect(addressLocationJson["name"] as? String == "Test Venue")
        #expect(addressLocationJson["locality"] as? String == "Amsterdam")
    }

    @Test("AnchorPDSCheckinRecord decodes from lexicon-compliant JSON")
    func anchorPDSCheckinRecord_decodesFromLexiconJSON() throws {
        // Given
        let json = """
        {
            "$type": "app.dropanchor.checkin",
            "text": "Test check-in",
            "createdAt": "2025-01-15T12:00:00Z",
            "locations": [
                {
                    "$type": "community.lexicon.location.geo",
                    "latitude": "52.0808732",
                    "longitude": "4.3629474"
                },
                {
                    "$type": "community.lexicon.location.address",
                    "street": "123 Main St",
                    "locality": "Amsterdam",
                    "name": "Test Venue"
                }
            ]
        }
        """

        // When
        let jsonData = json.data(using: .utf8)!
        let record = try JSONDecoder().decode(AnchorPDSCheckinRecord.self, from: jsonData)

        // Then
        #expect(record.text == "Test check-in")
        #expect(record.createdAt == "2025-01-15T12:00:00Z")
        #expect(record.locations?.count == 2)

        // Verify locations
        let geoLocation = record.locations?.first {
            if case .geo = $0 { return true }
            return false
        }
        #expect(geoLocation != nil)

        let addressLocation = record.locations?.first {
            if case .address = $0 { return true }
            return false
        }
        #expect(addressLocation != nil)
    }

    @Test("AnchorPDSCheckinRecord works as unified model for both creation and reading")
    func anchorPDSCheckinRecord_unifiedModel() throws {
        // Given - Create a record (as if posting)
        let originalRecord = AnchorPDSCheckinRecord(
            text: "Unified model test",
            createdAt: "2025-01-15T12:00:00Z",
            locations: [
                .geo(CommunityGeoLocation(latitude: 40.7128, longitude: -74.0060))
            ],
            category: "museum",
            categoryGroup: "Culture",
            categoryIcon: "🏛️"
        )

        // When - Encode and decode (simulating server round-trip)
        let jsonData = try JSONEncoder().encode(originalRecord)
        let decodedRecord = try JSONDecoder().decode(AnchorPDSCheckinRecord.self, from: jsonData)

        // Then - Should be identical
        #expect(decodedRecord.text == originalRecord.text)
        #expect(decodedRecord.createdAt == originalRecord.createdAt)
        #expect(decodedRecord.locations?.count == originalRecord.locations?.count)
        #expect(decodedRecord.category == originalRecord.category)
        #expect(decodedRecord.categoryGroup == originalRecord.categoryGroup)
        #expect(decodedRecord.categoryIcon == originalRecord.categoryIcon)

        // Verify the location data is preserved
        if case let .geo(originalGeo) = originalRecord.locations?.first,
           case let .geo(decodedGeo) = decodedRecord.locations?.first {
            #expect(decodedGeo.latitude == originalGeo.latitude)
            #expect(decodedGeo.longitude == originalGeo.longitude)
        } else {
            Issue.record("Location data should be preserved through encoding/decoding")
        }
    }
}
