import CoreLocation
import Foundation

/// Service for querying place data from the Anchor backend API
/// Replaces OverpassService to centralize place discovery logic
public final class AnchorService: @unchecked Sendable {
    // MARK: - Properties
    
    private let session: URLSession
    private let baseURL: URL
    
    // MARK: - Initialization
    
    public init(
        session: URLSession = .shared,
        baseURL: URL = URL(string: "https://dropanchor.app/api")!
    ) {
        self.session = session
        self.baseURL = baseURL
    }
    
    // MARK: - Public Methods
    
    /// Find nearby places within a given radius using the Anchor backend API
    /// - Parameters:
    ///   - coordinate: Center coordinate for search
    ///   - radiusMeters: Search radius in meters (default from config)
    ///   - categories: Optional filter for specific OSM tags (e.g., ["amenity=cafe", "leisure=climbing"])
    /// - Returns: Array of nearby places
    public func findNearbyPlaces(
        near coordinate: CLLocationCoordinate2D,
        radiusMeters: Double = Double(AnchorConfig.shared.locationSearchRadius),
        categories: [String] = []
    ) async throws -> [Place] {
        let placesWithDistance = try await findNearbyPlacesWithDistance(
            near: coordinate,
            radiusMeters: radiusMeters,
            categories: categories
        )
        return placesWithDistance.map { $0.place }
    }
    
    /// Find nearby places with distance information from the Anchor backend API
    /// - Parameters:
    ///   - coordinate: Center coordinate for search
    ///   - radiusMeters: Search radius in meters (default from config)
    ///   - categories: Optional filter for specific OSM tags (e.g., ["amenity=cafe", "leisure=climbing"])
    /// - Returns: Array of nearby places with distance information, sorted by distance
    public func findNearbyPlacesWithDistance(
        near coordinate: CLLocationCoordinate2D,
        radiusMeters: Double = Double(AnchorConfig.shared.locationSearchRadius),
        categories: [String] = []
    ) async throws -> [PlaceWithDistance] {
        let request = try buildRequest(
            coordinate: coordinate,
            radiusMeters: radiusMeters,
            categories: categories
        )
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AnchorServiceError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                // Try to decode error response
                if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw AnchorServiceError.apiError(httpResponse.statusCode, errorData.error)
                } else {
                    throw AnchorServiceError.httpError(httpResponse.statusCode)
                }
            }
            
            let apiResponse = try JSONDecoder().decode(PlacesNearbyResponse.self, from: data)
            
            // Convert API response to PlaceWithDistance objects
            let placesWithDistance = apiResponse.places.map { apiPlace in
                let place = Place(
                    elementType: Place.ElementType(rawValue: apiPlace.elementType) ?? .node,
                    elementId: apiPlace.elementId,
                    name: apiPlace.name,
                    latitude: apiPlace.latitude,
                    longitude: apiPlace.longitude,
                    tags: apiPlace.tags
                )
                return PlaceWithDistance(place: place, distanceMeters: apiPlace.distanceMeters)
            }
            
            print("📍 Received \(placesWithDistance.count) places from Anchor API")
            return placesWithDistance
            
        } catch let urlError as URLError {
            throw AnchorServiceError.networkError(urlError)
        } catch let decodingError as DecodingError {
            throw AnchorServiceError.decodingError(decodingError)
        }
    }
    
    /// Find places by multiple categories using the Anchor backend API
    /// - Parameters:
    ///   - coordinate: Center coordinate for search
    ///   - radiusMeters: Search radius in meters (default from config)
    ///   - categories: Array of category filters (e.g., ["amenity=restaurant", "leisure=climbing"])
    /// - Returns: Array of places matching any of the categories
    public func findPlacesByCategories(
        near coordinate: CLLocationCoordinate2D,
        radiusMeters: Double = Double(AnchorConfig.shared.locationSearchRadius),
        categories: [String]
    ) async throws -> [Place] {
        try await findNearbyPlaces(
            near: coordinate,
            radiusMeters: radiusMeters,
            categories: categories
        )
    }
    
    /// Find places by category group using the Anchor backend API
    /// - Parameters:
    ///   - coordinate: Center coordinate for search
    ///   - radiusMeters: Search radius in meters (default from config)
    ///   - categoryGroup: The category group to search for
    /// - Returns: Array of places in the specified category group
    public func findPlacesByGroup(
        near coordinate: CLLocationCoordinate2D,
        radiusMeters: Double = Double(AnchorConfig.shared.locationSearchRadius),
        categoryGroup: PlaceCategorization.CategoryGroup
    ) async throws -> [Place] {
        let allCategories = PlaceCategorization.getAllCategories()
        let groupCategories = allCategories.filter { category in
            let parts = category.split(separator: "=")
            guard parts.count == 2 else { return false }
            let tag = String(parts[0])
            let value = String(parts[1])
            return PlaceCategorization.getCategoryGroup(for: tag, value: value) == categoryGroup
        }
        
        return try await findPlacesByCategories(
            near: coordinate,
            radiusMeters: radiusMeters,
            categories: groupCategories
        )
    }
    
    /// Get all available place categories (same as OverpassService for compatibility)
    /// - Returns: Array of all OpenStreetMap categories supported for place discovery
    public func getAllAvailableCategories() -> [String] {
        PlaceCategorization.getAllCategories()
    }
    
    /// Get prioritized categories (same as OverpassService for compatibility)
    /// - Returns: Array of high-priority categories for efficient searching
    public func getPrioritizedCategories() -> [String] {
        PlaceCategorization.getPrioritizedCategories()
    }
    
    /// Clear cache (compatibility method - backend handles caching)
    public func clearCache() {
        print("📍 Cache clearing delegated to backend API")
    }
}

// MARK: - Private Methods

private extension AnchorService {
    func buildRequest(
        coordinate: CLLocationCoordinate2D,
        radiusMeters: Double,
        categories: [String]
    ) throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent("places/nearby"), resolvingAgainstBaseURL: true)!
        
        // Build query parameters
        var queryItems = [
            URLQueryItem(name: "lat", value: String(coordinate.latitude)),
            URLQueryItem(name: "lng", value: String(coordinate.longitude)),
            URLQueryItem(name: "radius", value: String(Int(radiusMeters)))
        ]
        
        // Add categories if provided
        if !categories.isEmpty {
            queryItems.append(URLQueryItem(name: "categories", value: categories.joined(separator: ",")))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw AnchorServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(AnchorConfig.shared.userAgent, forHTTPHeaderField: "User-Agent")
        
        return request
    }
}

// MARK: - Response Models

private struct PlacesNearbyResponse: Codable {
    let places: [APIPlace]
    let totalCount: Int
    let searchRadius: Double
    let categories: [String]?
    let searchCoordinate: APICoordinate
}

private struct APIPlace: Codable {
    let id: String
    let elementType: String
    let elementId: Int64
    let name: String
    let latitude: Double
    let longitude: Double
    let tags: [String: String]
    let address: APIAddress
    let category: String?
    let categoryGroup: String?
    let icon: String
    let distanceMeters: Double
    let formattedDistance: String
}

private struct APIAddress: Codable {
    let type: String // Should be "community.lexicon.location.address"
    let name: String?
    let street: String?
    let locality: String?
    let region: String?
    let country: String?
    let postalCode: String?
    
    private enum CodingKeys: String, CodingKey {
        case type = "$type"
        case name, street, locality, region, country, postalCode
    }
}

private struct APICoordinate: Codable {
    let latitude: Double
    let longitude: Double
}

private struct ErrorResponse: Codable {
    let error: String
    let details: String?
}

// MARK: - Error Types

public enum AnchorServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case apiError(Int, String)
    case networkError(URLError)
    case decodingError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid Anchor API URL"
        case .invalidResponse:
            "Invalid response from Anchor API"
        case let .httpError(code):
            "HTTP error \(code) from Anchor API"
        case let .apiError(code, message):
            "API error \(code): \(message)"
        case let .networkError(urlError):
            "Network error: \(urlError.localizedDescription)"
        case let .decodingError(error):
            "Failed to decode Anchor API response: \(error.localizedDescription)"
        }
    }
}
