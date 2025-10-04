import Foundation

// MARK: - API Response Models

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

    public init(
        id: String,
        elementType: String,
        elementId: Int64,
        name: String,
        latitude: Double,
        longitude: Double,
        tags: [String: String],
        distance: Double
    ) {
        self.id = id
        self.elementType = elementType
        self.elementId = elementId
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.tags = tags
        self.distance = distance
    }

    // Custom decoding to handle elementId as either string or integer
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.elementType = try container.decode(String.self, forKey: .elementType)
        self.name = try container.decode(String.self, forKey: .name)
        self.latitude = try container.decode(Double.self, forKey: .latitude)
        self.longitude = try container.decode(Double.self, forKey: .longitude)
        self.tags = try container.decode([String: String].self, forKey: .tags)
        self.distance = try container.decode(Double.self, forKey: .distance)

        // Decode elementId flexibly - try as Int64 first, fall back to String
        if let elementIdInt = try? container.decode(Int64.self, forKey: .elementId) {
            self.elementId = elementIdInt
        } else if let elementIdString = try? container.decode(String.self, forKey: .elementId) {
            // Parse string to Int64
            self.elementId = Int64(elementIdString) ?? 0
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .elementId,
                in: container,
                debugDescription: "elementId must be either Int64 or String"
            )
        }
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

/// API response for places search
public struct AnchorPlacesSearchResponse: Codable, Sendable {
    public let places: [AnchorPlacesSearchAPIPlace]
    public let query: String
    public let center: AnchorPlacesCoordinates
    public let radius: Double
    public let count: Int

    public init(
        places: [AnchorPlacesSearchAPIPlace],
        query: String,
        center: AnchorPlacesCoordinates,
        radius: Double,
        count: Int
    ) {
        self.places = places
        self.query = query
        self.center = center
        self.radius = radius
        self.count = count
    }
}

/// API representation of a place from search endpoint
public struct AnchorPlacesSearchAPIPlace: Codable, Sendable {
    public let id: String
    public let elementType: String
    public let elementId: Int64
    public let name: String
    public let latitude: Double
    public let longitude: Double
    public let tags: [String: String]
    public let address: SearchPlaceAddress?
    public let category: String
    public let icon: String
    public let distanceMeters: Double
    public let formattedDistance: String

    public init(
        id: String,
        elementType: String,
        elementId: Int64,
        name: String,
        latitude: Double,
        longitude: Double,
        tags: [String: String],
        address: SearchPlaceAddress?,
        category: String,
        icon: String,
        distanceMeters: Double,
        formattedDistance: String
    ) {
        self.id = id
        self.elementType = elementType
        self.elementId = elementId
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.tags = tags
        self.address = address
        self.category = category
        self.icon = icon
        self.distanceMeters = distanceMeters
        self.formattedDistance = formattedDistance
    }

    // Custom decoding to handle elementId as either string or integer
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.elementType = try container.decode(String.self, forKey: .elementType)
        self.name = try container.decode(String.self, forKey: .name)
        self.latitude = try container.decode(Double.self, forKey: .latitude)
        self.longitude = try container.decode(Double.self, forKey: .longitude)
        self.tags = try container.decode([String: String].self, forKey: .tags)
        self.address = try container.decodeIfPresent(SearchPlaceAddress.self, forKey: .address)
        self.category = try container.decode(String.self, forKey: .category)
        self.icon = try container.decode(String.self, forKey: .icon)
        self.distanceMeters = try container.decode(Double.self, forKey: .distanceMeters)
        self.formattedDistance = try container.decode(String.self, forKey: .formattedDistance)

        // Decode elementId flexibly - try as Int64 first, fall back to String
        if let elementIdInt = try? container.decode(Int64.self, forKey: .elementId) {
            self.elementId = elementIdInt
        } else if let elementIdString = try? container.decode(String.self, forKey: .elementId) {
            // Parse string to Int64
            self.elementId = Int64(elementIdString) ?? 0
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .elementId,
                in: container,
                debugDescription: "elementId must be either Int64 or String"
            )
        }
    }
}

/// Address information from search API
public struct SearchPlaceAddress: Codable, Sendable {
    public let type: String // "$type": "community.lexicon.location.address"
    public let name: String?
    public let street: String?
    public let locality: String?
    public let region: String?
    public let country: String?
    public let postalCode: String?

    enum CodingKeys: String, CodingKey {
        case type = "$type"
        case name, street, locality, region, country, postalCode
    }

    public init(
        type: String,
        name: String?,
        street: String?,
        locality: String?,
        region: String?,
        country: String?,
        postalCode: String?
    ) {
        self.type = type
        self.name = name
        self.street = street
        self.locality = locality
        self.region = region
        self.country = country
        self.postalCode = postalCode
    }
}

// MARK: - Error Types

public enum AnchorPlacesError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case networkError(Error)
    case decodingError(Error)
    case invalidCategory(String)

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
        case .invalidCategory(let category):
            return "Invalid category group: \(category)"
        }
    }
}
