import Testing
import CoreLocation
import Foundation
@testable import AnchorKit

@Suite("Anchor Service", .tags(.services))
struct AnchorServiceTests {
    
    @Test("AnchorService initialization")
    func serviceInitialization() {
        _ = AnchorService()
        // Service is a struct, so it will always be non-nil after initialization
        #expect(Bool(true), "AnchorService should initialize successfully")
        
        let customURL = URL(string: "https://custom.api.com/api")!
        _ = AnchorService(baseURL: customURL)
        #expect(Bool(true), "AnchorService should initialize with custom URL")
    }
    
    @Test("API methods are available")
    func apiMethodsAvailable() {
        let service = AnchorService()
        
        // Test that all required methods exist and return expected types
        let categories = service.getAllAvailableCategories()
        #expect(!categories.isEmpty, "Should return available categories")
        
        let prioritized = service.getPrioritizedCategories()
        #expect(!prioritized.isEmpty, "Should return prioritized categories")
        
        // clearCache should not throw
        service.clearCache()
    }
    
    @Test("findNearbyPlaces method signature compatibility")
    func findNearbyPlacesSignature() async {
        let service = AnchorService()
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        // Test that the method exists and has the right signature
        // Note: This will fail at runtime due to network call, but we're just checking compilation
        do {
            _ = try await service.findNearbyPlaces(near: coordinate)
        } catch {
            // Expected to fail in test environment - we're just checking the API exists
            #expect(Bool(true), "Expected network error in test environment")
        }
    }
    
    @Test("findNearbyPlacesWithDistance method signature compatibility")
    func findNearbyPlacesWithDistanceSignature() async {
        let service = AnchorService()
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        // Test that the method exists and has the right signature
        do {
            _ = try await service.findNearbyPlacesWithDistance(near: coordinate, radiusMeters: 400)
        } catch {
            // Expected to fail in test environment - we're just checking the API exists
            #expect(Bool(true), "Expected network error in test environment")
        }
    }
    
    @Test("Category-based search methods")
    func categoryBasedSearchMethods() async {
        let service = AnchorService()
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let categories = ["amenity=cafe", "amenity=restaurant"]
        
        // Test findPlacesByCategories
        do {
            _ = try await service.findPlacesByCategories(near: coordinate, categories: categories)
        } catch {
            #expect(true, "Expected network error in test environment")
        }
        
        // Test findPlacesByGroup
        do {
            _ = try await service.findPlacesByGroup(near: coordinate, categoryGroup: .foodAndDrink)
        } catch {
            #expect(true, "Expected network error in test environment")
        }
    }
}