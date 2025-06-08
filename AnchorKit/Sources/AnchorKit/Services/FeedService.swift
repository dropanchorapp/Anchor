import Foundation

/// Protocol for URLSession to enable dependency injection for testing
public protocol URLSessionProtocol: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

/// Service for fetching and filtering Bluesky feeds for dropanchor posts
@Observable
public final class FeedService: Sendable {
    
    // MARK: - Properties
    
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
    }
    
    // MARK: - Feed Fetching
    
    /// Fetch following timeline filtered for dropanchor posts
    /// - Parameter credentials: Authentication credentials
    /// - Returns: Success status
    @MainActor
    public func fetchFollowingFeed(credentials: AuthCredentials) async throws -> Bool {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        // Fetch timeline using AT Protocol
        let request = try buildAuthenticatedRequest(
            endpoint: "/xrpc/app.bsky.feed.getTimeline",
            method: "GET",
            accessToken: credentials.accessToken
        )
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FeedError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw FeedError.httpError(httpResponse.statusCode)
        }
        
        let timelineResponse = try JSONDecoder().decode(TimelineResponse.self, from: data)
        
        // Filter for posts with dropanchor embeds
        let filteredPosts = timelineResponse.feed.compactMap { feedItem -> FeedPost? in
            guard hasDropanchorEmbed(feedItem.post) else { return nil }
            return FeedPost(from: feedItem)
        }
        
        posts = filteredPosts
        return true
    }
    
    /// Fetch global dropanchor feed (requires custom feed generator)
    /// - Parameter credentials: Authentication credentials  
    /// - Returns: Success status
    @MainActor
    public func fetchGlobalFeed(credentials: AuthCredentials) async throws -> Bool {
        // This would use a custom feed generator in the future
        // For now, return empty array
        posts = []
        return true
    }
    
    // MARK: - Private Methods
    
    /// Check if a post has a dropanchor embed
    /// - Parameter post: The post to check
    /// - Returns: True if post contains dropanchor embed
    private func hasDropanchorEmbed(_ post: TimelinePost) -> Bool {
        guard let embed = post.embed else { return false }
        
        // Check if it's a record embed
        guard embed.type == "app.bsky.embed.record#view" else { return false }
        
        // Check if the embedded record is a dropanchor checkin
        guard let record = embed.record,
              let uri = record.uri else { return false }
        
        // Check if the record collection is app.dropanchor.checkin
        return uri.contains("/app.dropanchor.checkin/")
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
    public let checkinRecord: CheckinEmbedRecord?
    
    internal init(from feedItem: TimelineFeedItem) {
        self.id = feedItem.post.uri
        self.author = FeedAuthor(from: feedItem.post.author)
        self.record = ATProtoRecord(from: feedItem.post.record)
        
        // Extract checkin record if available
        if let embed = feedItem.post.embed,
           let record = embed.record {
            self.checkinRecord = CheckinEmbedRecord(from: record)
        } else {
            self.checkinRecord = nil
        }
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

