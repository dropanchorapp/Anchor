import XCTest
import CoreLocation
@testable import AnchorKit

final class OverpassServiceTests: XCTestCase {
    var overpassService: OverpassService!
    
    override func setUp() {
        super.setUp()
        overpassService = OverpassService()
    }
    
    override func tearDown() {
        overpassService = nil
        super.tearDown()
    }
    
    func testSimpleOverpassQuery() async throws {
        // Use a well-known location (Golden Gate Bridge, San Francisco)
        let coordinate = CLLocationCoordinate2D(latitude: 37.8199, longitude: -122.4783)
        
        print("🧪 Testing Overpass API with coordinate: \(coordinate)")
        
        do {
            let places = try await overpassService.findNearbyPlaces(
                near: coordinate,
                radiusMeters: 1000
            )
            
            print("✅ Successfully found \(places.count) places")
            for place in places.prefix(5) {
                print("   - \(place.name) (\(place.category ?? "unknown"))")
            }
            
            XCTAssertFalse(places.isEmpty, "Should find at least some places near Golden Gate Bridge")
            
        } catch {
            print("❌ Error: \(error)")
            print("   Error type: \(type(of: error))")
            if let overpassError = error as? OverpassError {
                print("   Overpass error: \(overpassError.localizedDescription)")
            }
            throw error
        }
    }
    
    func testUpdatedServiceQuery() async throws {
        // Test our updated simplified service queries
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194) // San Francisco downtown
        
        print("🧪 Testing updated OverpassService with simplified queries")
        
        do {
            let places = try await overpassService.findNearbyPlaces(
                near: coordinate,
                radiusMeters: 1000
            )
            
            print("✅ Successfully found \(places.count) places with updated service")
            for place in places.prefix(10) {
                print("   - \(place.name) (\(place.category ?? "unknown"))")
            }
            
        } catch {
            print("❌ Error with updated service: \(error)")
            throw error
        }
    }

    func testBroaderQuery() async throws {
        // Test with a broader query to find any named place
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194) // San Francisco downtown
        
        print("🧪 Testing broader query in San Francisco downtown")
        
        let broadQuery = """
        [out:json][timeout:15];
        (
          node["name"]["amenity"](around:500,37.7749,-122.4194);
          way["name"]["amenity"](around:500,37.7749,-122.4194);
        );
        out center tags;
        """
        
        let url = URL(string: "https://overpass.private.coffee/api/interpreter")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("Anchor/1.0 (macOS test; https://github.com/example/anchor)", forHTTPHeaderField: "User-Agent")
        
        let body = "data=\(broadQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 HTTP Status: \(httpResponse.statusCode)")
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let elements = json["elements"] as? [[String: Any]] {
            print("✅ Found \(elements.count) places with names")
            for element in elements.prefix(10) {
                if let tags = element["tags"] as? [String: String],
                   let name = tags["name"] {
                    let amenity = tags["amenity"] ?? "unknown"
                    print("   - \(name) (\(amenity))")
                }
            }
        }
    }
    
    func testRawOverpassQuery() async throws {
        // Test with a very simple Overpass query
        let simpleQuery = """
        [out:json][timeout:10];
        (
          node["amenity"="restaurant"](around:1000,37.8199,-122.4783);
        );
        out center tags;
        """
        
        print("🧪 Testing raw Overpass query:")
        print(simpleQuery)
        
        let url = URL(string: "https://overpass.private.coffee/api/interpreter")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("Anchor/1.0 (macOS test; https://github.com/example/anchor)", forHTTPHeaderField: "User-Agent")
        
        let body = "data=\(simpleQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        request.httpBody = body.data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 HTTP Status: \(httpResponse.statusCode)")
                print("📡 Headers: \(httpResponse.allHeaderFields)")
            }
            
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            print("📡 Response length: \(data.count) bytes")
            print("📡 Response preview: \(String(responseString.prefix(200)))")
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                // Try to parse JSON
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("✅ Valid JSON received")
                        if let elements = json["elements"] as? [[String: Any]] {
                            print("✅ Found \(elements.count) elements")
                        }
                    }
                } catch {
                    print("❌ Failed to parse JSON: \(error)")
                }
            } else {
                print("❌ HTTP error or non-200 status")
            }
            
        } catch {
            print("❌ Network error: \(error)")
            throw error
        }
    }
}