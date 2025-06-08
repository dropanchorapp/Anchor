import Foundation

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
    
    public init(
        elementType: ElementType,
        elementId: Int64,
        name: String,
        latitude: Double,
        longitude: Double,
        tags: [String: String] = [:]
    ) {
        self.elementType = elementType
        self.elementId = elementId
        self.id = "\(elementType.rawValue):\(elementId)"
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.tags = tags
    }
}

// MARK: - ElementType
extension Place {
    public enum ElementType: String, Codable, CaseIterable, Sendable {
        case node = "node"
        case way = "way"
        case relation = "relation"
    }
}

// MARK: - Convenience Methods
extension Place {
    /// Parse a place ID string into element type and ID
    /// - Parameter placeId: String in format "type:id" (e.g., "way:123456")
    /// - Returns: Tuple of (ElementType, Int64) or nil if invalid format
    public static func parseId(_ placeId: String) -> (ElementType, Int64)? {
        let components = placeId.split(separator: ":")
        guard components.count == 2,
              let elementType = ElementType(rawValue: String(components[0])),
              let elementId = Int64(components[1]) else {
            return nil
        }
        return (elementType, elementId)
    }
    
    /// Returns a human-readable description with coordinates
    public var description: String {
        "\(name) (\(String(format: "%.6f", latitude)), \(String(format: "%.6f", longitude)))"
    }
    
    /// Returns the amenity or leisure type from tags
    public var category: String? {
        tags["amenity"] ?? tags["leisure"] ?? tags["shop"]
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