//
//  AnchorFeedModels.swift
//  AnchorKit
//
//  Response models and error types for Anchor Feed API
//

import Foundation

// MARK: - Response Models

/// Response format for user feed (personal timeline)
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
    public let image: AnchorFeedImage? // Optional image attachment
    public let likesCount: Int? // Optional likes count

    public init(
        id: String,
        uri: String,
        author: AnchorFeedAuthor,
        text: String,
        createdAt: String,
        coordinates: AnchorFeedCoordinates? = nil,
        address: AnchorFeedAddress? = nil,
        distance: Double? = nil,
        image: AnchorFeedImage? = nil,
        likesCount: Int? = nil
    ) {
        self.id = id
        self.uri = uri
        self.author = author
        self.text = text
        self.createdAt = createdAt
        self.coordinates = coordinates
        self.address = address
        self.distance = distance
        self.image = image
        self.likesCount = likesCount
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
        image = try container.decodeIfPresent(AnchorFeedImage.self, forKey: .image)
        likesCount = try container.decodeIfPresent(Int.self, forKey: .likesCount)
    }

    private enum CodingKeys: String, CodingKey {
        case id, uri, author, text, createdAt, coordinates, address, distance, image, likesCount
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

    // Custom decoder to handle both string and number values from API
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Try to decode as Double first, then as String and convert
        if let lat = try? container.decode(Double.self, forKey: .latitude) {
            latitude = lat
        } else if let latString = try? container.decode(String.self, forKey: .latitude),
                  let lat = Double(latString) {
            latitude = lat
        } else {
            throw DecodingError.typeMismatchWithInfo(
                Double.self,
                DecodingError.Context(
                    codingPath: container.codingPath + [CodingKeys.latitude],
                    debugDescription: "Expected Double or String for latitude"
                )
            )
        }

        if let lng = try? container.decode(Double.self, forKey: .longitude) {
            longitude = lng
        } else if let lngString = try? container.decode(String.self, forKey: .longitude),
                  let lng = Double(lngString) {
            longitude = lng
        } else {
            throw DecodingError.typeMismatchWithInfo(
                Double.self,
                DecodingError.Context(
                    codingPath: container.codingPath + [CodingKeys.longitude],
                    debugDescription: "Expected Double or String for longitude"
                )
            )
        }
    }

    private enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }
}

// Helper extension for better error messages
extension DecodingError {
    static func typeMismatchWithInfo(
        _ type: Any.Type,
        _ context: Context
    ) -> DecodingError {
        return .typeMismatch(type, context)
    }
}

/// Address/location information
public struct AnchorFeedAddress: Codable, Sendable {
    public let name: String?
    public let streetAddress: String?
    public let locality: String?
    public let region: String?
    public let country: String?

    public init(
        name: String? = nil,
        streetAddress: String? = nil,
        locality: String? = nil,
        region: String? = nil,
        country: String? = nil
    ) {
        self.name = name
        self.streetAddress = streetAddress
        self.locality = locality
        self.region = region
        self.country = country
    }
}

/// Image attachment information
public struct AnchorFeedImage: Codable, Sendable {
    public let thumbUrl: String
    public let fullsizeUrl: String
    public let alt: String?

    public init(
        thumbUrl: String,
        fullsizeUrl: String,
        alt: String? = nil
    ) {
        self.thumbUrl = thumbUrl
        self.fullsizeUrl = fullsizeUrl
        self.alt = alt
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

/// Delete response from the Feed API
public struct AnchorFeedDeleteResponse: Codable, Sendable {
    public let success: Bool

    public init(success: Bool) {
        self.success = success
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
