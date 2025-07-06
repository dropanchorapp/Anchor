import Foundation

// MARK: - AT Protocol Location Data Models

// Based on community lexicons: community.lexicon.location.geo and community.lexicon.location.address

/// AT Protocol geo location record (community.lexicon.location.geo)
public struct ATProtoGeoLocation: Codable, Sendable {
    /// Latitude in WGS84 coordinate system
    public let lat: Double

    /// Longitude in WGS84 coordinate system
    public let lon: Double

    /// Optional name/description of the location
    public let name: String?

    /// Optional altitude in meters
    public let alt: Double?

    public init(lat: Double, lon: Double, name: String? = nil, alt: Double? = nil) {
        self.lat = lat
        self.lon = lon
        self.name = name
        self.alt = alt
    }
}

/// AT Protocol address record (community.lexicon.location.address)
public struct ATProtoAddress: Codable, Sendable {
    /// ISO 3166-1 alpha-2 country code
    public let country: String?

    /// City, town, or other locality
    public let locality: String?

    /// State, province, or region
    public let region: String?

    /// Street address including house number and street name
    public let streetAddress: String?

    /// Postal/ZIP code
    public let postalCode: String?

    public init(
        country: String? = nil,
        locality: String? = nil,
        region: String? = nil,
        streetAddress: String? = nil,
        postalCode: String? = nil
    ) {
        self.country = country
        self.locality = locality
        self.region = region
        self.streetAddress = streetAddress
        self.postalCode = postalCode
    }
}

/// Container for location data that can be attached to AT Protocol posts
public struct ATProtoLocationRecord: Codable, Sendable {
    /// Geographic coordinates
    public let geo: ATProtoGeoLocation?

    /// Address information
    public let address: ATProtoAddress?

    /// Optional reference to Foursquare OS Places (future extension)
    public let fsq: String?

    public init(
        geo: ATProtoGeoLocation? = nil,
        address: ATProtoAddress? = nil,
        fsq: String? = nil
    ) {
        self.geo = geo
        self.address = address
        self.fsq = fsq
    }
}

extension ATProtoAddress: LocationRepresentable {
    public var displayName: String? { streetAddress }
    public var street: String? { streetAddress }
    public var coordinate: (Double, Double)? { nil }
}

extension ATProtoGeoLocation: LocationRepresentable {
    public var displayName: String? { name }
    public var street: String? { nil }
    public var locality: String? { nil }
    public var region: String? { nil }
    public var country: String? { nil }
    public var postalCode: String? { nil }
    public var coordinate: (Double, Double)? { (lat, lon) }
}
