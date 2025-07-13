import Foundation

// MARK: - Feed Models

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
