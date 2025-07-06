import Foundation

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
                    
                    let feedPost = FeedPost(from: checkin)
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
                    
                    let feedPost = FeedPost(from: checkin)
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
                    
                    let feedPost = FeedPost(from: checkin)
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
            displayName: nil, // AppView doesn't provide display names yet
            avatar: nil // AppView doesn't provide avatars yet
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
