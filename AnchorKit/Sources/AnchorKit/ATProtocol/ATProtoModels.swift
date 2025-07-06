// swiftlint:disable file_length
import Foundation

// MARK: - Authentication Models

public struct ATProtoLoginRequest: Codable, Sendable {
    let identifier: String
    let password: String
}

public struct ATProtoLoginResponse: Codable, Sendable {
    let accessJwt: String
    let refreshJwt: String
    let handle: String
    let did: String
    let expiresIn: Int? // Token expiration time in seconds

    private enum CodingKeys: String, CodingKey {
        case accessJwt, refreshJwt, handle, did
        case expiresIn = "expires_in"
    }
}

public struct ATProtoRefreshRequest: Codable, Sendable {
    let refreshJwt: String
}

public struct ATProtoRefreshResponse: Codable, Sendable {
    let accessJwt: String
    let refreshJwt: String
    let expiresIn: Int? // Token expiration time in seconds

    private enum CodingKeys: String, CodingKey {
        case accessJwt, refreshJwt
        case expiresIn = "expires_in"
    }
}

// MARK: - Post Models

public struct ATProtoCreatePostRequest: Codable {
    let collection: String = "app.bsky.feed.post"
    let repo: String
    let record: ATProtoPostRecord

    private enum CodingKeys: String, CodingKey {
        case collection, repo, record
    }
}

public struct ATProtoPostRecord: Codable {
    let type: String = "app.bsky.feed.post"
    let text: String
    let createdAt: String
    let facets: [RichTextFacet]?
    let embed: ATProtoPostEmbed?

    private enum CodingKeys: String, CodingKey {
        case text, createdAt, facets, embed
        case type = "$type"
    }
}

// MARK: - Embed Models

public struct ATProtoPostEmbed: Codable {
    let type: String = "app.bsky.embed.record"
    let record: ATProtoEmbedRecord

    private enum CodingKeys: String, CodingKey {
        case record
        case type = "$type"
    }
}

public struct ATProtoEmbedRecord: Codable {
    let uri: String
    let cid: String
}

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

/// Request for creating address records
public struct ATProtoCreateAddressRequest: Codable {
    let collection: String
    let repo: String
    let record: CommunityAddressRecord

    public init(repo: String, record: CommunityAddressRecord) {
        self.collection = "community.lexicon.location.address"
        self.repo = repo
        self.record = record
    }
}

/// Request for creating checkin records with strongref
public struct ATProtoCreateCheckinRequest: Codable {
    let collection: String
    let repo: String
    let record: CheckinRecord

    public init(repo: String, record: CheckinRecord) {
        self.collection = "app.dropanchor.checkin"
        self.repo = repo
        self.record = record
    }
}

public struct ATProtoCreateRecordResponse: Codable, Sendable {
    let uri: String
    let cid: String
}

/// Response for getting records
public struct ATProtoGetRecordResponse: Codable, Sendable {
    public let uri: String
    public let cid: String
    public let value: Data // Raw JSON data

    private enum CodingKeys: String, CodingKey {
        case uri, cid, value
    }

    public init(uri: String, cid: String, value: Data) {
        self.uri = uri
        self.cid = cid
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uri = try container.decode(String.self, forKey: .uri)
        cid = try container.decode(String.self, forKey: .cid)

        // Store the raw JSON for flexible decoding
        let valueContainer = try container.nestedContainer(keyedBy: AnyCodingKey.self, forKey: .value)
        let valueDict = try valueContainer.decode()
        value = try JSONSerialization.data(withJSONObject: valueDict, options: [])
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uri, forKey: .uri)
        try container.encode(cid, forKey: .cid)

        // Encode raw data as base64 string for JSON compatibility
        let base64String = value.base64EncodedString()
        try container.encode(base64String, forKey: .value)
    }
}

/// Helper for dynamic JSON decoding
private struct AnyCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

private extension KeyedDecodingContainer where Key == AnyCodingKey {
    func decode() throws -> [String: Any] {
        var result: [String: Any] = [:]
        for key in allKeys {
            if let value = try? decodeSingleValue(forKey: key) {
                result[key.stringValue] = value
            } else if let nested = try? nestedContainer(keyedBy: AnyCodingKey.self, forKey: key) {
                result[key.stringValue] = try nested.decode()
            } else if var nested = try? nestedUnkeyedContainer(forKey: key) {
                result[key.stringValue] = try decodeArray(&nested)
            }
        }
        return result
    }

    private func decodeSingleValue(forKey key: Key) throws -> Any? {
        if let value = try? decode(String.self, forKey: key) {
            return value
        } else if let value = try? decode(Int.self, forKey: key) {
            return value
        } else if let value = try? decode(Double.self, forKey: key) {
            return value
        } else if let value = try? decode(Bool.self, forKey: key) {
            return value
        }
        return nil
    }

    private func decodeArray(_ nested: inout UnkeyedDecodingContainer) throws -> [Any] {
        var array: [Any] = []
        while !nested.isAtEnd {
            if let value = try? nested.decode(String.self) {
                array.append(value)
            } else if let value = try? nested.decode(Int.self) {
                array.append(value)
            } else if let value = try? nested.decode(Double.self) {
                array.append(value)
            } else if let value = try? nested.decode(Bool.self) {
                array.append(value)
            }
        }
        return array
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
