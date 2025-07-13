import Foundation

/// Wrapper class for BlueskyProfileInfo to use with NSCache
private final class ProfileWrapper {
    let profile: BlueskyProfileInfo

    init(_ profile: BlueskyProfileInfo) {
        self.profile = profile
    }
}

/// Service for resolving user profiles in feed posts
@MainActor
public final class FeedProfileResolver {
    // MARK: - Properties

    private let multiPDSClient: MultiPDSClient
    private var credentials: AuthCredentialsProtocol?

    // Profile cache
    private let profileCache = NSCache<NSString, ProfileWrapper>()

    // MARK: - Initialization

    public init(multiPDSClient: MultiPDSClient) {
        self.multiPDSClient = multiPDSClient

        // Configure cache
        profileCache.countLimit = 500 // Reasonable limit for profiles
    }

    // MARK: - Authentication

    /// Set authentication credentials for profile resolution
    public func setCredentials(_ credentials: AuthCredentialsProtocol?) {
        self.credentials = credentials
    }

    /// Get access token from stored credentials
    private func getAccessToken() -> String? {
        return credentials?.accessToken
    }

    // MARK: - Caching

    /// Get cached profile or return nil if not available
    public func getCachedProfile(for did: String) -> BlueskyProfileInfo? {
        let cacheKey = NSString(string: did)
        return profileCache.object(forKey: cacheKey)?.profile
    }

    /// Cache a resolved profile
    public func cacheProfile(_ profile: BlueskyProfileInfo, for did: String) {
        let cacheKey = NSString(string: did)
        profileCache.setObject(ProfileWrapper(profile), forKey: cacheKey)
        print("💾 FeedProfileResolver: Cached profile for \(did): @\(profile.handle)")
    }

    // MARK: - Profile Resolution

    /// Resolve user profiles for posts that don't have displayName or avatar
    public func resolveProfiles(for posts: [FeedPost]) async -> [FeedPost] {
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

        print("🔄 FeedProfileResolver: Need to resolve \(didsNeedingResolution.count) profiles")

        // First, update posts with any cached profiles we have
        var updatedPosts = updatePostsWithCachedProfiles(posts)

        // Try to get access token from credentials (if available)
        let accessToken = getAccessToken()

        // Only resolve profiles that aren't cached
        guard !didsNeedingResolution.isEmpty else {
            print("✅ FeedProfileResolver: All profiles are cached, no network requests needed")
            return updatedPosts
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
                updatedPosts = updatePostsWithProfile(updatedPosts, profile: profileInfo, for: did)
            }
        }

        return updatedPosts
    }

    // MARK: - Private Helpers

    /// Update posts with cached profiles
    private func updatePostsWithCachedProfiles(_ posts: [FeedPost]) -> [FeedPost] {
        return posts.map { post in
            // Skip if already has complete profile data
            if post.author.displayName != nil && post.author.avatar != nil {
                return post
            }

            // Check for cached profile
            guard let cachedProfile = getCachedProfile(for: post.author.did) else {
                return post
            }

            print("🔄 FeedProfileResolver: Applying cached profile for \(post.author.did): @\(cachedProfile.handle)")

            return createUpdatedPost(post, with: cachedProfile)
        }
    }

    /// Update posts with a specific profile
    private func updatePostsWithProfile(_ posts: [FeedPost], profile: BlueskyProfileInfo, for did: String) -> [FeedPost] {
        return posts.map { post in
            guard post.author.did == did else { return post }
            return createUpdatedPost(post, with: profile)
        }
    }

    /// Helper to create updated post with profile information
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

        return updatedPost
    }
}
