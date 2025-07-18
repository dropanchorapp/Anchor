import Foundation

/// Wrapper class for FeedPost to use with NSCache
private final class FeedPostWrapper {
    let post: FeedPost

    init(_ post: FeedPost) {
        self.post = post
    }
}

/// Observable store for managing check-in feeds from the new Anchor AppView backend
///
/// Manages feed state and coordinates with the Anchor AppView API.
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

    private let appViewService: AnchorAppViewServiceProtocol
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

    public init(appViewService: AnchorAppViewServiceProtocol? = nil, session: URLSessionProtocol = URLSession.shared) {
        self.session = session
        self.appViewService = appViewService ?? AnchorAppViewService(session: session)

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

                // Fetch global feed from AppView (no authentication required)
                print("📡 FeedStore: Fetching global feed from AppView...")
                let feedResponse = try await appViewService.getGlobalFeed(
                    limit: AnchorConfig.shared.maxNearbyPlaces,
                    cursor: nil
                )
                print("📡 FeedStore: Received \(feedResponse.checkins.count) check-ins from AppView")

                // Check for cancellation before processing results
                try Task.checkCancellation()

                // Convert AppView responses to FeedPost format
                var feedPosts: [FeedPost] = []

                for (index, checkin) in feedResponse.checkins.enumerated() {
                    // Check for cancellation during processing
                    try Task.checkCancellation()

                    print("📝 FeedStore: Processing check-in \(index + 1)/\(feedResponse.checkins.count) " +
                          "from \(checkin.author.handle)")

                    let feedPost = getCachedOrCreatePost(from: checkin)
                    feedPosts.append(feedPost)
                    print("✅ FeedStore: Added post for \(checkin.author.handle)")
                }

                // Final cancellation check before updating UI
                try Task.checkCancellation()

                posts = feedPosts
                print("✅ FeedStore: Updated posts array with \(feedPosts.count) items")

                return true

            } catch is CancellationError {
                // Handle cancellation gracefully - don't update error state
                print("⏹️ FeedStore: Feed loading was cancelled")
                return false

            } catch {
                print("❌ FeedStore: Feed loading failed with error: \(error)")
                self.error = FeedError.networkError(error)
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

    /// Fetch following feed from the AppView (requires user DID)
    /// - Parameter userDid: DID of the user to get following feed for
    /// - Returns: Success status
    @MainActor
    public func fetchFollowingFeed(for userDid: String) async throws -> Bool {
        print("🔄 FeedStore: Starting fetchFollowingFeed for \(userDid)...")

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

                // Fetch following feed from AppView
                print("📡 FeedStore: Fetching following feed from AppView...")
                let feedResponse = try await appViewService.getFollowingFeed(
                    userDid: userDid,
                    limit: AnchorConfig.shared.maxNearbyPlaces,
                    cursor: nil
                )
                print("📡 FeedStore: Received \(feedResponse.checkins.count) following check-ins from AppView")

                // Check for cancellation before processing results
                try Task.checkCancellation()

                // Convert AppView responses to FeedPost format
                var feedPosts: [FeedPost] = []

                for (index, checkin) in feedResponse.checkins.enumerated() {
                    // Check for cancellation during processing
                    try Task.checkCancellation()

                    print("📝 FeedStore: Processing following check-in \(index + 1)/\(feedResponse.checkins.count) " +
                          "from \(checkin.author.handle)")

                    let feedPost = getCachedOrCreatePost(from: checkin)
                    feedPosts.append(feedPost)
                    print("✅ FeedStore: Added following post for \(checkin.author.handle)")
                }

                // Final cancellation check before updating UI
                try Task.checkCancellation()

                posts = feedPosts
                print("✅ FeedStore: Updated posts array with \(feedPosts.count) following items")

                return true

            } catch is CancellationError {
                // Handle cancellation gracefully - don't update error state
                print("⏹️ FeedStore: Following feed loading was cancelled")
                return false

            } catch {
                print("❌ FeedStore: Following feed loading failed with error: \(error)")
                self.error = FeedError.networkError(error)
                throw error
            }
        }

        // Store the task for potential cancellation
        loadingTask = task

        // Wait for the task to complete
        let result = try await task.value
        print("🏁 FeedStore: fetchFollowingFeed completed with result: \(result)")
        return result
    }

    /// Fetch nearby check-ins from the AppView
    /// - Parameters:
    ///   - latitude: Latitude coordinate
    ///   - longitude: Longitude coordinate
    ///   - radius: Search radius in kilometers
    /// - Returns: Success status
    @MainActor
    public func fetchNearbyFeed(latitude: Double, longitude: Double, radius: Double = 5.0) async throws -> Bool {
        print("🔄 FeedStore: Starting fetchNearbyFeed for \(latitude), \(longitude) with radius \(radius)km...")

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

                // Fetch nearby feed from AppView
                print("📡 FeedStore: Fetching nearby feed from AppView...")
                let nearbyResponse = try await appViewService.getNearbyCheckins(
                    latitude: latitude,
                    longitude: longitude,
                    radius: radius,
                    limit: AnchorConfig.shared.maxNearbyPlaces
                )
                print("📡 FeedStore: Received \(nearbyResponse.checkins.count) nearby check-ins from AppView")

                // Check for cancellation before processing results
                try Task.checkCancellation()

                // Convert AppView responses to FeedPost format
                var feedPosts: [FeedPost] = []

                for (index, checkin) in nearbyResponse.checkins.enumerated() {
                    // Check for cancellation during processing
                    try Task.checkCancellation()

                    let distanceStr = checkin.distance.map { String(format: "%.1fkm", $0) } ?? "unknown"
                    print("📝 FeedStore: Processing nearby check-in \(index + 1)/\(nearbyResponse.checkins.count) " +
                          "from \(checkin.author.handle) (\(distanceStr))")

                    let feedPost = getCachedOrCreatePost(from: checkin)
                    feedPosts.append(feedPost)
                    print("✅ FeedStore: Added nearby post for \(checkin.author.handle)")
                }

                // Final cancellation check before updating UI
                try Task.checkCancellation()

                posts = feedPosts
                print("✅ FeedStore: Updated posts array with \(feedPosts.count) nearby items")

                return true

            } catch is CancellationError {
                // Handle cancellation gracefully - don't update error state
                print("⏹️ FeedStore: Nearby feed loading was cancelled")
                return false

            } catch {
                print("❌ FeedStore: Nearby feed loading failed with error: \(error)")
                self.error = FeedError.networkError(error)
                throw error
            }
        }

        // Store the task for potential cancellation
        loadingTask = task

        // Wait for the task to complete
        let result = try await task.value
        print("🏁 FeedStore: fetchNearbyFeed completed with result: \(result)")
        return result
    }

    // MARK: - Caching

    /// Get cached post or create new one from checkin data
    @MainActor
    private func getCachedOrCreatePost(from checkin: AnchorAppViewCheckin) -> FeedPost {
        let cacheKey = NSString(string: checkin.id)

        // Check if we have a cached post
        if let cachedWrapper = feedPostCache.object(forKey: cacheKey) {
            print("🔄 FeedStore: Using cached post for \(checkin.id)")
            return cachedWrapper.post
        }

        // Create new post and cache it
        let newPost = FeedPost(from: checkin)
        feedPostCache.setObject(FeedPostWrapper(newPost), forKey: cacheKey)
        print("💾 FeedStore: Cached new post for \(checkin.id)")

        return newPost
    }

}
