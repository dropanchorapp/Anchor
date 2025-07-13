@testable import AnchorKit
import CoreLocation
import Foundation
import Testing

@Suite("Overpass Service", .tags(.integration, .services, .network, .location))
struct OverpassServiceTests {
    let overpassService: OverpassService

    init() {
        overpassService = OverpassService()
    }

    @Test("Simple Overpass query for nearby places")
    func simpleOverpassQuery() async throws {
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

            #expect(!places.isEmpty, "Should find at least some places near Golden Gate Bridge")

        } catch {
            print("❌ Error: \(error)")
            print("   Error type: \(type(of: error))")
            if let overpassError = error as? OverpassError {
                print("   Overpass error: \(overpassError.localizedDescription)")
            }
            throw error
        }
    }

    @Test("Updated service query with simplified queries")
    func updatedServiceQuery() async throws {
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

    @Test("Find nearby places with distance information")
    func findNearbyPlacesWithDistance() async throws {
        // Test the new findNearbyPlacesWithDistance method
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194) // San Francisco downtown

        print("🧪 Testing findNearbyPlacesWithDistance method")

        do {
            let placesWithDistance = try await overpassService.findNearbyPlacesWithDistance(
                near: coordinate,
                radiusMeters: 1000
            )

            print("✅ Successfully found \(placesWithDistance.count) places with distance")

            // Verify that places are returned with distance information
            #expect(!placesWithDistance.isEmpty, "Should find at least some places")

            // Verify that distances are calculated
            for placeWithDistance in placesWithDistance.prefix(5) {
                let place = placeWithDistance.place
                let distance = placeWithDistance.distanceMeters
                let formatted = placeWithDistance.formattedDistance

                print("   - \(place.name): \(formatted) (\(distance)m)")

                // Verify distance is positive and reasonable (within search radius + some buffer)
                #expect(distance >= 0, "Distance should be non-negative")
                #expect(distance <= 1500, "Distance should be within reasonable range")
                #expect(!formatted.isEmpty, "Formatted distance should not be empty")
            }

            // Verify places are sorted by distance (closest first)
            if placesWithDistance.count > 1 {
                let distances = placesWithDistance.map { $0.distanceMeters }
                let sortedDistances = distances.sorted()
                #expect(distances == sortedDistances, "Places should be sorted by distance")
                print("✅ Places are correctly sorted by distance")
            }

        } catch {
            print("❌ Error with findNearbyPlacesWithDistance: \(error)")
            throw error
        }
    }

    @Test("Broader query for amenities in San Francisco")
    func broaderQuery() async throws {
        // Test with a broader query to find any named place
        _ = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194) // San Francisco downtown

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

    @Test("Raw Overpass query for restaurants")
    func rawOverpassQuery() async throws {
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
