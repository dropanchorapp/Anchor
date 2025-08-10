import Foundation

// MARK: - StrongRef Models

/// AT Protocol StrongRef for referencing records with content integrity verification
public struct StrongRef: Codable, Sendable, Hashable {
    /// AT URI pointing to the referenced record
    public let uri: String

    /// CID (Content Identifier) for content integrity verification
    public let cid: String

    public init(uri: String, cid: String) {
        self.uri = uri
        self.cid = cid
    }
}

// MARK: - StrongRef Record Models

/// Geographic coordinates using community lexicon format
public struct GeoCoordinates: Codable, Sendable, Hashable {
    public let type: String = "community.lexicon.location.geo"
    public let latitude: String
    public let longitude: String

    private enum CodingKeys: String, CodingKey {
        case latitude, longitude
        case type = "$type"
    }

    public init(latitude: Double, longitude: Double) {
        self.latitude = String(latitude)
        self.longitude = String(longitude)
    }
}

/// Community address record for separate storage and referencing
public struct CommunityAddressRecord: Codable, Sendable, Hashable {
    public let type: String = "community.lexicon.location.address"
    public let name: String?
    public let street: String?
    public let locality: String?
    public let region: String?
    public let country: String?
    public let postalCode: String?

    private enum CodingKeys: String, CodingKey {
        case name, street, locality, region, country, postalCode
        case type = "$type"
    }

    public init(
        name: String? = nil,
        street: String? = nil,
        locality: String? = nil,
        region: String? = nil,
        country: String? = nil,
        postalCode: String? = nil
    ) {
        self.name = name
        self.street = street
        self.locality = locality
        self.region = region
        self.country = country
        self.postalCode = postalCode
    }
}

/// New checkin record using StrongRef to reference separate address records
public struct CheckinRecord: Codable, Sendable, Hashable {
    public let type: String = "app.dropanchor.checkin"
    public let text: String
    public let createdAt: String
    public let addressRef: StrongRef
    public let coordinates: GeoCoordinates

    // Optional place categorization fields
    public let category: String?
    public let categoryGroup: String?
    public let categoryIcon: String?

    private enum CodingKeys: String, CodingKey {
        case text, createdAt, addressRef, coordinates, category, categoryGroup, categoryIcon
        case type = "$type"
    }

    public init(
        text: String,
        createdAt: String,
        addressRef: StrongRef,
        coordinates: GeoCoordinates,
        category: String? = nil,
        categoryGroup: String? = nil,
        categoryIcon: String? = nil
    ) {
        self.text = text
        self.createdAt = createdAt
        self.addressRef = addressRef
        self.coordinates = coordinates
        self.category = category
        self.categoryGroup = categoryGroup
        self.categoryIcon = categoryIcon
    }
}

// MARK: - StrongRef Checkin Models

/// Error types for checkin content integrity
public enum CheckinError: LocalizedError, Sendable {
    case addressContentMismatch
    case missingLocationData
    case invalidFormat

    public var errorDescription: String? {
        switch self {
        case .addressContentMismatch:
            "Address record content has been modified since checkin creation"
        case .missingLocationData:
            "Checkin record is missing location data"
        case .invalidFormat:
            "Invalid checkin record format"
        }
    }
}

/// Resolved checkin with address data from strongref
public struct ResolvedCheckin: Sendable {
    public let checkin: CheckinRecord
    public let address: CommunityAddressRecord
    public let isVerified: Bool // CID verification result

    public init(checkin: CheckinRecord, address: CommunityAddressRecord, isVerified: Bool = true) {
        self.checkin = checkin
        self.address = address
        self.isVerified = isVerified
    }
}

// MARK: - Rich Text Models

public struct RichTextFacet: Codable {
    public let index: ByteRange
    public let features: [RichTextFeature]

    public init(index: ByteRange, features: [RichTextFeature]) {
        self.index = index
        self.features = features
    }
}

public struct ByteRange: Codable {
    public let byteStart: Int
    public let byteEnd: Int

    public init(byteStart: Int, byteEnd: Int) {
        self.byteStart = byteStart
        self.byteEnd = byteEnd
    }
}

public enum RichTextFeature: Codable {
    case link(uri: String)
    case mention(did: String)
    case tag(tag: String)

    private enum CodingKeys: String, CodingKey {
        case type = "$type"
        case uri, did, tag
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .link(uri):
            try container.encode("app.bsky.richtext.facet#link", forKey: .type)
            try container.encode(uri, forKey: .uri)
        case let .mention(did):
            try container.encode("app.bsky.richtext.facet#mention", forKey: .type)
            try container.encode(did, forKey: .did)
        case let .tag(tag):
            try container.encode("app.bsky.richtext.facet#tag", forKey: .type)
            try container.encode(tag, forKey: .tag)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "app.bsky.richtext.facet#link":
            let uri = try container.decode(String.self, forKey: .uri)
            self = .link(uri: uri)
        case "app.bsky.richtext.facet#mention":
            let did = try container.decode(String.self, forKey: .did)
            self = .mention(did: did)
        case "app.bsky.richtext.facet#tag":
            let tag = try container.decode(String.self, forKey: .tag)
            self = .tag(tag: tag)
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unknown rich text feature type: \(type)"
                )
            )
        }
    }
}

// MARK: - Error Types

public enum ATProtoError: LocalizedError, Sendable, Equatable {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case authenticationFailed(String)
    case missingCredentials

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid AT Protocol URL"
        case .invalidResponse:
            "Invalid response from AT Protocol server"
        case let .httpError(code):
            "HTTP error \(code) from AT Protocol server"
        case let .decodingError(error):
            "Failed to decode AT Protocol response: \(error.localizedDescription)"
        case let .authenticationFailed(message):
            "AT Protocol authentication failed: \(message)"
        case .missingCredentials:
            "Missing or invalid AT Protocol credentials"
        }
    }

    public static func == (lhs: ATProtoError, rhs: ATProtoError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.invalidResponse, .invalidResponse),
             (.missingCredentials, .missingCredentials):
            return true
        case let (.httpError(lhsCode), .httpError(rhsCode)):
            return lhsCode == rhsCode
        case let (.authenticationFailed(lhsMessage), .authenticationFailed(rhsMessage)):
            return lhsMessage == rhsMessage
        case let (.decodingError(lhsError), .decodingError(rhsError)):
            // Compare error descriptions since Error doesn't conform to Equatable
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}
