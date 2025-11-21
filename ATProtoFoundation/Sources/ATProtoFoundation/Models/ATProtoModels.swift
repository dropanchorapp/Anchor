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

// MARK: - Rich Text Models

public struct RichTextFacet: Codable, Sendable {
    public let index: ByteRange
    public let features: [RichTextFeature]

    public init(index: ByteRange, features: [RichTextFeature]) {
        self.index = index
        self.features = features
    }
}

public struct ByteRange: Codable, Sendable {
    public let byteStart: Int
    public let byteEnd: Int

    public init(byteStart: Int, byteEnd: Int) {
        self.byteStart = byteStart
        self.byteEnd = byteEnd
    }
}

public enum RichTextFeature: Codable, Sendable {
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
