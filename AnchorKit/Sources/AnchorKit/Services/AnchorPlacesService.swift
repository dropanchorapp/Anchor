//
//  AnchorPlacesService.swift
//  AnchorKit
//
//  Created by Tijs Teulings on 13/08/2025.
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
    func searchPlaces(query: String, near coordinate: CLLocationCoordinate2D, limit: Int) async throws -> [AnchorPlaceWithDistance]
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
    private let categoryCache: CategoryCacheServiceProtocol
    private let settings: AnchorSettings

    // MARK: - Initialization

    public init(
        session: URLSession = .shared,
        baseURL: URL = URL(string: "https://dropanchor.app/api")!,
        categoryCache: CategoryCacheServiceProtocol = CategoryCacheService.shared,
        settings: AnchorSettings = AnchorSettings()
    ) {
        self.session = session
        self.baseURL = baseURL
        self.categoryCache = categoryCache
        self.settings = settings
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

        print("🗺️ AnchorPlacesService: Finding places near (\(coordinate.latitude), \(coordinate.longitude)) " +
              "within \(radiusMeters)m")
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
        // Convert string to CategoryGroup enum and map to specific OSM categories
        guard let categoryGroup = PlaceCategorization.CategoryGroup(rawValue: group) else {
            throw AnchorPlacesError.invalidCategory(group)
        }
        let categories = categoryCache.getCategoriesForGroup(categoryGroup)
        return try await findPlacesByCategories(
            near: coordinate,
            radiusMeters: radiusMeters,
            categories: categories
        )
    }

    /// Get all available place categories
    /// - Returns: Array of all available OSM tag categories
    public func getAllAvailableCategories() -> [String] {
        return categoryCache.getAllCategories()
    }

    /// Get prioritized/popular categories for UI display
    /// - Returns: Array of prioritized category tags
    public func getPrioritizedCategories() -> [String] {
        return categoryCache.getPrioritizedCategories()
    }

    /// Search for places using text query within vicinity
    /// - Parameters:
    ///   - query: Text query (e.g., "coffee shop", "sushi bar")
    ///   - coordinate: Center coordinate for search
    ///   - limit: Maximum number of results (default 10)
    /// - Returns: Array of places matching the query, sorted by distance
    public func searchPlaces(
        query: String,
        near coordinate: CLLocationCoordinate2D,
        limit: Int = 10
    ) async throws -> [AnchorPlaceWithDistance] {

        print("🔍 AnchorPlacesService: Searching for '\(query)' near (\(coordinate.latitude), \(coordinate.longitude))")
        print("🔍 AnchorPlacesService: Limit: \(limit)")

        // Build request to /api/places/search
        let request = try buildSearchRequest(
            query: query,
            coordinate: coordinate,
            limit: limit
        )

        print("🔍 AnchorPlacesService: Making search request to: \(request.url?.absoluteString ?? "unknown")")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AnchorPlacesError.invalidResponse
            }

            print("🔍 AnchorPlacesService: Search response status: \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 200 else {
                let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ AnchorPlacesService: Search error response: \(errorString)")
                throw AnchorPlacesError.httpError(httpResponse.statusCode)
            }

            // Parse search response
            let searchResponse = try JSONDecoder().decode(AnchorPlacesSearchResponse.self, from: data)

            print("✅ AnchorPlacesService: Found \(searchResponse.places.count) places for query '\(query)'")

            return searchResponse.places.map { apiPlace in
                let elementType = Place.ElementType(rawValue: apiPlace.elementType) ?? .node
                let place = Place(
                    elementType: elementType,
                    elementId: apiPlace.elementId,
                    name: apiPlace.name,
                    latitude: apiPlace.latitude,
                    longitude: apiPlace.longitude,
                    tags: apiPlace.tags
                )
                return AnchorPlaceWithDistance(
                    place: place,
                    distance: apiPlace.distanceMeters,
                    backendCategory: apiPlace.category,
                    backendIcon: apiPlace.icon
                )
            }

        } catch {
            print("❌ AnchorPlacesService: Search network error: \(error)")
            throw AnchorPlacesError.networkError(error)
        }
    }

    /// Clear any cached data
    public func clearCache() {
        categoryCache.clearCache()
    }

    // MARK: - Private Methods

    /// Build HTTP request for places API
    private func buildRequest(
        coordinate: CLLocationCoordinate2D,
        radiusMeters: Double,
        categories: [String]
    ) throws -> URLRequest {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("/places/nearby"),
            resolvingAgainstBaseURL: false
        )!

        var queryItems = [
            URLQueryItem(name: "lat", value: String(coordinate.latitude)),
            URLQueryItem(name: "lng", value: String(coordinate.longitude)),
            URLQueryItem(name: "radius", value: String(radiusMeters)),
            URLQueryItem(name: "provider", value: settings.nearbyPlacesProvider.rawValue)
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

    /// Build HTTP request for places search API
    private func buildSearchRequest(
        query: String,
        coordinate: CLLocationCoordinate2D,
        limit: Int
    ) throws -> URLRequest {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("/places/search"),
            resolvingAgainstBaseURL: false
        )!

        let queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "lat", value: String(coordinate.latitude)),
            URLQueryItem(name: "lng", value: String(coordinate.longitude)),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "provider", value: settings.placeSearchProvider.rawValue)
        ]

        components.queryItems = queryItems

        guard let url = components.url else {
            throw AnchorPlacesError.invalidURL
        }

        return URLRequest(url: url)
    }
}
