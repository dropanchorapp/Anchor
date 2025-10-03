import Testing
import Foundation
@testable import AnchorKit

@Suite("AnchorFeed Coordinates Decoding")
struct AnchorFeedCoordinatesTests {

    @Test("Coordinates decode from numbers")
    func coordinatesFromNumbers() throws {
        let json = """
        {
            "latitude": 52.3676,
            "longitude": 4.9041
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let coordinates = try decoder.decode(AnchorFeedCoordinates.self, from: data)

        #expect(coordinates.latitude == 52.3676)
        #expect(coordinates.longitude == 4.9041)
    }

    @Test("Coordinates decode from strings")
    func coordinatesFromStrings() throws {
        let json = """
        {
            "latitude": "52.3676",
            "longitude": "4.9041"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let coordinates = try decoder.decode(AnchorFeedCoordinates.self, from: data)

        #expect(coordinates.latitude == 52.3676)
        #expect(coordinates.longitude == 4.9041)
    }

    @Test("Checkin with string coordinates decodes correctly")
    func checkinWithStringCoordinates() throws {
        let json = """
        {
            "id": "test-123",
            "uri": "at://did:plc:test/app.dropanchor.checkin/123",
            "author": {
                "did": "did:plc:test",
                "handle": "test.bsky.social"
            },
            "text": "Test checkin",
            "createdAt": "2025-08-10T14:29:35.566Z",
            "coordinates": {
                "latitude": "52.3676",
                "longitude": "4.9041"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let checkin = try decoder.decode(AnchorFeedCheckin.self, from: data)

        #expect(checkin.coordinates?.latitude == 52.3676)
        #expect(checkin.coordinates?.longitude == 4.9041)
    }

    @Test("Checkin with number coordinates decodes correctly")
    func checkinWithNumberCoordinates() throws {
        let json = """
        {
            "id": "test-123",
            "uri": "at://did:plc:test/app.dropanchor.checkin/123",
            "author": {
                "did": "did:plc:test",
                "handle": "test.bsky.social"
            },
            "text": "Test checkin",
            "createdAt": "2025-08-10T14:29:35.566Z",
            "coordinates": {
                "latitude": 52.3676,
                "longitude": 4.9041
            }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let checkin = try decoder.decode(AnchorFeedCheckin.self, from: data)

        #expect(checkin.coordinates?.latitude == 52.3676)
        #expect(checkin.coordinates?.longitude == 4.9041)
    }

    @Test("Feed response with mixed coordinate types decodes correctly")
    func feedResponseWithMixedCoordinateTypes() throws {
        let json = """
        {
            "checkins": [
                {
                    "id": "string-coords",
                    "uri": "at://did:plc:test/app.dropanchor.checkin/1",
                    "author": {
                        "did": "did:plc:test1",
                        "handle": "test1.bsky.social"
                    },
                    "text": "String coordinates",
                    "createdAt": "2025-08-10T14:29:35.566Z",
                    "coordinates": {
                        "latitude": "52.3676",
                        "longitude": "4.9041"
                    }
                },
                {
                    "id": "number-coords",
                    "uri": "at://did:plc:test/app.dropanchor.checkin/2",
                    "author": {
                        "did": "did:plc:test2",
                        "handle": "test2.bsky.social"
                    },
                    "text": "Number coordinates",
                    "createdAt": "2025-08-10T13:29:35.566Z",
                    "coordinates": {
                        "latitude": 37.7749,
                        "longitude": -122.4194
                    }
                }
            ]
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let response = try decoder.decode(AnchorFeedResponse.self, from: data)

        #expect(response.checkins.count == 2)

        // First checkin with string coordinates
        #expect(response.checkins[0].coordinates?.latitude == 52.3676)
        #expect(response.checkins[0].coordinates?.longitude == 4.9041)

        // Second checkin with number coordinates
        #expect(response.checkins[1].coordinates?.latitude == 37.7749)
        #expect(response.checkins[1].coordinates?.longitude == -122.4194)
    }
}
