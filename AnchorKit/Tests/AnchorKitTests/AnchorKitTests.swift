@testable import AnchorKit
import Foundation
import Testing

@Suite("Core Models", .tags(.unit, .models))
struct CoreModelTests {
    @Test("Place model creation and properties")
    func placeModelCreation() {
        let place = Place(
            elementType: .way,
            elementId: 123_456,
            name: "Test Climbing Gym",
            latitude: 37.7749,
            longitude: -122.4194,
            tags: ["leisure": "climbing", "name": "Test Climbing Gym"]
        )

        #expect(place.id == "way:123456")
        #expect(place.name == "Test Climbing Gym")
        #expect(place.elementType == .way)
        #expect(place.elementId == 123_456)
        #expect(place.latitude == 37.7749)
        #expect(place.longitude == -122.4194)
    }

    @Test("Place ID parsing", arguments: [
        ("way:123456", Place.ElementType.way, 123_456, true),
        ("node:789", Place.ElementType.node, 789, true),
        ("relation:42", Place.ElementType.relation, 42, true),
        ("invalid", Place.ElementType.way, 0, false),
        ("way:abc", Place.ElementType.way, 0, false),
        ("", Place.ElementType.way, 0, false)
    ])
    func placeIdParsing(input: String, expectedType: Place.ElementType, expectedId: Int, shouldSucceed: Bool) throws {
        let parsed = Place.parseId(input)

        if shouldSucceed {
            let result = try #require(parsed, "Should successfully parse '\(input)'")
            #expect(result.0 == expectedType)
            #expect(result.1 == expectedId)
        } else {
            #expect(parsed == nil, "Should fail to parse '\(input)'")
        }
    }

    @Test("AnchorConfig User-Agent is configurable")
    func anchorConfigUserAgent() {
        let userAgent = AnchorConfig.shared.userAgent
        #expect(!userAgent.isEmpty, "User-Agent should not be empty")
        #expect(userAgent.contains("Anchor"), "User-Agent should contain 'Anchor'")
        #expect(userAgent.contains("1.0"), "User-Agent should contain version number")
    }
}
