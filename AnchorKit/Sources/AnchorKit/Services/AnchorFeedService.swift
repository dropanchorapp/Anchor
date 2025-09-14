//
//  AnchorFeedService.swift
//  AnchorKit
//
//  Created by Tijs Teulings on 13/08/2025.
//

import Foundation

// MARK: - Feed Service Protocol

/// Service protocol for Anchor feed operations
@MainActor
public protocol AnchorFeedServiceProtocol {
    func getGlobalFeed(limit: Int, cursor: String?) async throws -> AnchorFeedResponse
    func getNearbyCheckins(latitude: Double, longitude: Double, radius: Double, limit: Int) async throws -> AnchorNearbyFeedResponse
    func getUserCheckins(did: String, limit: Int, cursor: String?) async throws -> AnchorFeedResponse
    func getFollowingFeed(userDid: String, limit: Int, cursor: String?) async throws -> AnchorFeedResponse
}

// MARK: - Anchor Feed Service

/// Service for reading feed data from the Anchor backend
/// Provides read-only access to global, nearby, user, and following feeds
@MainActor
public final class AnchorFeedService: AnchorFeedServiceProtocol {
    // MARK: - Properties

    private let session: URLSessionProtocol
    private let baseURL: URL

    // MARK: - Initialization

    public init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
        self.baseURL = URL(string: "https://dropanchor.app/api")!
    }

    // MARK: - Feed Methods

    /// Get recent check-ins from all users with pagination support
    /// - Parameters:
    ///   - limit: Number of check-ins to return (default: 50, max: 100)
    ///   - cursor: ISO timestamp for pagination
    /// - Returns: Global feed response with check-ins and cursor
    public func getGlobalFeed(limit: Int = 50, cursor: String? = nil) async throws -> AnchorFeedResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("/global"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit))
        ]
        if let cursor = cursor {
            components.queryItems?.append(URLQueryItem(name: "cursor", value: cursor))
        }

        let request = URLRequest(url: components.url!)
        return try await performRequest(request, responseType: AnchorFeedResponse.self)
    }

    /// Get nearby check-ins within a geographic radius
    /// - Parameters:
    ///   - latitude: Center latitude for search
    ///   - longitude: Center longitude for search
    ///   - radius: Search radius in kilometers (default: 5km)
    ///   - limit: Number of check-ins to return (default: 50)
    /// - Returns: Nearby feed response with spatial information
    public func getNearbyCheckins(latitude: Double, longitude: Double, radius: Double = 5.0, limit: Int = 50) async throws -> AnchorNearbyFeedResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("/nearby"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lng", value: String(longitude)),
            URLQueryItem(name: "radius", value: String(radius)),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        let request = URLRequest(url: components.url!)
        return try await performRequest(request, responseType: AnchorNearbyFeedResponse.self)
    }

    /// Get check-ins for a specific user with pagination support
    /// - Parameters:
    ///   - did: User's DID identifier
    ///   - limit: Number of check-ins to return (default: 50)
    ///   - cursor: ISO timestamp for pagination
    /// - Returns: User feed response with check-ins and cursor
    public func getUserCheckins(did: String, limit: Int = 50, cursor: String? = nil) async throws -> AnchorFeedResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("/user"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "did", value: did),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        if let cursor = cursor {
            components.queryItems?.append(URLQueryItem(name: "cursor", value: cursor))
        }

        let request = URLRequest(url: components.url!)
        return try await performRequest(request, responseType: AnchorFeedResponse.self)
    }

    /// Get check-ins from users that the specified user follows
    /// - Parameters:
    ///   - userDid: DID of the user whose following feed to retrieve
    ///   - limit: Number of check-ins to return (default: 50)
    ///   - cursor: ISO timestamp for pagination
    /// - Returns: Following feed response with check-ins and cursor
    public func getFollowingFeed(userDid: String, limit: Int = 50, cursor: String? = nil) async throws -> AnchorFeedResponse {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("/following"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "user", value: userDid),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        if let cursor = cursor {
            components.queryItems?.append(URLQueryItem(name: "cursor", value: cursor))
        }

        let request = URLRequest(url: components.url!)
        return try await performRequest(request, responseType: AnchorFeedResponse.self)
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
                throw AnchorFeedError.invalidResponse
            }

            // Check for HTTP errors
            guard 200...299 ~= httpResponse.statusCode else {
                // Try to decode error response
                if let errorResponse = try? JSONDecoder().decode(AnchorFeedErrorResponse.self, from: data) {
                    throw AnchorFeedError.apiError(httpResponse.statusCode, errorResponse.error)
                } else {
                    throw AnchorFeedError.httpError(httpResponse.statusCode)
                }
            }

            // Decode successful response
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(responseType, from: data)

        } catch let error as AnchorFeedError {
            throw error
        } catch {
            throw AnchorFeedError.networkError(error)
        }
    }
}

// MARK: - Response Models

/// Response format for global, user, and following feeds
public struct AnchorFeedResponse: Codable, Sendable {
    public let checkins: [AnchorFeedCheckin]
    public let cursor: String?
    public let user: AnchorFeedUser?

    public init(checkins: [AnchorFeedCheckin], cursor: String? = nil, user: AnchorFeedUser? = nil) {
        self.checkins = checkins
        self.cursor = cursor
        self.user = user
    }
}

/// Response format for nearby queries with spatial information
public struct AnchorNearbyFeedResponse: Codable, Sendable {
    public let checkins: [AnchorFeedCheckin]
    public let center: AnchorFeedCoordinates
    public let radius: Double

    public init(checkins: [AnchorFeedCheckin], center: AnchorFeedCoordinates, radius: Double) {
        self.checkins = checkins
        self.center = center
        self.radius = radius
    }
}

/// Individual check-in record from the Feed API
public struct AnchorFeedCheckin: Codable, Sendable, Identifiable {
    public let id: String
    public let uri: String
    public let author: AnchorFeedAuthor
    public let text: String
    public let createdAt: String
    public let coordinates: AnchorFeedCoordinates?
    public let address: AnchorFeedAddress?
    public let distance: Double? // Only present in nearby responses

    public init(id: String, uri: String, author: AnchorFeedAuthor, text: String, createdAt: String, coordinates: AnchorFeedCoordinates? = nil, address: AnchorFeedAddress? = nil, distance: Double? = nil) {
        self.id = id
        self.uri = uri
        self.author = author
        self.text = text
        self.createdAt = createdAt
        self.coordinates = coordinates
        self.address = address
        self.distance = distance
    }

    // Custom decoder to handle null id values by using uri as fallback
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle null id by using uri as fallback
        let idValue = try container.decodeIfPresent(String.self, forKey: .id)
        uri = try container.decode(String.self, forKey: .uri)
        id = idValue ?? uri

        author = try container.decode(AnchorFeedAuthor.self, forKey: .author)
        text = try container.decode(String.self, forKey: .text)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        coordinates = try container.decodeIfPresent(AnchorFeedCoordinates.self, forKey: .coordinates)
        address = try container.decodeIfPresent(AnchorFeedAddress.self, forKey: .address)
        distance = try container.decodeIfPresent(Double.self, forKey: .distance)
    }

    private enum CodingKeys: String, CodingKey {
        case id, uri, author, text, createdAt, coordinates, address, distance
    }
}

/// Author information for check-ins
public struct AnchorFeedAuthor: Codable, Sendable {
    public let did: String
    public let handle: String
    public let displayName: String?
    public let avatar: String?

    public init(did: String, handle: String, displayName: String? = nil, avatar: String? = nil) {
        self.did = did
        self.handle = handle
        self.displayName = displayName
        self.avatar = avatar
    }
}

/// Geographic coordinates
public struct AnchorFeedCoordinates: Codable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// Address/location information
public struct AnchorFeedAddress: Codable, Sendable {
    public let name: String?
    public let streetAddress: String?
    public let locality: String?
    public let region: String?
    public let country: String?

    public init(name: String? = nil, streetAddress: String? = nil, locality: String? = nil, region: String? = nil, country: String? = nil) {
        self.name = name
        self.streetAddress = streetAddress
        self.locality = locality
        self.region = region
        self.country = country
    }
}

/// User information
public struct AnchorFeedUser: Codable, Sendable {
    public let did: String
    public let handle: String
    public let displayName: String?
    public let avatar: String?

    public init(did: String, handle: String, displayName: String? = nil, avatar: String? = nil) {
        self.did = did
        self.handle = handle
        self.displayName = displayName
        self.avatar = avatar
    }
}

/// Stats information
public struct AnchorFeedStats: Codable, Sendable {
    public let totalCheckins: Int
    public let uniqueUsers: Int
    public let uniquePlaces: Int
    public let lastUpdate: String

    public init(totalCheckins: Int, uniqueUsers: Int, uniquePlaces: Int, lastUpdate: String) {
        self.totalCheckins = totalCheckins
        self.uniqueUsers = uniqueUsers
        self.uniquePlaces = uniquePlaces
        self.lastUpdate = lastUpdate
    }
}

/// Error response from the Feed API
public struct AnchorFeedErrorResponse: Codable, Sendable {
    public let error: String

    public init(error: String) {
        self.error = error
    }
}

// MARK: - Feed Error Types

public enum AnchorFeedError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case apiError(Int, String)
    case networkError(Error)
    case decodingError(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .apiError(let statusCode, let message):
            return "API error (\(statusCode)): \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}
