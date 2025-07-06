import Foundation

// MARK: - Anchor AppView Service Protocol

/// Service protocol for the new Anchor AppView backend
/// Uses the REST API at https://anchor-feed-generator.val.run
@MainActor
public protocol AnchorAppViewServiceProtocol {
    func getGlobalFeed(limit: Int, cursor: String?) async throws -> AnchorAppViewFeedResponse
    func getNearbyCheckins(latitude: Double, longitude: Double, radius: Double, limit: Int) async throws -> AnchorAppViewNearbyResponse
    func getUserCheckins(did: String, limit: Int, cursor: String?) async throws -> AnchorAppViewFeedResponse
    func getFollowingFeed(userDid: String, limit: Int, cursor: String?) async throws -> AnchorAppViewFeedResponse
    func getStats() async throws -> AnchorAppViewStats
}

// MARK: - Anchor AppView Service Implementation

/// Service for integrating with the new Anchor AppView backend
/// Provides feeds from the Val Town-hosted location-feed-generator API
@MainActor
public final class AnchorAppViewService: AnchorAppViewServiceProtocol {
    // MARK: - Properties

    private let session: URLSessionProtocol
    private let baseURL = "https://anchor-feed-generator.val.run"

    // MARK: - Initialization

    public init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }

    // MARK: - Feed Methods

    /// Get recent check-ins from all users with pagination support
    /// - Parameters:
    ///   - limit: Number of check-ins to return (default: 50, max: 100)
    ///   - cursor: ISO timestamp for pagination
    /// - Returns: Global feed response with check-ins and cursor
    public func getGlobalFeed(limit: Int = 50, cursor: String? = nil) async throws -> AnchorAppViewFeedResponse {
        var components = URLComponents(string: "\(baseURL)/global")!
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit))
        ]
        if let cursor = cursor {
            components.queryItems?.append(URLQueryItem(name: "cursor", value: cursor))
        }

        let request = URLRequest(url: components.url!)
        return try await performRequest(request, responseType: AnchorAppViewFeedResponse.self)
    }

    /// Get check-ins within a specified radius of coordinates using spatial queries
    /// - Parameters:
    ///   - latitude: Latitude in decimal degrees
    ///   - longitude: Longitude in decimal degrees  
    ///   - radius: Search radius in kilometers (default: 5, max: 50)
    ///   - limit: Number of results (default: 50, max: 100)
    /// - Returns: Nearby response with check-ins, center coordinates, and distances
    public func getNearbyCheckins(latitude: Double, longitude: Double, radius: Double = 5.0, limit: Int = 50) async throws -> AnchorAppViewNearbyResponse {
        var components = URLComponents(string: "\(baseURL)/nearby")!
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lng", value: String(longitude)),
            URLQueryItem(name: "radius", value: String(radius)),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        let request = URLRequest(url: components.url!)
        return try await performRequest(request, responseType: AnchorAppViewNearbyResponse.self)
    }

    /// Get all check-ins from a specific user
    /// - Parameters:
    ///   - did: User's decentralized identifier
    ///   - limit: Number of results (default: 50, max: 100)
    ///   - cursor: ISO timestamp for pagination
    /// - Returns: User feed response with check-ins and cursor
    public func getUserCheckins(did: String, limit: Int = 50, cursor: String? = nil) async throws -> AnchorAppViewFeedResponse {
        var components = URLComponents(string: "\(baseURL)/user")!
        components.queryItems = [
            URLQueryItem(name: "did", value: did),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        if let cursor = cursor {
            components.queryItems?.append(URLQueryItem(name: "cursor", value: cursor))
        }

        let request = URLRequest(url: components.url!)
        return try await performRequest(request, responseType: AnchorAppViewFeedResponse.self)
    }

    /// Get check-ins from users that the specified user follows on Bluesky
    /// - Parameters:
    ///   - userDid: User's DID to get following feed for
    ///   - limit: Number of results (default: 50, max: 100)
    ///   - cursor: ISO timestamp for pagination
    /// - Returns: Following feed response with check-ins and cursor
    public func getFollowingFeed(userDid: String, limit: Int = 50, cursor: String? = nil) async throws -> AnchorAppViewFeedResponse {
        var components = URLComponents(string: "\(baseURL)/following")!
        components.queryItems = [
            URLQueryItem(name: "user", value: userDid),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        if let cursor = cursor {
            components.queryItems?.append(URLQueryItem(name: "cursor", value: cursor))
        }

        let request = URLRequest(url: components.url!)
        return try await performRequest(request, responseType: AnchorAppViewFeedResponse.self)
    }

    /// Get AppView health metrics and processing statistics
    /// - Returns: Statistics about the AppView system
    public func getStats() async throws -> AnchorAppViewStats {
        let url = URL(string: "\(baseURL)/stats")!
        let request = URLRequest(url: url)
        return try await performRequest(request, responseType: AnchorAppViewStats.self)
    }

    // MARK: - Private Methods

    /// Perform HTTP request and decode response
    /// - Parameters:
    ///   - request: URLRequest to perform
    ///   - responseType: Type to decode response into
    /// - Returns: Decoded response object
    private func performRequest<T: Codable>(_ request: URLRequest, responseType: T.Type) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AnchorAppViewError.invalidResponse
            }

            // Check for HTTP errors
            guard 200...299 ~= httpResponse.statusCode else {
                // Try to decode error response
                if let errorResponse = try? JSONDecoder().decode(AnchorAppViewErrorResponse.self, from: data) {
                    throw AnchorAppViewError.apiError(httpResponse.statusCode, errorResponse.error)
                } else {
                    throw AnchorAppViewError.httpError(httpResponse.statusCode)
                }
            }

            // Decode successful response
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(responseType, from: data)

        } catch let error as AnchorAppViewError {
            throw error
        } catch {
            throw AnchorAppViewError.networkError(error)
        }
    }
}

// MARK: - Response Models

/// Response format for global, user, and following feeds
public struct AnchorAppViewFeedResponse: Codable, Sendable {
    public let checkins: [AnchorAppViewCheckin]
    public let cursor: String?
    public let user: AnchorAppViewUser?

    public init(checkins: [AnchorAppViewCheckin], cursor: String? = nil, user: AnchorAppViewUser? = nil) {
        self.checkins = checkins
        self.cursor = cursor
        self.user = user
    }
}

/// Response format for nearby queries with spatial information
public struct AnchorAppViewNearbyResponse: Codable, Sendable {
    public let checkins: [AnchorAppViewCheckin]
    public let center: AnchorAppViewCoordinates
    public let radius: Double

    public init(checkins: [AnchorAppViewCheckin], center: AnchorAppViewCoordinates, radius: Double) {
        self.checkins = checkins
        self.center = center
        self.radius = radius
    }
}

/// Individual check-in record from the AppView API
public struct AnchorAppViewCheckin: Codable, Sendable, Identifiable {
    public let id: String
    public let uri: String
    public let author: AnchorAppViewAuthor
    public let text: String
    public let createdAt: String
    public let coordinates: AnchorAppViewCoordinates?
    public let address: AnchorAppViewAddress?
    public let distance: Double? // Only present in nearby responses

    public init(id: String, uri: String, author: AnchorAppViewAuthor, text: String, createdAt: String, coordinates: AnchorAppViewCoordinates? = nil, address: AnchorAppViewAddress? = nil, distance: Double? = nil) {
        self.id = id
        self.uri = uri
        self.author = author
        self.text = text
        self.createdAt = createdAt
        self.coordinates = coordinates
        self.address = address
        self.distance = distance
    }
}

/// Author information for check-ins
public struct AnchorAppViewAuthor: Codable, Sendable {
    public let did: String
    public let handle: String

    public init(did: String, handle: String) {
        self.did = did
        self.handle = handle
    }
}

/// Geographic coordinates
public struct AnchorAppViewCoordinates: Codable, Sendable, Hashable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// Address/venue information
public struct AnchorAppViewAddress: Codable, Sendable, Hashable {
    public let name: String?
    public let street: String?
    public let locality: String?
    public let region: String?
    public let country: String?
    public let postalCode: String?

    public init(name: String? = nil, street: String? = nil, locality: String? = nil, region: String? = nil, country: String? = nil, postalCode: String? = nil) {
        self.name = name
        self.street = street
        self.locality = locality
        self.region = region
        self.country = country
        self.postalCode = postalCode
    }
}

/// User information for feed responses
public struct AnchorAppViewUser: Codable, Sendable {
    public let did: String

    public init(did: String) {
        self.did = did
    }
}

/// AppView statistics response
public struct AnchorAppViewStats: Codable, Sendable {
    public let totalCheckins: Int
    public let totalUsers: Int
    public let recentActivity: Int
    public let lastProcessingRun: String?
    public let timestamp: String

    public init(totalCheckins: Int, totalUsers: Int, recentActivity: Int, lastProcessingRun: String? = nil, timestamp: String) {
        self.totalCheckins = totalCheckins
        self.totalUsers = totalUsers
        self.recentActivity = recentActivity
        self.lastProcessingRun = lastProcessingRun
        self.timestamp = timestamp
    }
}

// MARK: - LocationRepresentable Conformance

extension AnchorAppViewAddress: LocationRepresentable {
    public var displayName: String? {
        return name
    }

    public var coordinate: (Double, Double)? {
        return nil
    }
}

/// Error response format from the API
public struct AnchorAppViewErrorResponse: Codable, Sendable {
    public let error: String

    public init(error: String) {
        self.error = error
    }
}

// MARK: - Error Types

/// Errors that can occur when using the Anchor AppView API
public enum AnchorAppViewError: LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case apiError(Int, String)
    case networkError(Error)
    case decodingError(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid AppView API URL"
        case .invalidResponse:
            return "Invalid response from AppView API"
        case let .httpError(code):
            return "HTTP error \(code) from AppView API"
        case let .apiError(code, message):
            return "API error \(code): \(message)"
        case let .networkError(error):
            return "Network error: \(error.localizedDescription)"
        case let .decodingError(error):
            return "Failed to decode AppView response: \(error.localizedDescription)"
        }
    }
}
