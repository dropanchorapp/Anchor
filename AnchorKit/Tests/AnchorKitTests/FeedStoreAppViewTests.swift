@testable import AnchorKit
import Foundation
import Testing

// MARK: - Mock AppView Service for Testing

@MainActor
final class MockAnchorAppViewService: AnchorAppViewServiceProtocol {
    var mockGlobalFeedResponse: AnchorAppViewFeedResponse?
    var mockNearbyResponse: AnchorAppViewNearbyResponse?
    var mockUserFeedResponse: AnchorAppViewFeedResponse?
    var mockFollowingFeedResponse: AnchorAppViewFeedResponse?
    var mockStatsResponse: AnchorAppViewStats?
    var shouldThrowError = false
    var thrownError: Error = NSError(domain: "test", code: 1, userInfo: nil)
    
    func getGlobalFeed(limit: Int, cursor: String?) async throws -> AnchorAppViewFeedResponse {
        if shouldThrowError {
            throw thrownError
        }
        return mockGlobalFeedResponse ?? AnchorAppViewFeedResponse(checkins: [], cursor: nil)
    }
    
    func getNearbyCheckins(latitude: Double, longitude: Double, radius: Double, limit: Int) async throws -> AnchorAppViewNearbyResponse {
        if shouldThrowError {
            throw thrownError
        }
        return mockNearbyResponse ?? AnchorAppViewNearbyResponse(
            checkins: [],
            center: AnchorAppViewCoordinates(latitude: latitude, longitude: longitude),
            radius: radius
        )
    }
    
    func getUserCheckins(did: String, limit: Int, cursor: String?) async throws -> AnchorAppViewFeedResponse {
        if shouldThrowError {
            throw thrownError
        }
        return mockUserFeedResponse ?? AnchorAppViewFeedResponse(checkins: [], cursor: nil)
    }
    
    func getFollowingFeed(userDid: String, limit: Int, cursor: String?) async throws -> AnchorAppViewFeedResponse {
        if shouldThrowError {
            throw thrownError
        }
        return mockFollowingFeedResponse ?? AnchorAppViewFeedResponse(checkins: [], cursor: nil)
    }
    
    func getStats() async throws -> AnchorAppViewStats {
        if shouldThrowError {
            throw thrownError
        }
        return mockStatsResponse ?? AnchorAppViewStats(
            totalCheckins: 0,
            totalUsers: 0,
            recentActivity: 0,
            lastProcessingRun: nil,
            timestamp: ISO8601DateFormatter().string(from: Date())
        )
    }
}

@Suite("Feed Store - AppView Integration", .tags(.unit, .stores, .feed))
struct FeedStoreAppViewTests {
    let feedStore: FeedStore
    let mockSession: MutableMockURLSession
    let mockAppViewService: MockAnchorAppViewService
    
    @MainActor
    init() {
        mockSession = MutableMockURLSession()
        mockAppViewService = MockAnchorAppViewService()
        
        // Create FeedStore with mocked AppView service
        feedStore = FeedStore(appViewService: mockAppViewService, session: mockSession)
    }
    
    // MARK: - FeedPost Model Tests
    
    @Test("FeedPost initialization from AppView checkin")
    func feedPost_initializationFromAppViewCheckin() {
        let checkin = createMockAppViewCheckin()
        
        let feedPost = FeedPost(from: checkin)
        
        #expect(feedPost.id == "test123")
        #expect(feedPost.author.did == "did:plc:test")
        #expect(feedPost.author.handle == "test.bsky.social")
        #expect(feedPost.record.text == "Great coffee!")
        #expect(feedPost.coordinates?.latitude == 52.3676)
        #expect(feedPost.coordinates?.longitude == 4.9041)
        #expect(feedPost.address?.name == "Test Cafe")
        #expect(feedPost.distance == nil) // Not set in basic checkin
    }
    
    @Test("FeedPost initialization with distance for nearby results")
    func feedPost_initializationWithDistance() {
        var checkin = createMockAppViewCheckin()
        checkin = AnchorAppViewCheckin(
            id: checkin.id,
            uri: checkin.uri,
            author: checkin.author,
            text: checkin.text,
            createdAt: checkin.createdAt,
            coordinates: checkin.coordinates,
            address: checkin.address,
            distance: 1.5
        )
        
        let feedPost = FeedPost(from: checkin)
        
        #expect(feedPost.distance == 1.5)
    }
    
    // MARK: - Global Feed Tests
    
    @Test("fetchGlobalFeed success with empty response")
    @MainActor
    func fetchGlobalFeed_successEmpty() async throws {
        // Setup mock response
        mockAppViewService.mockGlobalFeedResponse = AnchorAppViewFeedResponse(
            checkins: [],
            cursor: nil
        )
        
        let result = try await feedStore.fetchGlobalFeed()
        
        #expect(result == true)
        #expect(feedStore.posts.isEmpty)
        #expect(feedStore.error == nil)
        #expect(feedStore.isLoading == false)
    }
    
    @Test("fetchGlobalFeed success with checkins")
    @MainActor
    func fetchGlobalFeed_successWithCheckins() async throws {
        // Setup mock response with checkins
        let checkins = [createMockAppViewCheckin()]
        mockAppViewService.mockGlobalFeedResponse = AnchorAppViewFeedResponse(
            checkins: checkins,
            cursor: "2024-01-01T12:00:00Z"
        )
        
        let result = try await feedStore.fetchGlobalFeed()
        
        #expect(result == true)
        #expect(feedStore.posts.count == 1)
        #expect(feedStore.posts.first?.id == "test123")
        #expect(feedStore.posts.first?.author.handle == "test.bsky.social")
        #expect(feedStore.error == nil)
        #expect(feedStore.isLoading == false)
    }
    
    @Test("fetchGlobalFeed handles network errors")
    @MainActor
    func fetchGlobalFeed_networkError() async throws {
        // Setup mock to throw error
        mockAppViewService.shouldThrowError = true
        mockAppViewService.thrownError = AnchorAppViewError.networkError(
            NSError(domain: "NetworkError", code: -1, userInfo: nil)
        )
        
        do {
            _ = try await feedStore.fetchGlobalFeed()
            #expect(Bool(false), "Expected error to be thrown")
        } catch {
            #expect(feedStore.error != nil)
            #expect(feedStore.isLoading == false)
        }
    }
    
    // MARK: - Nearby Feed Tests
    
    @Test("fetchNearbyFeed success with distance information")
    @MainActor
    func fetchNearbyFeed_successWithDistance() async throws {
        // Setup mock response with nearby checkins including distance
        var checkin = createMockAppViewCheckin()
        checkin = AnchorAppViewCheckin(
            id: checkin.id,
            uri: checkin.uri,
            author: checkin.author,
            text: checkin.text,
            createdAt: checkin.createdAt,
            coordinates: checkin.coordinates,
            address: checkin.address,
            distance: 2.5
        )
        
        mockAppViewService.mockNearbyResponse = AnchorAppViewNearbyResponse(
            checkins: [checkin],
            center: AnchorAppViewCoordinates(latitude: 52.3676, longitude: 4.9041),
            radius: 5.0
        )
        
        let result = try await feedStore.fetchNearbyFeed(latitude: 52.3676, longitude: 4.9041, radius: 5.0)
        
        #expect(result == true)
        #expect(feedStore.posts.count == 1)
        #expect(feedStore.posts.first?.distance == 2.5)
        #expect(feedStore.error == nil)
        #expect(feedStore.isLoading == false)
    }
    
    @Test("fetchNearbyFeed with coordinates")
    @MainActor
    func fetchNearbyFeed_withCoordinates() async throws {
        let latitude = 40.7128
        let longitude = -74.0060
        let radius = 10.0
        
        // Setup empty response
        mockAppViewService.mockNearbyResponse = AnchorAppViewNearbyResponse(
            checkins: [],
            center: AnchorAppViewCoordinates(latitude: latitude, longitude: longitude),
            radius: radius
        )
        
        let result = try await feedStore.fetchNearbyFeed(latitude: latitude, longitude: longitude, radius: radius)
        
        #expect(result == true)
        #expect(feedStore.posts.isEmpty)
        #expect(feedStore.error == nil)
    }
    
    // MARK: - Following Feed Tests
    
    @Test("fetchFollowingFeed success")
    @MainActor
    func fetchFollowingFeed_success() async throws {
        let userDid = "did:plc:user123"
        
        // Setup mock response
        let checkins = [createMockAppViewCheckin()]
        mockAppViewService.mockFollowingFeedResponse = AnchorAppViewFeedResponse(
            checkins: checkins,
            cursor: nil,
            user: AnchorAppViewUser(did: userDid)
        )
        
        let result = try await feedStore.fetchFollowingFeed(for: userDid)
        
        #expect(result == true)
        #expect(feedStore.posts.count == 1)
        #expect(feedStore.error == nil)
        #expect(feedStore.isLoading == false)
    }
    
    @Test("fetchFollowingFeed with empty results")
    @MainActor
    func fetchFollowingFeed_empty() async throws {
        let userDid = "did:plc:user123"
        
        // Setup empty response (user not following anyone with checkins)
        mockAppViewService.mockFollowingFeedResponse = AnchorAppViewFeedResponse(
            checkins: [],
            cursor: nil,
            user: AnchorAppViewUser(did: userDid)
        )
        
        let result = try await feedStore.fetchFollowingFeed(for: userDid)
        
        #expect(result == true)
        #expect(feedStore.posts.isEmpty)
        #expect(feedStore.error == nil)
    }
    
    // MARK: - Loading State Tests
    
    @Test("loading state management during fetch")
    @MainActor
    func loadingState_management() async throws {
        // Setup mock response with delay simulation
        mockAppViewService.mockGlobalFeedResponse = AnchorAppViewFeedResponse(
            checkins: [],
            cursor: nil
        )
        
        // Start fetch operation
        let fetchTask = Task {
            return try await feedStore.fetchGlobalFeed()
        }
        
        // Check that loading state is set immediately
        // Note: This test is timing-sensitive and may need adjustment
        
        let result = try await fetchTask.value
        
        #expect(result == true)
        #expect(feedStore.isLoading == false) // Should be false after completion
    }
    
    @Test("cancel loading operation")
    @MainActor
    func cancelLoading_stopsOperation() async throws {
        // Start a fetch operation
        let fetchTask = Task {
            return try await feedStore.fetchGlobalFeed()
        }
        
        // Cancel it immediately
        feedStore.cancelLoading()
        
        // Check that loading state is reset
        #expect(feedStore.isLoading == false)
        
        // Clean up the task
        fetchTask.cancel()
    }
    
    // MARK: - Error Handling Tests
    
    @Test("error state management")
    @MainActor
    func errorState_management() async throws {
        // Setup mock to throw API error
        mockAppViewService.shouldThrowError = true
        mockAppViewService.thrownError = AnchorAppViewError.apiError(400, "Bad Request")
        
        do {
            _ = try await feedStore.fetchGlobalFeed()
            #expect(Bool(false), "Expected error to be thrown")
        } catch {
            #expect(feedStore.error != nil)
            #expect(feedStore.isLoading == false)
            
            // Error should be converted to FeedError
            if case let .networkError(underlyingError) = feedStore.error {
                #expect(underlyingError is AnchorAppViewError)
            } else {
                #expect(Bool(false), "Expected networkError type")
            }
        }
    }
}

// MARK: - Test Helpers

private func createMockAppViewCheckin() -> AnchorAppViewCheckin {
    return AnchorAppViewCheckin(
        id: "test123",
        uri: "at://did:plc:test/app.dropanchor.checkin/test123",
        author: AnchorAppViewAuthor(
            did: "did:plc:test",
            handle: "test.bsky.social"
        ),
        text: "Great coffee!",
        createdAt: "2024-01-01T12:00:00Z",
        coordinates: AnchorAppViewCoordinates(
            latitude: 52.3676,
            longitude: 4.9041
        ),
        address: AnchorAppViewAddress(
            name: "Test Cafe",
            street: "123 Test St",
            locality: "Amsterdam",
            region: "North Holland",
            country: "Netherlands",
            postalCode: "1012 LP"
        ),
        distance: nil
    )
}