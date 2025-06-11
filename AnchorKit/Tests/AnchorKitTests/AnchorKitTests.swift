import Testing
import Foundation
@testable import AnchorKit

@Suite("Core Models", .tags(.unit, .models))
struct CoreModelTests {
    
    @Test("Place model creation and properties")
    func placeModelCreation() {
        let place = Place(
            elementType: .way,
            elementId: 123456,
            name: "Test Climbing Gym",
            latitude: 37.7749,
            longitude: -122.4194,
            tags: ["leisure": "climbing", "name": "Test Climbing Gym"]
        )
        
        #expect(place.id == "way:123456")
        #expect(place.name == "Test Climbing Gym")
        #expect(place.elementType == .way)
        #expect(place.elementId == 123456)
        #expect(place.latitude == 37.7749)
        #expect(place.longitude == -122.4194)
    }
    
    @Test("Place ID parsing", arguments: [
        ("way:123456", Place.ElementType.way, 123456, true),
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
}

@Suite("Authentication Models", .tags(.unit, .models, .auth))
struct AuthenticationModelTests {
    
    @Test("Valid credentials properties")
    func authCredentialsStorage() {
        let credentials = MockAuthCredentials(
            handle: "test.bsky.social",
            accessToken: "test-access-token",
            refreshToken: "test-refresh-token",
            did: "did:plc:test123",
            expiresAt: Date().addingTimeInterval(3600)
        )
        
        #expect(credentials.handle == "test.bsky.social")
        #expect(credentials.accessToken == "test-access-token")
        #expect(credentials.refreshToken == "test-refresh-token")
        #expect(credentials.did == "did:plc:test123")
        #expect(!credentials.isExpired)
        #expect(credentials.isValid)
    }
    
    @Test("Expired credentials validation")
    func authCredentialsExpiration() {
        let expiredCredentials = MockAuthCredentials(
            handle: "test.bsky.social",
            accessToken: "test-access-token", 
            refreshToken: "test-refresh-token",
            did: "did:plc:test123",
            expiresAt: Date().addingTimeInterval(-3600)
        )
        
        #expect(expiredCredentials.isExpired)
        #expect(!expiredCredentials.isValid)
    }
}

@Suite("Settings Models", .tags(.unit, .models))
struct SettingsModelTests {
    
    @Test("Default settings values")
    func anchorSettingsDefaults() {
        let settings = AnchorSettings()
        
        #expect(settings.defaultMessage == "")
        #expect(settings.includeEmoji == true)
        #expect(settings.searchRadius == 1000.0)
        #expect(settings.preferredCategories == ["climbing", "gym", "cafe"])
    }
} 