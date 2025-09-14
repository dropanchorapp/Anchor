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
/// Manages feed state and coordinates with the Anchor Feed API.
/// Provides observable feed state for UI binding.
///
/// Responsibilities:
/// - Observable feed state for UI (posts, loading, errors)
/// - Coordinate feed fetching operations
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

    /// Fetch global check-in feed from the AppView
    /// - Returns: Success status
    @MainActor
    public func fetchGlobalFeed() async throws -> Bool {
        debugPrint("🔄 FeedStore: Starting global feed...")

        // Cancel any existing loading task
        loadingTask?.cancel()

        // Create a new task for this operation
        let task = Task<Bool, Error> {
            isLoading = true
            error = nil

            defer {
                isLoading = false
            }

            do {
                try Task.checkCancellation()

                let feedResponse = try await feedService.getGlobalFeed(
                    limit: AnchorConfig.shared.maxNearbyPlaces,
                    cursor: nil
                )

                try Task.checkCancellation()

                // Convert responses to FeedPost format
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
                debugPrint("❌ FeedStore: Global feed loading failed with error: \(error)")
                self.error = FeedError.networkError(error)
                throw error
            }
        }

        loadingTask = task
        return try await task.value
    }

    /// Fetch following feed from the AppView (requires user DID)
    /// - Parameter userDid: DID of the user to get following feed for
    /// - Returns: Success status
    @MainActor
    public func fetchFollowingFeed(for userDid: String) async throws -> Bool {
        debugPrint("🔄 FeedStore: Starting following feed...")

        loadingTask?.cancel()

        let task = Task<Bool, Error> {
            isLoading = true
            error = nil

            defer {
                isLoading = false
            }

            do {
                try Task.checkCancellation()

                let feedResponse = try await feedService.getFollowingFeed(
                    userDid: userDid,
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
                debugPrint("❌ FeedStore: Following feed loading failed with error: \(error)")
                self.error = FeedError.networkError(error)
                throw error
            }
        }

        loadingTask = task
        return try await task.value
    }

    /// Fetch user-specific feed from the AppView
    /// - Parameter userDid: DID of the user to get feed for
    /// - Returns: Success status
    @MainActor
    public func fetchUserFeed(for userDid: String) async throws -> Bool {
        debugPrint("🔄 FeedStore: Starting user feed...")

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

    /// Fetch nearby check-in feed based on location
    /// - Parameters:
    ///   - latitude: Latitude coordinate
    ///   - longitude: Longitude coordinate
    ///   - radiusMeters: Search radius in meters
    /// - Returns: Success status
    @MainActor
    public func fetchNearbyFeed(
        latitude: Double,
        longitude: Double,
        radiusMeters: Double
    ) async throws -> Bool {
        debugPrint("🔄 FeedStore: Starting nearby feed...")

        loadingTask?.cancel()

        let task = Task<Bool, Error> {
            isLoading = true
            error = nil

            defer {
                isLoading = false
            }

            do {
                try Task.checkCancellation()

                let nearbyResponse = try await feedService.getNearbyCheckins(
                    latitude: latitude,
                    longitude: longitude,
                    radius: radiusMeters,
                    limit: AnchorConfig.shared.maxNearbyPlaces
                )

                try Task.checkCancellation()

                var feedPosts: [FeedPost] = []
                for checkin in nearbyResponse.checkins {
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
                debugPrint("❌ FeedStore: Nearby feed loading failed with error: \(error)")
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