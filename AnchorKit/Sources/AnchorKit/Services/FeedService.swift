import Foundation

/// Service for fetching check-in feeds from AnchorPDS with Bluesky profile enrichment
@MainActor
@Observable
public final class FeedService: Sendable {

    // MARK: - Properties

    private let anchorPDSService: AnchorPDSService
    private let blueskyService: BlueskyService
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
        self.anchorPDSService = AnchorPDSService(session: session)
        self.blueskyService = BlueskyService()
    }
    
    // MARK: - Convenience Initializers
    
    @MainActor
    public static func create(session: URLSessionProtocol = URLSession.shared) -> FeedService {
        return FeedService(session: session)
    }

    // MARK: - Feed Fetching

    /// Fetch global check-in feed from AnchorPDS
    /// - Parameter credentials: Authentication credentials
    /// - Returns: Success status
    public func fetchFollowingFeed(credentials: AuthCredentialsProtocol) async throws -> Bool {
        return try await fetchGlobalFeed(credentials: credentials)
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
            let authCredentials: AuthCredentials
            if let creds = credentials as? AuthCredentials {
                authCredentials = creds
            } else {
                // Create AuthCredentials from protocol
                authCredentials = AuthCredentials(
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
        // For now, return a basic profile with just the DID
        // In a full implementation, we'd call Bluesky's profile API
        return BlueskyProfileInfo(
            did: did,
            handle: extractHandleFromDID(did) ?? did,
            displayName: nil,
            avatar: nil
        )
    }
    
    /// Extract handle from DID (simplified)
    /// - Parameter did: The DID string
    /// - Returns: Handle if extractable, nil otherwise
    private func extractHandleFromDID(_ did: String) -> String? {
        // This is a simplified implementation
        // In reality, you'd need to resolve the DID to get the handle
        return nil
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

    internal init(from feedItem: TimelineFeedItem) {
        self.id = feedItem.post.uri
        self.author = FeedAuthor(from: feedItem.post.author)
        self.record = ATProtoRecord(from: feedItem.post.record)

        // Extract checkin record if available
        if let embed = feedItem.post.embed,
           let _ = embed.record {
            self.checkinRecord = nil // Legacy support
        } else {
            self.checkinRecord = nil
        }
    }
    
    // New initializer for AnchorPDS responses
    internal init(from checkinResponse: AnchorPDSCheckinResponse, profileInfo: BlueskyProfileInfo?) {
        self.id = checkinResponse.uri
        self.author = FeedAuthor(
            did: checkinResponse.author.did,
            handle: profileInfo?.handle ?? checkinResponse.author.did,
            displayName: profileInfo?.displayName,
            avatar: profileInfo?.avatar
        )
        self.record = ATProtoRecord(
            text: checkinResponse.value.text,
            createdAt: ISO8601DateFormatter().date(from: checkinResponse.value.createdAt) ?? Date()
        )
        self.checkinRecord = checkinResponse.value
    }
}

public struct FeedAuthor: Sendable {
    public let did: String
    public let handle: String
    public let displayName: String?
    public let avatar: String?

    internal init(from author: TimelineAuthor) {
        self.did = author.did
        self.handle = author.handle
        self.displayName = author.displayName
        self.avatar = author.avatar
    }
    
    // New initializer for AnchorPDS responses with profile info
    internal init(did: String, handle: String, displayName: String?, avatar: String?) {
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

    internal init(from record: EmbedRecordView) {
        self.uri = record.uri ?? ""
        self.cid = record.cid ?? ""

        // For now, just store basic info
        // In a full implementation, we'd parse the actual checkin record
        self.text = nil
        self.locations = []
    }
}

// MARK: - API Response Models

internal struct TimelineResponse: Codable {
    let feed: [TimelineFeedItem]
    let cursor: String?
}

internal struct TimelineFeedItem: Codable {
    let post: TimelinePost
    let reason: TimelineReason?
}

internal struct TimelinePost: Codable {
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

internal struct TimelineAuthor: Codable {
    let did: String
    let handle: String
    let displayName: String?
    let avatar: String?
}

internal struct PostEmbedView: Codable {
    let type: String
    let record: EmbedRecordView?

    private enum CodingKeys: String, CodingKey {
        case record
        case type = "$type"
    }
}

internal struct EmbedRecordView: Codable {
    let uri: String?
    let cid: String?
    let value: EmbedRecordValue?
}

internal struct EmbedRecordValue: Codable {
    let type: String
    let text: String?
    let createdAt: String?

    private enum CodingKeys: String, CodingKey {
        case text, createdAt
        case type = "$type"
    }
}

internal struct TimelineReason: Codable {
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

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid feed API URL"
        case .invalidResponse:
            return "Invalid response from feed API"
        case .httpError(let code):
            return "HTTP error \(code) from feed API"
        case .decodingError(let error):
            return "Failed to decode feed response: \(error.localizedDescription)"
        }
    }
}
