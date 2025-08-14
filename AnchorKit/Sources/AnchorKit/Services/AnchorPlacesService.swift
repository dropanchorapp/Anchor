//
//  AnchorPlacesService.swift
//  AnchorKit
//
//  Created by Claude Code on 13/08/2025.
//

import CoreLocation
import Foundation

// MARK: - Places Service Protocol

/// Service protocol for Anchor places operations
public protocol AnchorPlacesServiceProtocol {
    func findNearbyPlaces(near coordinate: CLLocationCoordinate2D, radiusMeters: Double, categories: [String]) async throws -> [Place]
    func findNearbyPlacesWithDistance(near coordinate: CLLocationCoordinate2D, radiusMeters: Double, categories: [String]) async throws -> [AnchorPlaceWithDistance]
    func findPlacesByCategories(near coordinate: CLLocationCoordinate2D, radiusMeters: Double, categories: [String]) async throws -> [Place]
    func findPlacesByGroup(near coordinate: CLLocationCoordinate2D, radiusMeters: Double, group: String) async throws -> [Place]
    func getAllAvailableCategories() -> [String]
    func getPrioritizedCategories() -> [String]
    func clearCache()
}

// MARK: - Anchor Places Service

/// Service for discovering places from the Anchor backend API
/// Provides read-only access to nearby places, categories, and search functionality
public final class AnchorPlacesService: AnchorPlacesServiceProtocol, @unchecked Sendable {
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
    ) async throws -> [AnchorPlaceWithDistance] {

        print("🗺️ AnchorPlacesService: Finding places near (\(coordinate.latitude), \(coordinate.longitude)) within \(radiusMeters)m")
        if !categories.isEmpty {
            print("🗺️ AnchorPlacesService: Categories filter: \(categories)")
        }

        // Build request to /api/places/nearby
        let request = try buildRequest(
            coordinate: coordinate,
            radiusMeters: radiusMeters,
            categories: categories
        )

        print("🗺️ AnchorPlacesService: Making request to: \(request.url?.absoluteString ?? "unknown")")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AnchorPlacesError.invalidResponse
            }

            print("🗺️ AnchorPlacesService: Response status: \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 200 else {
                let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ AnchorPlacesService: Error response: \(errorString)")
                throw AnchorPlacesError.httpError(httpResponse.statusCode)
            }

            // Parse response
            let placesResponse = try JSONDecoder().decode(AnchorPlacesNearbyResponse.self, from: data)

            print("✅ AnchorPlacesService: Found \(placesResponse.places.count) places")

            return placesResponse.places.map { apiPlace in
                let elementType = Place.ElementType(rawValue: apiPlace.elementType) ?? .node
                let place = Place(
                    elementType: elementType,
                    elementId: apiPlace.elementId,
                    name: apiPlace.name,
                    latitude: apiPlace.latitude,
                    longitude: apiPlace.longitude,
                    tags: apiPlace.tags
                )
                return AnchorPlaceWithDistance(place: place, distance: apiPlace.distance)
            }

        } catch {
            print("❌ AnchorPlacesService: Network error: \(error)")
            throw AnchorPlacesError.networkError(error)
        }
    }

    /// Find places by specific categories (convenience method)
    /// - Parameters:
    ///   - coordinate: Center coordinate for search
    ///   - radiusMeters: Search radius in meters
    ///   - categories: OSM tag categories to search for
    /// - Returns: Array of places matching the categories
    public func findPlacesByCategories(
        near coordinate: CLLocationCoordinate2D,
        radiusMeters: Double = Double(AnchorConfig.shared.locationSearchRadius),
        categories: [String]
    ) async throws -> [Place] {
        return try await findNearbyPlaces(
            near: coordinate,
            radiusMeters: radiusMeters,
            categories: categories
        )
    }

    /// Find places by category group (e.g., "food", "entertainment")
    /// - Parameters:
    ///   - coordinate: Center coordinate for search
    ///   - radiusMeters: Search radius in meters
    ///   - group: Category group name
    /// - Returns: Array of places in the specified group
    public func findPlacesByGroup(
        near coordinate: CLLocationCoordinate2D,
        radiusMeters: Double = Double(AnchorConfig.shared.locationSearchRadius),
        group: String
    ) async throws -> [Place] {
        // For now, use prioritized categories as a fallback
        // TODO: Implement proper group-to-categories mapping
        let categories = PlaceCategorization.getPrioritizedCategories()
        return try await findPlacesByCategories(
            near: coordinate,
            radiusMeters: radiusMeters,
            categories: categories
        )
    }

    /// Get all available place categories
    /// - Returns: Array of all available OSM tag categories
    public func getAllAvailableCategories() -> [String] {
        return PlaceCategorization.getAllCategories()
    }

    /// Get prioritized/popular categories for UI display
    /// - Returns: Array of prioritized category tags
    public func getPrioritizedCategories() -> [String] {
        return PlaceCategorization.getPrioritizedCategories()
    }

    /// Clear any cached data
    public func clearCache() {
        // Currently no caching implemented, but method provided for future use
    }

    // MARK: - Private Methods

    /// Build HTTP request for places API
    private func buildRequest(
        coordinate: CLLocationCoordinate2D,
        radiusMeters: Double,
        categories: [String]
    ) throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent("/places/nearby"), resolvingAgainstBaseURL: false)!

        var queryItems = [
            URLQueryItem(name: "lat", value: String(coordinate.latitude)),
            URLQueryItem(name: "lng", value: String(coordinate.longitude)),
            URLQueryItem(name: "radius", value: String(radiusMeters))
        ]

        // Add categories if provided
        if !categories.isEmpty {
            for category in categories {
                queryItems.append(URLQueryItem(name: "category", value: category))
            }
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            throw AnchorPlacesError.invalidURL
        }

        return URLRequest(url: url)
    }
}

// MARK: - Response Models

/// API response for nearby places
public struct AnchorPlacesNearbyResponse: Codable, Sendable {
    public let places: [AnchorPlacesAPIPlace]
    public let center: AnchorPlacesCoordinates
    public let radius: Double

    public init(places: [AnchorPlacesAPIPlace], center: AnchorPlacesCoordinates, radius: Double) {
        self.places = places
        self.center = center
        self.radius = radius
    }
}

/// API representation of a place
public struct AnchorPlacesAPIPlace: Codable, Sendable {
    public let id: String
    public let elementType: String
    public let elementId: Int64
    public let name: String
    public let latitude: Double
    public let longitude: Double
    public let tags: [String: String]
    public let distance: Double

    public init(id: String, elementType: String, elementId: Int64, name: String, latitude: Double, longitude: Double, tags: [String: String], distance: Double) {
        self.id = id
        self.elementType = elementType
        self.elementId = elementId
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.tags = tags
        self.distance = distance
    }
}

/// Geographic coordinates for API responses
public struct AnchorPlacesCoordinates: Codable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// Place with distance information
public struct AnchorPlaceWithDistance: Sendable, Identifiable {
    public let place: Place
    public let distance: Double

    public init(place: Place, distance: Double) {
        self.place = place
        self.distance = distance
    }

    /// Unique identifier for SwiftUI lists
    public var id: String {
        place.id
    }

    /// Formatted distance string (e.g., "150m" or "1.2km")
    public var formattedDistance: String {
        if distance < 1000 {
            return String(format: "%.0fm", distance)
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
}

// MARK: - Places Error Types

public enum AnchorPlacesError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case networkError(Error)
    case decodingError(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for places request"
        case .invalidResponse:
            return "Invalid response from places API"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}
