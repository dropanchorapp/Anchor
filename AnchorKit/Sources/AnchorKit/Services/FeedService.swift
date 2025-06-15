import Foundation

/// Service for fetching check-in feeds from AnchorPDS with Bluesky profile enrichment
@MainActor
@Observable
public final class FeedService {
    // MARK: - Properties

    private let anchorPDSService: AnchorPDSService
    private let session: URLSessionProtocol
    private let baseURL = "https://bsky.social"

    /// Current feed posts
    @MainActor
    public private(set) var posts: [FeedPost] = []

    /// Loading state
    @MainActor
    public private(set) var isLoading = false

    /// Error state
    @MainActor
    public private(set) var error: FeedError?

    // MARK: - Initialization

    public init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
        anchorPDSService = AnchorPDSService(session: session)
    }

    // MARK: - Convenience Initializers

    @MainActor
    public static func create(session: URLSessionProtocol = URLSession.shared) -> FeedService {
        FeedService(session: session)
    }

    // MARK: - Feed Fetching

    /// Fetch global check-in feed from AnchorPDS
    /// - Parameter credentials: Authentication credentials
    /// - Returns: Success status
    public func fetchFollowingFeed(credentials: AuthCredentialsProtocol) async throws -> Bool {
        try await fetchGlobalFeed(credentials: credentials)
    }

    /// Fetch global check-in feed from AnchorPDS
    /// - Parameter credentials: Authentication credentials
    /// - Returns: Success status
    public func fetchGlobalFeed(credentials: AuthCredentialsProtocol) async throws -> Bool {
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            // Convert credentials to AuthCredentials if needed
            let authCredentials: AuthCredentials = if let creds = credentials as? AuthCredentials {
                creds
            } else {
                // Create AuthCredentials from protocol
                AuthCredentials(
                    handle: credentials.handle,
                    accessToken: credentials.accessToken,
                    refreshToken: credentials.refreshToken,
                    did: credentials.did,
                    expiresAt: credentials.expiresAt
                )
            }

            // Fetch global feed from AnchorPDS
            let feedResponse = try await anchorPDSService.getGlobalFeed(
                limit: 50,
                cursor: nil,
                credentials: authCredentials
            )

            // Convert AnchorPDS responses to FeedPost format with profile enrichment
            var enrichedPosts: [FeedPost] = []

            for checkinResponse in feedResponse.checkins {
                // Get profile info from Bluesky for this DID
                let profileInfo = await getProfileInfo(for: checkinResponse.author.did)

                let feedPost = FeedPost(from: checkinResponse, profileInfo: profileInfo)
                enrichedPosts.append(feedPost)
            }

            posts = enrichedPosts
            return true

        } catch AnchorPDSError.authenticationRequired {
            // Handle AnchorPDS authentication specifically
            self.error = FeedError.authenticationError("AnchorPDS authentication is currently unavailable. This is an experimental feature - check-ins are still being saved to AnchorPDS, but the global feed cannot be displayed right now.")
            posts = [] // Clear any existing posts
            return false
            
        } catch {
            self.error = FeedError.decodingError(error)
            throw error
        }
    }

    // MARK: - Private Methods

    /// Get profile information from Bluesky for a given DID
    /// - Parameter did: The DID to look up
    /// - Returns: Profile information or nil if not found
    private func getProfileInfo(for did: String) async -> BlueskyProfileInfo? {
        do {
            // Build request to Bluesky's public API
            guard let url = URL(string: "https://public.api.bsky.app/xrpc/app.bsky.actor.getProfile?actor=\(did)") else {
                return nil
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Anchor/1.0 (macOS)", forHTTPHeaderField: "User-Agent")

            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200
            else {
                return nil
            }

            let profileResponse = try JSONDecoder().decode(BlueskyProfileResponse.self, from: data)

            return BlueskyProfileInfo(
                did: profileResponse.did,
                handle: profileResponse.handle,
                displayName: profileResponse.displayName,
                avatar: profileResponse.avatar
            )

        } catch {
            print("Failed to fetch profile for DID \(did): \(error)")
            return nil
        }
    }

    private func buildAuthenticatedRequest(
        endpoint: String,
        method: String,
        accessToken: String
    ) throws -> URLRequest {
        guard let url = URL(string: baseURL + endpoint) else {
            throw FeedError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Anchor/1.0 (macOS)", forHTTPHeaderField: "User-Agent")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        return request
    }
}

// MARK: - Models

public struct FeedPost: Identifiable, Sendable {
    public let id: String
    public let author: FeedAuthor
    public let record: ATProtoRecord
    public let checkinRecord: AnchorPDSCheckinRecord?

    init(from feedItem: TimelineFeedItem) {
        id = feedItem.post.uri
        author = FeedAuthor(from: feedItem.post.author)
        record = ATProtoRecord(from: feedItem.post.record)

        // Extract checkin record if available
        if let embed = feedItem.post.embed,
           embed.record != nil {
            checkinRecord = nil // Legacy support
        } else {
            checkinRecord = nil
        }
    }

    // New initializer for AnchorPDS responses
    init(from checkinResponse: AnchorPDSCheckinResponse, profileInfo: BlueskyProfileInfo?) {
        id = checkinResponse.uri
        author = FeedAuthor(
            did: checkinResponse.author.did,
            handle: profileInfo?.handle ?? checkinResponse.author.did,
            displayName: profileInfo?.displayName,
            avatar: profileInfo?.avatar
        )
        record = ATProtoRecord(
            text: checkinResponse.value.text,
            createdAt: ISO8601DateFormatter().date(from: checkinResponse.value.createdAt) ?? Date()
        )
        checkinRecord = checkinResponse.value
    }
}

public struct FeedAuthor: Sendable {
    public let did: String
    public let handle: String
    public let displayName: String?
    public let avatar: String?

    init(from author: TimelineAuthor) {
        did = author.did
        handle = author.handle
        displayName = author.displayName
        avatar = author.avatar
    }

    // New initializer for AnchorPDS responses with profile info
    init(did: String, handle: String, displayName: String?, avatar: String?) {
        self.did = did
        self.handle = handle
        self.displayName = displayName
        self.avatar = avatar
    }
}

public struct BlueskyProfileInfo: Sendable {
    public let did: String
    public let handle: String
    public let displayName: String?
    public let avatar: String?
}

public struct CheckinEmbedRecord: Sendable {
    public let uri: String
    public let cid: String
    public let text: String?
    public let locations: [String] // Simplified for now

    init(from record: EmbedRecordView) {
        uri = record.uri ?? ""
        cid = record.cid ?? ""

        // For now, just store basic info
        // In a full implementation, we'd parse the actual checkin record
        text = nil
        locations = []
    }
}

// MARK: - API Response Models

struct BlueskyProfileResponse: Codable {
    let did: String
    let handle: String
    let displayName: String?
    let avatar: String?
    let description: String?
    let followersCount: Int?
    let followsCount: Int?
    let postsCount: Int?

    // We only need the basic fields for our use case
    private enum CodingKeys: String, CodingKey {
        case did, handle, displayName, avatar, description
        case followersCount, followsCount, postsCount
    }
}

struct TimelineResponse: Codable {
    let feed: [TimelineFeedItem]
    let cursor: String?
}

struct TimelineFeedItem: Codable {
    let post: TimelinePost
    let reason: TimelineReason?
}

struct TimelinePost: Codable {
    let uri: String
    let cid: String
    let author: TimelineAuthor
    let record: TimelineRecord
    let embed: PostEmbedView?
    let replyCount: Int?
    let repostCount: Int?
    let likeCount: Int?
    let indexedAt: String
}

struct TimelineAuthor: Codable {
    let did: String
    let handle: String
    let displayName: String?
    let avatar: String?
}

struct PostEmbedView: Codable {
    let type: String
    let record: EmbedRecordView?

    private enum CodingKeys: String, CodingKey {
        case record
        case type = "$type"
    }
}

struct EmbedRecordView: Codable {
    let uri: String?
    let cid: String?
    let value: EmbedRecordValue?
}

struct EmbedRecordValue: Codable {
    let type: String
    let text: String?
    let createdAt: String?

    private enum CodingKeys: String, CodingKey {
        case text, createdAt
        case type = "$type"
    }
}

struct TimelineReason: Codable {
    let type: String

    private enum CodingKeys: String, CodingKey {
        case type = "$type"
    }
}

// MARK: - Error Types

public enum FeedError: LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case authenticationError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid feed API URL"
        case .invalidResponse:
            "Invalid response from feed API"
        case let .httpError(code):
            "HTTP error \(code) from feed API"
        case let .decodingError(error):
            "Failed to decode feed response: \(error.localizedDescription)"
        case let .authenticationError(message):
            message
        }
    }
}
