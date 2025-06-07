import XCTest
@testable import AnchorKit

final class AnchorKitTests: XCTestCase {
    
    func testPlaceModelCreation() {
        let place = Place(
            elementType: .way,
            elementId: 123456,
            name: "Test Climbing Gym",
            latitude: 37.7749,
            longitude: -122.4194,
            tags: ["leisure": "climbing", "name": "Test Climbing Gym"]
        )
        
        XCTAssertEqual(place.id, "way:123456")
        XCTAssertEqual(place.name, "Test Climbing Gym")
        XCTAssertEqual(place.elementType, .way)
        XCTAssertEqual(place.elementId, 123456)
        XCTAssertEqual(place.latitude, 37.7749)
        XCTAssertEqual(place.longitude, -122.4194)
    }
    
    func testPlaceIdParsing() {
        let parsed = Place.parseId("way:123456")
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.0, .way)
        XCTAssertEqual(parsed?.1, 123456)
        
        // Test invalid format
        XCTAssertNil(Place.parseId("invalid"))
        XCTAssertNil(Place.parseId("way:abc"))
    }
    
    func testAuthCredentialsStorage() {
        let credentials = AuthCredentials(
            handle: "test.bsky.social",
            accessToken: "test-access-token",
            refreshToken: "test-refresh-token",
            did: "did:plc:test123",
            expiresAt: Date().addingTimeInterval(3600)
        )
        
        XCTAssertEqual(credentials.handle, "test.bsky.social")
        XCTAssertEqual(credentials.accessToken, "test-access-token")
        XCTAssertEqual(credentials.refreshToken, "test-refresh-token")
        XCTAssertEqual(credentials.did, "did:plc:test123")
        XCTAssertFalse(credentials.isExpired)
        XCTAssertTrue(credentials.isValid)
    }
    
    func testAuthCredentialsExpiration() {
        let expiredCredentials = AuthCredentials(
            handle: "test.bsky.social",
            accessToken: "test-access-token", 
            refreshToken: "test-refresh-token",
            did: "did:plc:test123",
            expiresAt: Date().addingTimeInterval(-3600) // Expired 1 hour ago
        )
        
        XCTAssertTrue(expiredCredentials.isExpired)
        XCTAssertFalse(expiredCredentials.isValid)
    }
    
    func testAnchorSettingsDefaults() {
        let settings = AnchorSettings()
        
        XCTAssertEqual(settings.defaultMessage, "")
        XCTAssertTrue(settings.includeEmoji)
        XCTAssertEqual(settings.searchRadius, 1000.0)
        XCTAssertEqual(settings.preferredCategories, ["climbing", "gym", "cafe"])
    }
} 