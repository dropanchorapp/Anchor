import Foundation

/// Wrapper class for FeedPost to use with NSCache
private final class FeedPostWrapper {
    let post: FeedPost

    init(_ post: FeedPost) {
        self.post = post
    }
}

/// Observable store for managing check-in feeds from the Anchor feed service
///
/// **PDS-Only Architecture**: Manages personal timeline only, focused on location logging
/// Manages feed state and coordinates with the Anchor Feed API.
/// Provides observable feed state for UI binding.
///
/// Responsibilities:
/// - Observable feed state for UI (posts, loading, errors)
/// - Coordinate user feed fetching operations (personal timeline)
/// - Handle feed-related business logic
@MainActor
@Observable
public final class FeedStore {
    // MARK: - Properties

    private let feedService: AnchorFeedServiceProtocol
    private let session: URLSessionProtocol

    // Cache
    private let feedPostCache = NSCache<NSString, FeedPostWrapper>()

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

    public init(feedService: AnchorFeedServiceProtocol? = nil, session: URLSessionProtocol = URLSession.shared) {
        self.session = session
        self.feedService = feedService ?? AnchorFeedService(session: session)

        // Configure cache
        feedPostCache.countLimit = 1000 // Cache for recent posts
    }

    // MARK: - Feed Fetching

    /// Cancel any ongoing feed loading operation
    @MainActor
    public func cancelLoading() {
        loadingTask?.cancel()
        isLoading = false
    }

    /// Fetch user's personal timeline from the AppView
    /// **PDS-Only Architecture**: Only personal timeline is supported
    /// - Parameter userDid: DID of the user to get feed for
    /// - Returns: Success status
    @MainActor
    public func fetchUserFeed(for userDid: String) async throws -> Bool {
        debugPrint("🔄 FeedStore: Starting user feed for \(userDid)...")

        loadingTask?.cancel()

        let task = Task<Bool, Error> {
            isLoading = true
            error = nil

            defer {
                isLoading = false
            }

            do {
                try Task.checkCancellation()

                let feedResponse = try await feedService.getUserCheckins(
                    did: userDid,
                    limit: AnchorConfig.shared.maxNearbyPlaces,
                    cursor: nil
                )

                try Task.checkCancellation()

                var feedPosts: [FeedPost] = []
                for checkin in feedResponse.checkins {
                    try Task.checkCancellation()
                    let feedPost = getCachedOrCreatePost(from: checkin)
                    feedPosts.append(feedPost)
                }

                try Task.checkCancellation()
                posts = feedPosts

                return true

            } catch is CancellationError {
                return false
            } catch {
                debugPrint("❌ FeedStore: User feed loading failed with error: \(error)")
                self.error = FeedError.networkError(error)
                throw error
            }
        }

        loadingTask = task
        return try await task.value
    }

    /// Clear all cached posts
    public func clearCache() {
        feedPostCache.removeAllObjects()
    }

    /// Delete a check-in from the feed
    /// Authentication via HttpOnly cookie (BFF pattern).
    /// - Parameters:
    ///   - post: The post to delete
    /// - Throws: FeedError if deletion fails
    @MainActor
    public func deleteCheckin(_ post: FeedPost) async throws {
        debugPrint("🗑️ FeedStore: Deleting check-in \(post.id)...")

        do {
            // Delete from backend (cookie authentication)
            try await feedService.deleteCheckin(
                did: post.author.did,
                rkey: post.id
            )

            // Remove from local posts array
            posts.removeAll { $0.id == post.id }

            // Remove from cache
            let cacheKey = NSString(string: post.id)
            feedPostCache.removeObject(forKey: cacheKey)

            debugPrint("✅ FeedStore: Successfully deleted check-in \(post.id)")

        } catch {
            debugPrint("❌ FeedStore: Failed to delete check-in: \(error)")
            throw FeedError.networkError(error)
        }
    }

    // MARK: - Private Methods

    /// Get cached post or create new one from checkin data
    @MainActor
    private func getCachedOrCreatePost(from checkin: AnchorFeedCheckin) -> FeedPost {
        let cacheKey = NSString(string: checkin.id)

        // Check if we have a cached post
        if let cachedWrapper = feedPostCache.object(forKey: cacheKey) {
            return cachedWrapper.post
        }

        // Create new post and cache it
        let newPost = FeedPost(from: checkin)
        feedPostCache.setObject(FeedPostWrapper(newPost), forKey: cacheKey)

        return newPost
    }
}
