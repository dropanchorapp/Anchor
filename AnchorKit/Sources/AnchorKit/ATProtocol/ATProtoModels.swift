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

public struct ATProtoCreateRecordResponse: Codable, Sendable {
    let uri: String
    let cid: String
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
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown rich text feature type: \(type)")
            )
        }
    }
}

// MARK: - Error Types

public enum ATProtoError: LocalizedError, Sendable {
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
}
