import Foundation

// MARK: - Helper Types

/// Empty body for GET requests
private struct EmptyBody: Codable {}

// MARK: - AnchorPDS Request Types

/// Community lexicon location types
public struct CommunityGeoLocation: Codable, Sendable {
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

public struct CommunityAddressLocation: Codable, Sendable {
    public let type: String = "community.lexicon.location.address"
    public let street: String?
    public let locality: String?
    public let region: String?
    public let country: String?
    public let postalCode: String?
    public let name: String?

    private enum CodingKeys: String, CodingKey {
        case street, locality, region, country, postalCode, name
        case type = "$type"
    }

    public init(street: String? = nil, locality: String? = nil, region: String? = nil, country: String? = nil, postalCode: String? = nil, name: String? = nil) {
        self.street = street
        self.locality = locality
        self.region = region
        self.country = country
        self.postalCode = postalCode
        self.name = name
    }
}

public enum LocationItem: Codable, Sendable {
    case geo(CommunityGeoLocation)
    case address(CommunityAddressLocation)

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .geo(geo):
            try container.encode(geo)
        case let .address(address):
            try container.encode(address)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let geo = try? container.decode(CommunityGeoLocation.self) {
            self = .geo(geo)
        } else {
            let address = try container.decode(CommunityAddressLocation.self)
            self = .address(address)
        }
    }
}

/// Lexicon-compliant check-in record - unified model for both creating and reading records
public struct AnchorPDSCheckinRecord: Codable, Sendable {
    public let type: String = "app.dropanchor.checkin"
    public let text: String
    public let createdAt: String
    public let locations: [LocationItem]?
    // Optional place categorization fields
    public let category: String?          // OSM category value (e.g., "restaurant", "climbing", "hotel")
    public let categoryGroup: String?     // Human-readable group (e.g., "Food & Drink", "Sports & Fitness")
    public let categoryIcon: String?      // Unicode emoji icon (e.g., "🍽️", "🧗‍♂️", "🏨")

    private enum CodingKeys: String, CodingKey {
        case text, createdAt, locations, category, categoryGroup, categoryIcon
        case type = "$type"
    }

    public init(
        text: String, 
        createdAt: String, 
        locations: [LocationItem]? = nil,
        category: String? = nil,
        categoryGroup: String? = nil,
        categoryIcon: String? = nil
    ) {
        self.text = text
        self.createdAt = createdAt
        self.locations = locations
        self.category = category
        self.categoryGroup = categoryGroup
        self.categoryIcon = categoryIcon
    }
}

/// AnchorPDS-specific request format
public struct AnchorPDSCreateRecordRequest: Codable {
    let collection: String
    let record: AnchorPDSCheckinRecord
    let rkey: String?

    public init(record: AnchorPDSCheckinRecord, rkey: String? = nil) {
        collection = "app.dropanchor.checkin"
        self.record = record
        self.rkey = rkey
    }
}

// MARK: - AnchorPDS-Specific Response Types

/// Feed response format specific to AnchorPDS (matches your server's schema)
public struct AnchorPDSFeedResponse: Codable {
    let checkins: [AnchorPDSCheckinResponse]
    let cursor: String?

    public init(checkins: [AnchorPDSCheckinResponse], cursor: String? = nil) {
        self.checkins = checkins
        self.cursor = cursor
    }
}

public struct AnchorPDSCheckinResponse: Codable {
    let uri: String
    let cid: String
    let value: AnchorPDSCheckinRecord // Using unified model
    let author: AnchorPDSAuthor

    public init(uri: String, cid: String, value: AnchorPDSCheckinRecord, author: AnchorPDSAuthor) {
        self.uri = uri
        self.cid = cid
        self.value = value
        self.author = author
    }
}

public struct AnchorPDSAuthor: Codable {
    let did: String

    public init(did: String) {
        self.did = did
    }
}

// MARK: - AnchorPDS Error Types

public enum AnchorPDSError: LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case authenticationRequired
    case recordCreationFailed(String)
    case serverError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid AnchorPDS URL"
        case .invalidResponse:
            "Invalid response from AnchorPDS server"
        case let .httpError(code):
            "HTTP error \(code) from AnchorPDS server"
        case let .decodingError(error):
            "Failed to decode AnchorPDS response: \(error.localizedDescription)"
        case .authenticationRequired:
            "Authentication required for AnchorPDS"
        case let .recordCreationFailed(message):
            "Failed to create record on AnchorPDS: \(message)"
        case let .serverError(message):
            "AnchorPDS server error: \(message)"
        }
    }
}

// MARK: - AnchorPDS Client Protocol

@MainActor
public protocol AnchorPDSClientProtocol: Sendable {
    func createRecord(request: AnchorPDSCreateRecordRequest, credentials: AuthCredentials) async throws -> ATProtoCreateRecordResponse
    func listCheckins(user: String?, limit: Int, cursor: String?, credentials: AuthCredentials) async throws -> AnchorPDSFeedResponse
    func getGlobalFeed(limit: Int, cursor: String?, credentials: AuthCredentials) async throws -> AnchorPDSFeedResponse
}

// MARK: - AnchorPDS Client Implementation

@MainActor
public final class AnchorPDSClient: AnchorPDSClientProtocol {
    // MARK: - Properties

    private let session: URLSessionProtocol
    private let baseURL: String

    // MARK: - Initialization

    public init(baseURL: String = AnchorConfig.shared.anchorPDSURL, session: URLSessionProtocol = URLSession.shared) {
        self.baseURL = baseURL
        self.session = session
    }

    // MARK: - Record Creation

    public func createRecord(request: AnchorPDSCreateRecordRequest, credentials: AuthCredentials) async throws -> ATProtoCreateRecordResponse {
        print("🔍 AnchorPDS Request: \(request)")

        let httpRequest = try buildAuthenticatedRequest(
            endpoint: "/xrpc/com.atproto.repo.createRecord",
            method: "POST",
            body: request,
            accessToken: credentials.accessToken
        )

        if let bodyData = httpRequest.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            print("🔍 AnchorPDS Request Body: \(bodyString)")
        }

        let (data, response) = try await session.data(for: httpRequest)
        try validateResponse(response)

        do {
            return try JSONDecoder().decode(ATProtoCreateRecordResponse.self, from: data)
        } catch {
            print("❌ AnchorPDS decode error: \(error)")
            print("❌ Response data: \(String(data: data, encoding: .utf8) ?? "invalid UTF-8")")
            throw AnchorPDSError.decodingError(error)
        }
    }

    // MARK: - Feed Operations

    public func listCheckins(user: String? = nil, limit: Int = AnchorConfig.shared.maxNearbyPlaces, cursor: String? = nil, credentials: AuthCredentials) async throws -> AnchorPDSFeedResponse {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: String(min(limit, 100)))
        ]

        if let user {
            queryItems.append(URLQueryItem(name: "user", value: user))
        }

        if let cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }

        let httpRequest = try buildAuthenticatedRequest(
            endpoint: "/xrpc/app.dropanchor.listCheckins",
            method: "GET",
            body: nil as EmptyBody?,
            queryItems: queryItems,
            accessToken: credentials.accessToken
        )

        let (data, response) = try await session.data(for: httpRequest)
        try validateResponse(response)

        do {
            return try JSONDecoder().decode(AnchorPDSFeedResponse.self, from: data)
        } catch {
            throw AnchorPDSError.decodingError(error)
        }
    }

    public func getGlobalFeed(limit: Int = AnchorConfig.shared.maxNearbyPlaces, cursor: String? = nil, credentials: AuthCredentials) async throws -> AnchorPDSFeedResponse {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: String(min(limit, 100)))
        ]

        if let cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }

        let httpRequest = try buildAuthenticatedRequest(
            endpoint: "/xrpc/app.dropanchor.getGlobalFeed",
            method: "GET",
            body: nil as EmptyBody?,
            queryItems: queryItems,
            accessToken: credentials.accessToken
        )

        let (data, response) = try await session.data(for: httpRequest)
        try validateResponse(response)

        do {
            return try JSONDecoder().decode(AnchorPDSFeedResponse.self, from: data)
        } catch {
            throw AnchorPDSError.decodingError(error)
        }
    }

    // MARK: - Private Methods

    private func buildRequest(
        endpoint: String,
        method: String,
        body: (some Codable)? = nil,
        queryItems: [URLQueryItem]? = nil
    ) throws -> URLRequest {
        guard var urlComponents = URLComponents(string: baseURL + endpoint) else {
            throw AnchorPDSError.invalidURL
        }

        if let queryItems {
            urlComponents.queryItems = queryItems
        }

        guard let url = urlComponents.url else {
            throw AnchorPDSError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Anchor/1.0 (macOS)", forHTTPHeaderField: "User-Agent")

        if let body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                throw AnchorPDSError.decodingError(error)
            }
        }

        return request
    }

    private func buildAuthenticatedRequest(
        endpoint: String,
        method: String,
        body: (some Codable)? = nil,
        queryItems: [URLQueryItem]? = nil,
        accessToken: String
    ) throws -> URLRequest {
        var request = try buildRequest(endpoint: endpoint, method: method, body: body, queryItems: queryItems)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AnchorPDSError.invalidResponse
        }

        guard 200 ... 299 ~= httpResponse.statusCode else {
            switch httpResponse.statusCode {
            case 401:
                throw AnchorPDSError.authenticationRequired
            case 400 ... 499:
                throw AnchorPDSError.httpError(httpResponse.statusCode)
            case 500 ... 599:
                throw AnchorPDSError.serverError("Server error \(httpResponse.statusCode)")
            default:
                throw AnchorPDSError.httpError(httpResponse.statusCode)
            }
        }
    }
}
