import Foundation

/// Observable store for managing check-in feeds from AnchorPDS with Bluesky profile enrichment
///
/// Manages feed state and coordinates with AnchorPDS services.
/// Provides observable feed state for UI binding.
///
/// Responsibilities:
/// - Observable feed state for UI (posts, loading, errors)
/// - Coordinate feed fetching operations
/// - Manage profile enrichment from Bluesky
/// - Handle feed-related business logic
@MainActor
@Observable
public final class FeedStore {
    // MARK: - Properties

    private let authStore: AuthStoreProtocol
    private let anchorPDSService: AnchorPDSService
    private let session: URLSessionProtocol
    private let multiPDSClient: MultiPDSClient
    private let baseURL = AnchorConfig.shared.blueskyPDSURL
    
    /// Current loading task for cancellation
    @MainActor
    private var loadingTask: Task<Bool, Error>?

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

    public init(authStore: AuthStoreProtocol, session: URLSessionProtocol = URLSession.shared) {
        self.authStore = authStore
        self.session = session
        self.multiPDSClient = MultiPDSClient(session: session)
        anchorPDSService = AnchorPDSService(session: session)
    }

    // MARK: - Feed Fetching
    
    /// Cancel any ongoing feed loading operation
    @MainActor
    public func cancelLoading() {
        loadingTask?.cancel()
        isLoading = false
    }

    /// Fetch global check-in feed from AnchorPDS
    /// - Returns: Success status
    @MainActor
    public func fetchFollowingFeed() async throws -> Bool {
        return try await fetchGlobalFeed()
    }

    /// Fetch global check-in feed from AnchorPDS
    /// - Returns: Success status
    @MainActor
    public func fetchGlobalFeed() async throws -> Bool {
        print("🔄 FeedStore: Starting fetchGlobalFeed...")
        
        // Cancel any existing loading task
        loadingTask?.cancel()
        
        // Create a new task for this operation
        let task = Task<Bool, Error> {
            isLoading = true
            error = nil
            print("🔄 FeedStore: Set loading state to true")

            defer { 
                isLoading = false 
                print("🔄 FeedStore: Set loading state to false")
            }

            do {
                // Check for cancellation before starting network operations
                try Task.checkCancellation()
                
                // Get valid credentials (handles refresh automatically)
                print("🔑 FeedStore: Getting valid credentials...")
                let credentials = try await authStore.getValidCredentials()
                print("🔑 FeedStore: Got credentials for \(credentials.handle)")
                
                // Fetch global feed from AnchorPDS
                print("📡 FeedStore: Fetching global feed from AnchorPDS...")
                let feedResponse = try await anchorPDSService.getGlobalFeed(
                    limit: AnchorConfig.shared.maxNearbyPlaces,
                    cursor: nil,
                    credentials: credentials
                )
                print("📡 FeedStore: Received \(feedResponse.checkins.count) check-ins from AnchorPDS")

                // Check for cancellation before processing results
                try Task.checkCancellation()

                // Convert AnchorPDS responses to FeedPost format with profile enrichment
                var enrichedPosts: [FeedPost] = []

                for (index, checkinResponse) in feedResponse.checkins.enumerated() {
                    // Check for cancellation during processing
                    try Task.checkCancellation()
                    
                    print("👤 FeedStore: Processing check-in \(index + 1)/\(feedResponse.checkins.count) from \(checkinResponse.author.did)")
                    
                    // Get profile info from Bluesky for this DID using authentication
                    let profileInfo = await getProfileInfo(for: checkinResponse.author.did, accessToken: credentials.accessToken)

                    let feedPost = FeedPost(from: checkinResponse, profileInfo: profileInfo)
                    enrichedPosts.append(feedPost)
                    print("✅ FeedStore: Added enriched post for \(checkinResponse.author.did)")
                }

                // Final cancellation check before updating UI
                try Task.checkCancellation()
                
                posts = enrichedPosts
                print("✅ FeedStore: Updated posts array with \(enrichedPosts.count) items")
                return true

            } catch AnchorPDSError.authenticationRequired {
                // Handle AnchorPDS authentication specifically
                print("🚫 FeedStore: AnchorPDS authentication required")
                self.error = FeedError.authenticationError(
                    "AnchorPDS authentication is currently unavailable. This is an experimental feature - " +
                        "check-ins are still being saved to AnchorPDS, but the global feed cannot be displayed right now."
                )
                posts = [] // Clear any existing posts
                return false

            } catch is CancellationError {
                // Handle cancellation gracefully - don't update error state
                print("⏹️ FeedStore: Feed loading was cancelled")
                return false
                
            } catch {
                print("❌ FeedStore: Feed loading failed with error: \(error)")
                self.error = FeedError.decodingError(error)
                throw error
            }
        }
        
        // Store the task for potential cancellation
        loadingTask = task
        
        // Wait for the task to complete
        let result = try await task.value
        print("🏁 FeedStore: fetchGlobalFeed completed with result: \(result)")
        return result
    }

    // MARK: - Private Methods

    /// Get profile information using multi-PDS discovery with fallback
    /// - Parameters:
    ///   - did: The DID to look up
    ///   - accessToken: Access token for making authenticated requests
    /// - Returns: Profile information or nil if not found
    private func getProfileInfo(for did: String, accessToken: String) async -> BlueskyProfileInfo? {
        // Use MultiPDSClient to try user's home PDS first, then fallback to Bluesky with authentication
        return await multiPDSClient.getProfileInfo(for: did, accessToken: accessToken)
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

public struct FeedPost: Identifiable, Sendable, Hashable {
    public let id: String
    public let author: FeedAuthor
    public let record: ATProtoRecord
    public let checkinRecord: AnchorPDSCheckinRecord?

    // Public initializer for testing and previews
    public init(id: String, author: FeedAuthor, record: ATProtoRecord, checkinRecord: AnchorPDSCheckinRecord?) {
        self.id = id
        self.author = author
        self.record = record
        self.checkinRecord = checkinRecord
    }

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

public struct FeedAuthor: Sendable, Hashable {
    public let did: String
    public let handle: String
    public let displayName: String?
    public let avatar: String?

    // Public initializer for testing and previews
    public init(did: String, handle: String, displayName: String?, avatar: String?) {
        self.did = did
        self.handle = handle
        self.displayName = displayName
        self.avatar = avatar
    }

    init(from author: TimelineAuthor) {
        did = author.did
        handle = author.handle
        displayName = author.displayName
        avatar = author.avatar
    }
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
