import Foundation
import CoreLocation

/// Service for querying OpenStreetMap data via Overpass API
public final class OverpassService: @unchecked Sendable {
    
    // MARK: - Properties
    
    private let session: URLSession
    private let baseURL = "https://overpass.private.coffee/api/interpreter"
    
    // MARK: - Caching
    
    private struct CachedPlaces {
        let places: [Place]
        let coordinate: CLLocationCoordinate2D
        let radiusMeters: Double
        let categories: [String]
        let timestamp: Date
    }
    
    private let cacheQueue = DispatchQueue(label: "overpass.cache", attributes: .concurrent)
    private var _placesCache: [String: CachedPlaces] = [:]
    private let cacheValidDuration: TimeInterval = 300 // 5 minutes
    private let locationToleranceMeters: Double = 100 // 100 meters
    
    private var placesCache: [String: CachedPlaces] {
        get {
            cacheQueue.sync { _placesCache }
        }
        set {
            cacheQueue.async(flags: .barrier) { [weak self] in
                self?._placesCache = newValue
            }
        }
    }
    
    private func getCachedPlaces(for key: String) -> CachedPlaces? {
        cacheQueue.sync { _placesCache[key] }
    }
    
    private func setCachedPlaces(_ places: CachedPlaces, for key: String) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?._placesCache[key] = places
        }
    }
    
    private func removeExpiredCacheEntries(_ keys: [String]) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            for key in keys {
                self?._placesCache.removeValue(forKey: key)
            }
        }
    }
    
    private func clearAllCache() {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?._placesCache.removeAll()
        }
    }
    
    // MARK: - Initialization
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - Public Methods
    
    /// Find nearby places within a given radius
    /// - Parameters:
    ///   - coordinate: Center coordinate for search
    ///   - radiusMeters: Search radius in meters (default: 1000)
    ///   - categories: Optional filter for specific OSM tags (e.g., ["leisure=climbing"])
    /// - Returns: Array of nearby places
    public func findNearbyPlaces(
        near coordinate: CLLocationCoordinate2D,
        radiusMeters: Double = 1000,
        categories: [String] = []
    ) async throws -> [Place] {
        
        // Cleanup expired cache entries occasionally
        cleanupExpiredCache()
        
        // Create cache key based on rounded coordinates and search parameters
        let cacheKey = createCacheKey(
            coordinate: coordinate,
            radiusMeters: radiusMeters,
            categories: categories
        )
        
        // Check if we have valid cached results
        if let cached = getCachedPlaces(for: cacheKey),
           isCacheValid(cached: cached, coordinate: coordinate) {
            let cacheAge = Int(Date().timeIntervalSince(cached.timestamp))
            print("📍 Using cached places for location (\(cached.places.count) places, age: \(cacheAge)s)")
            return cached.places
        }
        
        print("📍 Cache miss - fetching fresh places from Overpass API (key: \(cacheKey))")
        
        let query = buildOverpassQuery(
            coordinate: coordinate,
            radiusMeters: radiusMeters,
            categories: categories
        )
        
        let request = try buildRequest(query: query)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OverpassError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw OverpassError.httpError(httpResponse.statusCode)
            }
            
            let overpassResponse = try JSONDecoder().decode(OverpassResponse.self, from: data)
            let places = overpassResponse.elements.compactMap { element in
                parseElement(element)
            }
            
            // Cache the results
            let cachedPlaces = CachedPlaces(
                places: places,
                coordinate: coordinate,
                radiusMeters: radiusMeters,
                categories: categories,
                timestamp: Date()
            )
            setCachedPlaces(cachedPlaces, for: cacheKey)
            
            print("📍 Cached \(places.count) places for location")
            return places
            
        } catch let urlError as URLError {
            throw OverpassError.networkError(urlError)
        } catch let decodingError as DecodingError {
            throw OverpassError.decodingError(decodingError)
        }
    }
    
    /// Find climbing-specific places nearby
    /// - Parameters:
    ///   - coordinate: Center coordinate for search
    ///   - radiusMeters: Search radius in meters (default: 2000)
    /// - Returns: Array of climbing places
    public func findClimbingPlaces(
        near coordinate: CLLocationCoordinate2D,
        radiusMeters: Double = 2000
    ) async throws -> [Place] {
        return try await findNearbyPlaces(
            near: coordinate,
            radiusMeters: radiusMeters,
            categories: ["leisure=climbing", "sport=climbing"]
        )
    }
    
    /// Find places by multiple categories
    /// - Parameters:
    ///   - coordinate: Center coordinate for search
    ///   - radiusMeters: Search radius in meters (default: 1000)
    ///   - categories: Array of category filters (e.g., ["amenity=restaurant", "leisure=climbing"])
    /// - Returns: Array of places matching any of the categories
    public func findPlacesByCategories(
        near coordinate: CLLocationCoordinate2D,
        radiusMeters: Double = 1000,
        categories: [String]
    ) async throws -> [Place] {
        return try await findNearbyPlaces(
            near: coordinate,
            radiusMeters: radiusMeters,
            categories: categories
        )
    }
    
    /// Clear all cached places data
    public func clearCache() {
        clearAllCache()
        print("📍 Cleared all cached places")
    }
}

// MARK: - Private Methods

private extension OverpassService {
    
    /// Create a cache key based on rounded coordinates and search parameters
    /// Rounds coordinates to ~100 meter precision (3 decimal places ≈ 111m)
    func createCacheKey(
        coordinate: CLLocationCoordinate2D,
        radiusMeters: Double,
        categories: [String]
    ) -> String {
        // Round to 3 decimal places for ~100 meter precision
        let roundedLat = (coordinate.latitude * 1000).rounded() / 1000
        let roundedLon = (coordinate.longitude * 1000).rounded() / 1000
        
        // Use the actual categories that will be used in the query
        let actualCategories = categories.isEmpty ? getDefaultCategories() : categories
        let categoriesKey = actualCategories.sorted().joined(separator: ",")
        return "\(roundedLat),\(roundedLon),\(radiusMeters),\(categoriesKey)"
    }
    
    /// Check if cached data is still valid based on time and location
    private func isCacheValid(cached: CachedPlaces, coordinate: CLLocationCoordinate2D) -> Bool {
        // Check time-based expiration
        let timeSinceCache = Date().timeIntervalSince(cached.timestamp)
        if timeSinceCache > cacheValidDuration {
            return false
        }
        
        // Check location-based expiration (100 meter tolerance)
        let distance = distanceBetween(cached.coordinate, coordinate)
        return distance <= locationToleranceMeters
    }
    
    /// Calculate distance between two coordinates in meters
    func distanceBetween(
        _ coord1: CLLocationCoordinate2D,
        _ coord2: CLLocationCoordinate2D
    ) -> Double {
        let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
        return location1.distance(from: location2)
    }
    
    /// Clean up expired cache entries to prevent memory buildup
    private func cleanupExpiredCache() {
        let now = Date()
        let keysToRemove: [String] = cacheQueue.sync {
            _placesCache.compactMap { key, cached -> String? in
                let timeSinceCache = now.timeIntervalSince(cached.timestamp)
                return timeSinceCache > cacheValidDuration ? key : nil
            }
        }
        
        if !keysToRemove.isEmpty {
            removeExpiredCacheEntries(keysToRemove)
            print("📍 Cleaned up \(keysToRemove.count) expired cache entries")
        }
    }
    
    /// Get the default categories when none are specified
    func getDefaultCategories() -> [String] {
        return [
            "amenity=restaurant",
            "amenity=cafe", 
            "amenity=bar",
            "amenity=pub",
            "amenity=fast_food",
            "leisure=climbing",
            "leisure=sports_centre",
            "leisure=fitness_centre",
            "shop=outdoor",
            "shop=sports",
            "tourism=attraction",
            "tourism=museum",
            "tourism=gallery"
        ]
    }

    func buildOverpassQuery(
        coordinate: CLLocationCoordinate2D,
        radiusMeters: Double,
        categories: [String]
    ) -> String {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        
        // Build the query based on categories
        var queryParts: [String] = []
        
        let actualCategories = categories.isEmpty ? getDefaultCategories() : categories
        
        // Use actual categories for building the query
        for category in actualCategories {
            queryParts.append("node[\(category)][\"name\"](around:\(radiusMeters),\(lat),\(lon));")
            queryParts.append("way[\(category)][\"name\"](around:\(radiusMeters),\(lat),\(lon));")
        }
        
        let query = """
        [out:json][timeout:10];
        (
          \(queryParts.joined(separator: "\n  "))
        );
        out center tags;
        """
        
        return query
    }
    
    func buildRequest(query: String) throws -> URLRequest {
        guard let url = URL(string: baseURL) else {
            throw OverpassError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("Anchor/1.0 (macOS menubar check-in app; https://github.com/example/anchor)", forHTTPHeaderField: "User-Agent")
        
        let body = "data=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        request.httpBody = body.data(using: .utf8)
        
        return request
    }
    
    func parseElement(_ element: OverpassElement) -> Place? {
        guard let elementType = Place.ElementType(rawValue: element.type),
              let name = element.tags?["name"],
              !name.isEmpty else {
            return nil
        }
        
        let latitude: Double
        let longitude: Double
        
        // Handle different coordinate sources
        if let lat = element.lat, let lon = element.lon {
            latitude = lat
            longitude = lon
        } else if let center = element.center {
            latitude = center.lat
            longitude = center.lon
        } else {
            return nil
        }
        
        return Place(
            elementType: elementType,
            elementId: element.id,
            name: name,
            latitude: latitude,
            longitude: longitude,
            tags: element.tags ?? [:]
        )
    }
}

// MARK: - Response Models

private struct OverpassResponse: Codable {
    let version: Double?
    let generator: String?
    let elements: [OverpassElement]
}

private struct OverpassElement: Codable {
    let type: String
    let id: Int64
    let lat: Double?
    let lon: Double?
    let center: OverpassCenter?
    let tags: [String: String]?
}

private struct OverpassCenter: Codable {
    let lat: Double
    let lon: Double
}

// MARK: - Error Types

public enum OverpassError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case noData
    case networkError(URLError)
    case decodingError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Overpass API URL"
        case .invalidResponse:
            return "Invalid response from Overpass API"
        case .httpError(let code):
            return "HTTP error \(code) from Overpass API"
        case .noData:
            return "No data received from Overpass API"
        case .networkError(let urlError):
            return "Network error: \(urlError.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode Overpass response: \(error.localizedDescription)"
        }
    }
}
