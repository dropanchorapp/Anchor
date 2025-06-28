@testable import AnchorKit
import Foundation
import Testing

// MARK: - Mock Credentials

/// Mock implementation of AuthCredentialsProtocol to avoid SwiftData ModelContainer issues in CI
private struct MockAuthCredentials: AuthCredentialsProtocol {
    let handle: String
    let accessToken: String
    let refreshToken: String
    let did: String
    let pdsURL: String
    let expiresAt: Date

    var isExpired: Bool {
        expiresAt.timeIntervalSinceNow < 300 // 5 minutes buffer
    }

    var isValid: Bool {
        !handle.isEmpty && !accessToken.isEmpty && !did.isEmpty && !pdsURL.isEmpty && !isExpired
    }
}

// Note: Mock utilities moved to TestUtilities.swift

// MARK: - Test Models

// Mirror of the internal BlueskyProfileResponse for testing
struct BlueskyProfileResponse: Codable {
    let did: String
    let handle: String
    let displayName: String?
    let avatar: String?
    let description: String?
    let followersCount: Int?
    let followsCount: Int?
    let postsCount: Int?
}

// MARK: - Mock Services for Testing

@MainActor
final class MockAnchorPDSService {
    var mockGlobalFeedResponse: AnchorPDSFeedResponse?
    var shouldThrowError = false
    var thrownError: Error = NSError(domain: "test", code: 1, userInfo: nil)

    func getGlobalFeed() async throws -> AnchorPDSFeedResponse {
        if shouldThrowError {
            throw thrownError
        }
        return mockGlobalFeedResponse ?? AnchorPDSFeedResponse(checkins: [], cursor: nil)
    }
}

@MainActor
final class MockCheckInStore {
    var mockProfileInfo: [String: BlueskyProfileInfo] = [:]
    var shouldThrowError = false

    func getProfile(for did: String) async throws -> BlueskyProfileInfo? {
        if shouldThrowError {
            throw NSError(domain: "test", code: 1, userInfo: nil)
        }
        return mockProfileInfo[did]
    }
}

@Suite("Feed Store", .tags(.unit, .stores, .feed))
struct FeedStoreTests {
    let feedStore: FeedStore
    let mockSession: MutableMockURLSession
    let mockAnchorPDSService: MockAnchorPDSService
    let mockCheckInStore: MockCheckInStore

    @MainActor
    init() {
        mockSession = MutableMockURLSession()
        mockAnchorPDSService = MockAnchorPDSService()
        mockCheckInStore = MockCheckInStore()

        // Create FeedStore with mocked dependencies
        feedStore = FeedStore(session: mockSession)

        // Note: In a real implementation, we'd need dependency injection
        // For now, we'll test the public interface and mock the network responses
    }

    // MARK: - FeedPost Model Tests

    @Test("FeedPost initialization from timeline item")
    func feedPost_initialization() {
        let timelineFeedItem = createMockTimelineFeedItem()

        let feedPost = FeedPost(from: timelineFeedItem)

        #expect(feedPost.id == "at://did:plc:test/app.bsky.feed.post/123")
        #expect(feedPost.author.handle == "test.bsky.social")
        #expect(feedPost.author.displayName == "Test User")
        #expect(feedPost.author.did == "did:plc:test")
        #expect(feedPost.author.avatar == "https://example.com/avatar.jpg")

        // Verify record contains formatted text
        #expect(feedPost.record.text == "Check out https://example.com for more info!")
        #expect(feedPost.record.formattedText == "Check out [https://example.com](https://example.com) for more info!")
        #expect(feedPost.record.facets.count == 1)

        // Verify date parsing (date exists)
        #expect(feedPost.record.createdAt.timeIntervalSince1970 > 0)

        // Verify no checkin record in this example
        #expect(feedPost.checkinRecord == nil)
    }

    @Test("FeedPost initialization from AnchorPDS response")
    func feedPost_initializationFromAnchorPDS() {
        let checkinResponse = createMockAnchorPDSCheckinResponse()
        let profileInfo = BlueskyProfileInfo(
            did: "did:plc:test123",
            handle: "climber.bsky.social",
            displayName: "Test Climber",
            avatar: "https://example.com/avatar.jpg"
        )

        let feedPost = FeedPost(from: checkinResponse, profileInfo: profileInfo)

        #expect(feedPost.id == "at://did:plc:test123/app.dropanchor.checkin/abc123")
        #expect(feedPost.author.handle == "climber.bsky.social")
        #expect(feedPost.author.displayName == "Test Climber")
        #expect(feedPost.author.did == "did:plc:test123")
        #expect(feedPost.author.avatar == "https://example.com/avatar.jpg")
        #expect(feedPost.record.text == "Dropped anchor at Test Climbing Gym!")
        #expect(feedPost.checkinRecord != nil)
        #expect(feedPost.checkinRecord?.text == "Dropped anchor at Test Climbing Gym!")
        #expect(feedPost.checkinRecord?.locations?.count == 1)
    }

    @Test("FeedPost initialization from AnchorPDS response without profile info")
    func feedPost_initializationFromAnchorPDS_noProfile() {
        let checkinResponse = createMockAnchorPDSCheckinResponse()

        let feedPost = FeedPost(from: checkinResponse, profileInfo: nil)

        #expect(feedPost.id == "at://did:plc:test123/app.dropanchor.checkin/abc123")
        #expect(feedPost.author.handle == "did:plc:test123") // Falls back to DID
        #expect(feedPost.author.displayName == nil)
        #expect(feedPost.author.did == "did:plc:test123")
        #expect(feedPost.author.avatar == nil)
    }

    @Test("FeedPost with checkin record embedded")
    func feedPost_withCheckinRecord() {
        let timelineFeedItem = createMockTimelineFeedItemWithCheckin()

        let feedPost = FeedPost(from: timelineFeedItem)

        // Note: The current implementation doesn't extract checkin records from embeds
        // This is legacy support that returns nil
        #expect(feedPost.checkinRecord == nil)
    }

    // MARK: - Feed Fetching Tests

    @Test("Fetch following feed succeeds with valid response")
    func fetchFollowingFeed_success() async throws {
        // Note: Following feed now also uses AnchorPDS, so we use the same mock structure
        let mockResponse = createMockAnchorPDSFeedResponse()
        let mockData = try JSONEncoder().encode(mockResponse)

        await MainActor.run {
            mockSession.data = mockData
            mockSession.response = HTTPURLResponse(
                url: URL(string: "http://localhost:3000/xrpc/app.dropanchor.feed.getGlobal")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
        }

        let credentials = createMockCredentials()

        let result = try await feedStore.fetchFollowingFeed(credentials: credentials)

        #expect(result == true)
        await #expect(feedStore.posts.count == 2) // Mock response has 2 check-ins
        await #expect(feedStore.isLoading == false)
        await #expect(feedStore.error == nil)
    }

    @Test("Fetch global feed succeeds with AnchorPDS response and profile enrichment")
    func fetchGlobalFeed_success() async throws {
        // Mock AnchorPDS response
        let mockAnchorPDSResponse = createMockAnchorPDSFeedResponse()
        let mockAnchorPDSData = try JSONEncoder().encode(mockAnchorPDSResponse)

        // Mock Bluesky profile responses for both users
        let mockProfile1 = BlueskyProfileResponse(
            did: "did:plc:test123",
            handle: "climber1.bsky.social",
            displayName: "Test Climber 1",
            avatar: "https://example.com/avatar1.jpg",
            description: "Rock climbing enthusiast",
            followersCount: 100,
            followsCount: 50,
            postsCount: 25
        )
        let mockProfile1Data = try JSONEncoder().encode(mockProfile1)

        let mockProfile2 = BlueskyProfileResponse(
            did: "did:plc:test456",
            handle: "climber2.bsky.social",
            displayName: "Test Climber 2",
            avatar: "https://example.com/avatar2.jpg",
            description: "Another climber",
            followersCount: 75,
            followsCount: 30,
            postsCount: 15
        )
        let mockProfile2Data = try JSONEncoder().encode(mockProfile2)

        await MainActor.run {
            // Set up mock responses - first call to AnchorPDS, then profile calls
            mockSession.responses = [
                (mockAnchorPDSData, HTTPURLResponse(
                    url: URL(string: "http://localhost:3000/xrpc/app.dropanchor.feed.getGlobal")!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!),
                (mockProfile1Data, HTTPURLResponse(
                    url: URL(string: "https://public.api.bsky.app/xrpc/app.bsky.actor.getProfile")!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!),
                (mockProfile2Data, HTTPURLResponse(
                    url: URL(string: "https://public.api.bsky.app/xrpc/app.bsky.actor.getProfile")!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!)
            ]
        }

        let credentials = createMockCredentials()

        let result = try await feedStore.fetchGlobalFeed(credentials: credentials)

        #expect(result == true)
        await #expect(feedStore.posts.count == 2) // Mock response has 2 check-ins
        await #expect(feedStore.isLoading == false)
        await #expect(feedStore.error == nil)

        // Verify the posts have the expected structure with profile enrichment
        let posts = await feedStore.posts
        let firstPost = posts.first!
        #expect(firstPost.checkinRecord != nil)
        #expect(firstPost.author.did == "did:plc:test123")
        #expect(firstPost.author.handle == "climber1.bsky.social")
        #expect(firstPost.author.displayName == "Test Climber 1")
        #expect(firstPost.author.avatar == "https://example.com/avatar1.jpg")

        let secondPost = posts[1]
        #expect(secondPost.author.did == "did:plc:test456")
        #expect(secondPost.author.handle == "climber2.bsky.social")
        #expect(secondPost.author.displayName == "Test Climber 2")
        #expect(secondPost.author.avatar == "https://example.com/avatar2.jpg")
    }

    @Test("Fetch global feed handles AnchorPDS errors")
    func fetchGlobalFeed_anchorPDSError() async throws {
        await MainActor.run {
            mockSession.response = HTTPURLResponse(
                url: URL(string: "http://localhost:3000/xrpc/app.dropanchor.feed.getGlobal")!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
        }

        let credentials = createMockCredentials()

        do {
            _ = try await feedStore.fetchGlobalFeed(credentials: credentials)
            Issue.record("Expected error to be thrown")
        } catch {
            // Expected to throw an error (could be FeedError, URLError, or AnchorPDSError)
            #expect(error is FeedError || error is URLError || error is AnchorPDSError)
        }
    }

    @Test("Fetch following feed handles HTTP errors")
    func fetchFollowingFeed_httpError() async throws {
        await MainActor.run {
            mockSession.response = HTTPURLResponse(
                url: URL(string: "http://localhost:3000/xrpc/app.dropanchor.feed.getGlobal")!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
        }

        let credentials = createMockCredentials()

        // The method should complete successfully but set an error
        let result = try await feedStore.fetchFollowingFeed(credentials: credentials)

        // Should return false indicating failure
        #expect(result == false)

        // Should have an error set
        await #expect(feedStore.error != nil)

        // Should be an authentication error
        if let error = await feedStore.error {
            #expect(error is FeedError)
            if case .authenticationError = error {
                // This is the expected error type
            } else {
                Issue.record("Expected authenticationError but got \(error)")
            }
        }
    }

    @Test("Fetch following feed handles invalid JSON")
    func fetchFollowingFeed_invalidJSON() async throws {
        await MainActor.run {
            mockSession.data = "invalid json".data(using: .utf8)!
            mockSession.response = HTTPURLResponse(
                url: URL(string: "http://localhost:3000/xrpc/app.dropanchor.feed.getGlobal")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
        }

        let credentials = createMockCredentials()

        do {
            _ = try await feedStore.fetchFollowingFeed(credentials: credentials)
            Issue.record("Expected error to be thrown")
        } catch {
            // Expected to throw an error (could be DecodingError wrapped in AnchorPDSError)
            #expect(error is DecodingError || error is AnchorPDSError)
        }
    }

    @Test("Fetch following feed filters out non-dropanchor posts")
    func fetchFollowingFeed_filteredResults() async throws {
        // Create an empty AnchorPDS response (no check-ins)
        let mockResponse = AnchorPDSFeedResponse(checkins: [], cursor: nil)
        let mockData = try JSONEncoder().encode(mockResponse)

        await MainActor.run {
            mockSession.data = mockData
            mockSession.response = HTTPURLResponse(
                url: URL(string: "http://localhost:3000/xrpc/app.dropanchor.feed.getGlobal")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
        }

        let credentials = createMockCredentials()

        let result = try await feedStore.fetchFollowingFeed(credentials: credentials)

        #expect(result == true)
        await #expect(feedStore.posts.count == 0) // No check-ins in response
    }

    // MARK: - Helper Methods

    // Mock credentials using protocol to avoid SwiftData ModelContainer issues in CI
    private func createMockCredentials() -> AuthCredentialsProtocol {
        MockAuthCredentials(
            handle: "test.bsky.social",
            accessToken: "test-access-token",
            refreshToken: "test-refresh-token",
            did: "did:plc:test123",
            pdsURL: "https://bsky.social",
            expiresAt: Date().addingTimeInterval(3600) // 1 hour from now
        )
    }

    private func createMockTimelineFeedItem() -> TimelineFeedItem {
        TimelineFeedItem(
            post: TimelinePost(
                uri: "at://did:plc:test/app.bsky.feed.post/123",
                cid: "bafyreicid123",
                author: TimelineAuthor(
                    did: "did:plc:test",
                    handle: "test.bsky.social",
                    displayName: "Test User",
                    avatar: "https://example.com/avatar.jpg"
                ),
                record: TimelineRecord(
                    text: "Check out https://example.com for more info!",
                    createdAt: "2024-01-15T12:00:00Z",
                    type: "app.bsky.feed.post",
                    facets: [
                        TimelineFacet(
                            index: FacetIndex(byteStart: 10, byteEnd: 29),
                            features: [
                                FacetFeature(type: "app.bsky.richtext.facet#link", uri: "https://example.com", did: nil, tag: nil)
                            ]
                        )
                    ]
                ),
                embed: nil,
                replyCount: 0,
                repostCount: 0,
                likeCount: 5,
                indexedAt: "2024-01-15T12:01:00Z"
            ),
            reason: nil
        )
    }

    private func createMockTimelineFeedItemWithCheckin() -> TimelineFeedItem {
        let embedRecord = EmbedRecordView(
            uri: "at://did:plc:test/app.dropanchor.checkin/456",
            cid: "bafyreicid123",
            value: nil
        )

        let embed = PostEmbedView(
            type: "app.bsky.embed.record#view",
            record: embedRecord
        )

        return TimelineFeedItem(
            post: TimelinePost(
                uri: "at://did:plc:test/app.bsky.feed.post/123",
                cid: "bafyreicid123",
                author: TimelineAuthor(
                    did: "did:plc:test",
                    handle: "test.bsky.social",
                    displayName: "Test User",
                    avatar: "https://example.com/avatar.jpg"
                ),
                record: TimelineRecord(
                    text: "Dropped anchor at Test Location!",
                    createdAt: "2024-01-15T12:00:00Z",
                    type: "app.bsky.feed.post",
                    facets: nil
                ),
                embed: embed,
                replyCount: 0,
                repostCount: 0,
                likeCount: 3,
                indexedAt: "2024-01-15T12:01:00Z"
            ),
            reason: nil
        )
    }

    private func createMockTimelineFeedItemWithMultipleFacets() -> TimelineFeedItem {
        TimelineFeedItem(
            post: TimelinePost(
                uri: "at://did:plc:test/app.bsky.feed.post/123",
                cid: "bafyreicid123",
                author: TimelineAuthor(
                    did: "did:plc:test",
                    handle: "test.bsky.social",
                    displayName: "Test User",
                    avatar: nil
                ),
                record: TimelineRecord(
                    text: "Hey @alice.bsky.social check https://example.com #awesome",
                    createdAt: "2024-01-15T12:00:00Z",
                    type: "app.bsky.feed.post",
                    facets: [
                        TimelineFacet(
                            index: FacetIndex(byteStart: 4, byteEnd: 20),
                            features: [
                                FacetFeature(type: "app.bsky.richtext.facet#mention", uri: nil, did: "did:plc:alice", tag: nil)
                            ]
                        ),
                        TimelineFacet(
                            index: FacetIndex(byteStart: 27, byteEnd: 46),
                            features: [
                                FacetFeature(type: "app.bsky.richtext.facet#link", uri: "https://example.com", did: nil, tag: nil)
                            ]
                        ),
                        TimelineFacet(
                            index: FacetIndex(byteStart: 47, byteEnd: 55),
                            features: [
                                FacetFeature(type: "app.bsky.richtext.facet#tag", uri: nil, did: nil, tag: "awesome")
                            ]
                        )
                    ]
                ),
                embed: nil,
                replyCount: 0,
                repostCount: 0,
                likeCount: 1,
                indexedAt: "2024-01-15T12:01:00Z"
            ),
            reason: nil
        )
    }

    private func createMockTimelineFeedItemWithUnicode() -> TimelineFeedItem {
        TimelineFeedItem(
            post: TimelinePost(
                uri: "at://did:plc:test/app.bsky.feed.post/123",
                cid: "bafyreicid123",
                author: TimelineAuthor(
                    did: "did:plc:test",
                    handle: "test.bsky.social",
                    displayName: "Test User",
                    avatar: nil
                ),
                record: TimelineRecord(
                    text: "🧗‍♂️ Great climb at https://café.example.com 🎉",
                    createdAt: "2024-01-15T12:00:00Z",
                    type: "app.bsky.feed.post",
                    facets: [
                        TimelineFacet(
                            index: FacetIndex(byteStart: 19, byteEnd: 41),
                            features: [
                                FacetFeature(type: "app.bsky.richtext.facet#link", uri: "https://café.example.com", did: nil, tag: nil)
                            ]
                        )
                    ]
                ),
                embed: nil,
                replyCount: 0,
                repostCount: 0,
                likeCount: 2,
                indexedAt: "2024-01-15T12:01:00Z"
            ),
            reason: nil
        )
    }

    private func createMockTimelineResponse() -> TimelineResponse {
        TimelineResponse(
            feed: [
                createMockTimelineFeedItemWithCheckin(),
                createMockTimelineFeedItemWithCheckin()
            ],
            cursor: "next-page-cursor"
        )
    }

    private func createMockTimelineResponseWithoutDropanchor() -> TimelineResponse {
        // Create a post without dropanchor embed
        let regularPost = TimelineFeedItem(
            post: TimelinePost(
                uri: "at://did:plc:test/app.bsky.feed.post/789",
                cid: "bafyreicid456",
                author: TimelineAuthor(
                    did: "did:plc:test",
                    handle: "test.bsky.social",
                    displayName: "Test User",
                    avatar: nil
                ),
                record: TimelineRecord(
                    text: "Just a regular post",
                    createdAt: "2024-01-15T12:00:00Z",
                    type: "app.bsky.feed.post",
                    facets: nil
                ),
                embed: nil,
                replyCount: 0,
                repostCount: 0,
                likeCount: 1,
                indexedAt: "2024-01-15T12:01:00Z"
            ),
            reason: nil
        )

        return TimelineResponse(
            feed: [regularPost],
            cursor: "next-page-cursor"
        )
    }

    private func createMockAnchorPDSCheckinResponse() -> AnchorPDSCheckinResponse {
        let geoLocation = CommunityGeoLocation(latitude: 52.0808732, longitude: 4.3629474)
        let checkinRecord = AnchorPDSCheckinRecord(
            text: "Dropped anchor at Test Climbing Gym!",
            createdAt: "2024-01-15T12:00:00Z",
            locations: [.geo(geoLocation)],
            category: "climbing",
            categoryGroup: "Sports & Fitness",
            categoryIcon: "🧗‍♂️"
        )

        return AnchorPDSCheckinResponse(
            uri: "at://did:plc:test123/app.dropanchor.checkin/abc123",
            cid: "bafyreicid123",
            value: checkinRecord,
            author: AnchorPDSAuthor(did: "did:plc:test123")
        )
    }

    private func createMockAnchorPDSFeedResponse() -> AnchorPDSFeedResponse {
        let checkin1 = createMockAnchorPDSCheckinResponse()

        let geoLocation2 = CommunityGeoLocation(latitude: 40.7128, longitude: -74.0060)
        let checkinRecord2 = AnchorPDSCheckinRecord(
            text: "Another check-in!",
            createdAt: "2024-01-15T13:00:00Z",
            locations: [.geo(geoLocation2)],
            category: "restaurant",
            categoryGroup: "Food & Drink",
            categoryIcon: "🍽️"
        )
        let checkin2 = AnchorPDSCheckinResponse(
            uri: "at://did:plc:test456/app.dropanchor.checkin/def456",
            cid: "bafyreicid456",
            value: checkinRecord2,
            author: AnchorPDSAuthor(did: "did:plc:test456")
        )

        return AnchorPDSFeedResponse(checkins: [checkin1, checkin2], cursor: nil)
    }
}
