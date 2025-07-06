import Foundation

/// Wrapper class for FeedPost to use with NSCache
private final class FeedPostWrapper {
    let post: FeedPost
    
    init(_ post: FeedPost) {
        self.post = post
    }
}

/// Wrapper class for BlueskyProfileInfo to use with NSCache
private final class ProfileWrapper {
    let profile: BlueskyProfileInfo
    
    init(_ profile: BlueskyProfileInfo) {
        self.profile = profile
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
    private let multiPDSClient: MultiPDSClient
    private var credentials: AuthCredentialsProtocol?
    
    // Caches
    private let profileCache = NSCache<NSString, ProfileWrapper>()
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
        self.multiPDSClient = MultiPDSClient(session: session)
        
        // Configure caches
        profileCache.countLimit = 500 // Reasonable limit for profiles
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
                
                // Resolve user profiles asynchronously
                Task {
                    await resolveProfiles()
                    print("✅ FeedStore: Resolved profiles for posts")
                }
                
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
                
                // Resolve user profiles asynchronously
                Task {
                    await resolveProfiles()
                    print("✅ FeedStore: Resolved profiles for posts")
                }
                
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
                
                // Resolve user profiles asynchronously
                Task {
                    await resolveProfiles()
                    print("✅ FeedStore: Resolved profiles for posts")
                }
                
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

    // MARK: - Authentication

    /// Set authentication credentials for profile resolution
    @MainActor
    public func setCredentials(_ credentials: AuthCredentialsProtocol?) {
        self.credentials = credentials
    }

    /// Get access token from stored credentials
    @MainActor
    private func getAccessToken() -> String? {
        return credentials?.accessToken
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

    /// Get cached profile or return nil if not available
    @MainActor
    private func getCachedProfile(for did: String) -> BlueskyProfileInfo? {
        let cacheKey = NSString(string: did)
        return profileCache.object(forKey: cacheKey)?.profile
    }

    /// Cache a resolved profile
    @MainActor
    private func cacheProfile(_ profile: BlueskyProfileInfo, for did: String) {
        let cacheKey = NSString(string: did)
        profileCache.setObject(ProfileWrapper(profile), forKey: cacheKey)
        print("💾 FeedStore: Cached profile for \(did): @\(profile.handle)")
    }

    // MARK: - Profile Resolution

    /// Resolve user profiles for posts that don't have displayName or avatar
    @MainActor
    private func resolveProfiles() async {
        // Get DIDs that need profile resolution (excluding those with cached profiles)
        let didsNeedingResolution = Set(posts.compactMap { post -> String? in
            // Skip if already has complete profile data
            if post.author.displayName != nil && post.author.avatar != nil {
                return nil
            }
            
            // Skip if we have a cached profile
            if getCachedProfile(for: post.author.did) != nil {
                return nil
            }
            
            return post.author.did
        })
        
        print("🔄 FeedStore: Need to resolve \(didsNeedingResolution.count) profiles")

        // First, update posts with any cached profiles we have
        updatePostsWithCachedProfiles()

        // Try to get access token from credentials (if available)
        let accessToken = getAccessToken()

        // Only resolve profiles that aren't cached
        guard !didsNeedingResolution.isEmpty else {
            print("✅ FeedStore: All profiles are cached, no network requests needed")
            return
        }

        // Resolve profiles in parallel
        await withTaskGroup(of: (String, BlueskyProfileInfo?).self) { group in
            for did in didsNeedingResolution {
                group.addTask {
                    let profile = await self.multiPDSClient.getProfileInfo(for: did, accessToken: accessToken)
                    return (did, profile)
                }
            }

            // Collect results and update posts
            for await (did, profileInfo) in group {
                guard let profileInfo = profileInfo else { continue }

                // Cache the resolved profile
                cacheProfile(profileInfo, for: did)

                // Update posts with resolved profile information
                updatePostsWithProfile(profileInfo, for: did)
            }
        }
    }

    /// Update posts with cached profiles
    @MainActor
    private func updatePostsWithCachedProfiles() {
        posts = posts.map { post in
            // Skip if already has complete profile data
            if post.author.displayName != nil && post.author.avatar != nil {
                return post
            }
            
            // Check for cached profile
            guard let cachedProfile = getCachedProfile(for: post.author.did) else {
                return post
            }
            
            print("🔄 FeedStore: Applying cached profile for \(post.author.did): @\(cachedProfile.handle)")
            
            return createUpdatedPost(post, with: cachedProfile)
        }
    }

    /// Update posts with a specific profile
    @MainActor
    private func updatePostsWithProfile(_ profile: BlueskyProfileInfo, for did: String) {
        posts = posts.map { post in
            guard post.author.did == did else { return post }
            return createUpdatedPost(post, with: profile)
        }
    }

    /// Helper to create updated post with profile information
    @MainActor
    private func createUpdatedPost(_ post: FeedPost, with profile: BlueskyProfileInfo) -> FeedPost {
        let updatedAuthor = FeedAuthor(
            did: post.author.did,
            handle: profile.handle,
            displayName: profile.displayName,
            avatar: profile.avatar
        )

        let updatedPost = FeedPost(
            id: post.id,
            author: updatedAuthor,
            record: post.record,
            coordinates: post.coordinates,
            address: post.address,
            distance: post.distance
        )
        
        // Update the cache with the enhanced post
        let cacheKey = NSString(string: post.id)
        feedPostCache.setObject(FeedPostWrapper(updatedPost), forKey: cacheKey)
        
        return updatedPost
    }

}

// MARK: - Models

public struct FeedPost: Identifiable, Sendable, Hashable {
    public let id: String
    public let author: FeedAuthor
    public let record: ATProtoRecord
    public let coordinates: AnchorAppViewCoordinates?
    public let address: AnchorAppViewAddress?
    public let distance: Double? // Only present in nearby feeds

    // Public initializer for testing and previews
    public init(id: String, author: FeedAuthor, record: ATProtoRecord, coordinates: AnchorAppViewCoordinates? = nil, address: AnchorAppViewAddress? = nil, distance: Double? = nil) {
        self.id = id
        self.author = author
        self.record = record
        self.coordinates = coordinates
        self.address = address
        self.distance = distance
    }

    // New initializer for AppView API responses
    init(from checkin: AnchorAppViewCheckin) {
        id = checkin.id
        author = FeedAuthor(
            did: checkin.author.did,
            handle: checkin.author.handle,
            displayName: nil, // Will be resolved asynchronously
            avatar: nil // Will be resolved asynchronously
        )

        // Parse the createdAt string to Date
        let dateFormatter = ISO8601DateFormatter()
        let createdAt = dateFormatter.date(from: checkin.createdAt) ?? Date()

        record = ATProtoRecord(
            text: checkin.text,
            createdAt: createdAt
        )

        coordinates = checkin.coordinates
        address = checkin.address
        distance = checkin.distance
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

}

// MARK: - Error Types

public enum FeedError: LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case networkError(Error)
    case decodingError(Error)
    case apiError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid AppView API URL"
        case .invalidResponse:
            "Invalid response from AppView API"
        case let .httpError(code):
            "HTTP error \(code) from AppView API"
        case let .networkError(error):
            "Network error: \(error.localizedDescription)"
        case let .decodingError(error):
            "Failed to decode AppView response: \(error.localizedDescription)"
        case let .apiError(message):
            "AppView API error: \(message)"
        }
    }
}
