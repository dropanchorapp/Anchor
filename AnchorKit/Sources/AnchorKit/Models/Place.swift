import Foundation

/// AT Protocol community lexicon address format
public struct PlaceAddress: Codable, Sendable, Hashable {
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
        type: String = "community.lexicon.location.address",
        name: String? = nil,
        street: String? = nil,
        locality: String? = nil,
        region: String? = nil,
        country: String? = nil,
        postalCode: String? = nil
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

/// Represents a place/point of interest from OpenStreetMap via Overpass API
public struct Place: Codable, Sendable {
    /// Unique identifier in format "type:id" (e.g., "way:123456", "node:789012")
    public let id: String

    /// Display name of the place
    public let name: String

    /// Latitude coordinate
    public let latitude: Double

    /// Longitude coordinate
    public let longitude: Double

    /// OpenStreetMap tags (amenity, leisure, etc.)
    public let tags: [String: String]

    /// Element type from Overpass API ("node", "way", "relation")
    public let elementType: ElementType

    /// OpenStreetMap element ID
    public let elementId: Int64

    /// Structured address data from backend (includes locality, region, country)
    public let address: PlaceAddress?

    public init(
        elementType: ElementType,
        elementId: Int64,
        name: String,
        latitude: Double,
        longitude: Double,
        tags: [String: String] = [:],
        address: PlaceAddress? = nil
    ) {
        self.elementType = elementType
        self.elementId = elementId
        id = "\(elementType.rawValue):\(elementId)"
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.tags = tags
        self.address = address
    }
}

// MARK: - ElementType

public extension Place {
    enum ElementType: String, Codable, CaseIterable, Sendable {
        case node
        case way
        case relation
    }
}

// MARK: - Convenience Methods

public extension Place {
    /// Parse a place ID string into element type and ID
    /// - Parameter placeId: String in format "type:id" (e.g., "way:123456")
    /// - Returns: Tuple of (ElementType, Int64) or nil if invalid format
    static func parseId(_ placeId: String) -> (ElementType, Int64)? {
        let components = placeId.split(separator: ":")
        guard components.count == 2,
              let elementType = ElementType(rawValue: String(components[0])),
              let elementId = Int64(components[1])
        else {
            return nil
        }
        return (elementType, elementId)
    }

    /// Returns a human-readable description with coordinates
    var description: String {
        "\(name) (\(String(format: "%.6f", latitude)), \(String(format: "%.6f", longitude)))"
    }

    /// Returns the amenity or leisure type from tags
    var category: String? {
        tags["amenity"] ?? tags["leisure"] ?? tags["shop"] ?? tags["tourism"]
    }

    /// Returns the category group for this place (e.g., "Food & Drink", "Sports & Fitness")
    var categoryGroup: PlaceCategorization.CategoryGroup? {
        if let tag = tags.keys.first(where: { ["amenity", "leisure", "shop", "tourism"].contains($0) }),
           let value = tags[tag] {
            return PlaceCategorization.getCategoryGroup(for: tag, value: value)
        }
        return nil
    }

    /// Returns an appropriate icon for this place based on its category
    var icon: String {
        if let tag = tags.keys.first(where: { ["amenity", "leisure", "shop", "tourism"].contains($0) }),
           let value = tags[tag] {
            return PlaceCategorization.getIcon(for: tag, value: value)
        }
        return "📍"
    }
}

// MARK: - Identifiable

extension Place: Identifiable {
    // Uses the computed `id` property
}

// MARK: - Hashable

extension Place: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Place, rhs: Place) -> Bool {
        lhs.id == rhs.id
    }
}

extension Place: LocationRepresentable {
    public var displayName: String? { self.name }
    public var street: String? { address?.street }
    public var locality: String? { address?.locality }
    public var region: String? { address?.region }
    public var country: String? { address?.country }
    public var postalCode: String? { address?.postalCode }
    public var coordinate: (Double, Double)? { (latitude, longitude) }
}

// MARK: - PlaceWithDistance

/// Place enriched with distance information for display
public struct PlaceWithDistance: Identifiable, Sendable {
    public let place: Place
    public let distanceMeters: Double

    public var id: String { place.id }

    public init(place: Place, distanceMeters: Double) {
        self.place = place
        self.distanceMeters = distanceMeters
    }

    /// Formatted distance string for display
    public var formattedDistance: String {
        if distanceMeters < 1000 {
            return String(format: "%.0fm", distanceMeters)
        } else {
            return String(format: "%.1fkm", distanceMeters / 1000)
        }
    }
}

// MARK: - PlaceWithDistance Hashable

extension PlaceWithDistance: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(place.id)
        hasher.combine(distanceMeters)
    }

    public static func == (lhs: PlaceWithDistance, rhs: PlaceWithDistance) -> Bool {
        lhs.place.id == rhs.place.id && lhs.distanceMeters == rhs.distanceMeters
    }
}

// MARK: - Place with Distance (from AnchorPlacesService)

/// Place with distance information
public struct AnchorPlaceWithDistance: Sendable, Identifiable {
    public let place: Place
    public let distance: Double
    /// Category from backend API (for search results)
    public let backendCategory: String?
    /// Icon from backend API (for search results)
    public let backendIcon: String?

    public init(place: Place, distance: Double, backendCategory: String? = nil, backendIcon: String? = nil) {
        self.place = place
        self.distance = distance
        self.backendCategory = backendCategory
        self.backendIcon = backendIcon
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
