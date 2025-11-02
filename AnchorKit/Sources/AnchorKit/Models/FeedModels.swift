import Foundation

// MARK: - Feed Models

public struct FeedPost: Identifiable, Sendable, Hashable {
    public let id: String
    public let author: FeedAuthor
    public let record: ATProtoRecord
    public let coordinates: FeedCoordinates?
    public let address: FeedAddress?
    public let distance: Double? // Only present in nearby feeds
    public let image: FeedImage? // Optional image attachment
    public let likesCount: Int? // Optional likes count

    // Public initializer for testing and previews
    public init(
        id: String,
        author: FeedAuthor,
        record: ATProtoRecord,
        coordinates: FeedCoordinates? = nil,
        address: FeedAddress? = nil,
        distance: Double? = nil,
        image: FeedImage? = nil,
        likesCount: Int? = nil
    ) {
        self.id = id
        self.author = author
        self.record = record
        self.coordinates = coordinates
        self.address = address
        self.distance = distance
        self.image = image
        self.likesCount = likesCount
    }

    // New initializer for Feed Service API responses
    init(from checkin: AnchorFeedCheckin) {
        id = checkin.id
        author = FeedAuthor(
            did: checkin.author.did,
            handle: checkin.author.handle,
            displayName: checkin.author.displayName,
            avatar: checkin.author.avatar
        )

        // Parse the createdAt string to Date
        let createdAt = ISO8601DateFormatter.flexibleDate(from: checkin.createdAt) ?? Date()

        record = ATProtoRecord(
            text: checkin.text,
            createdAt: createdAt
        )

        coordinates = checkin.coordinates.map {
            FeedCoordinates(latitude: $0.latitude, longitude: $0.longitude)
        }
        address = checkin.address.map {
            FeedAddress(
                name: $0.name,
                streetAddress: $0.streetAddress,
                locality: $0.locality,
                region: $0.region,
                country: $0.country
            )
        }
        distance = checkin.distance
        image = checkin.image.map {
            FeedImage(
                thumbUrl: $0.thumbUrl,
                fullsizeUrl: $0.fullsizeUrl,
                alt: $0.alt
            )
        }
        likesCount = checkin.likesCount
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

/// Geographic coordinates for feeds
public struct FeedCoordinates: Sendable, Hashable, Codable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// Address information for feeds
public struct FeedAddress: Sendable, Hashable, Codable {
    public let name: String?
    public let streetAddress: String?
    public let locality: String?
    public let region: String?
    public let country: String?

    public init(
        name: String? = nil,
        streetAddress: String? = nil,
        locality: String? = nil,
        region: String? = nil,
        country: String? = nil
    ) {
        self.name = name
        self.streetAddress = streetAddress
        self.locality = locality
        self.region = region
        self.country = country
    }
}

/// Image attachment for feeds
public struct FeedImage: Sendable, Hashable, Codable {
    public let thumbUrl: String
    public let fullsizeUrl: String
    public let alt: String?

    public init(
        thumbUrl: String,
        fullsizeUrl: String,
        alt: String? = nil
    ) {
        self.thumbUrl = thumbUrl
        self.fullsizeUrl = fullsizeUrl
        self.alt = alt
    }
}

// MARK: - LocationRepresentable Conformance

extension FeedAddress: LocationRepresentable {
    public var displayName: String? { name }
    public var street: String? { streetAddress }
    public var postalCode: String? { nil }
    public var coordinate: (Double, Double)? { nil }
}

// MARK: - Date Grouping

public struct FeedSection: Identifiable {
    public let id = UUID()
    public let date: Date
    public let posts: [FeedPost]

    public init(date: Date, posts: [FeedPost]) {
        self.date = date
        self.posts = posts
    }
}

extension Array where Element == FeedPost {
    /// Groups posts by date (day) in descending order (newest first)
    public func groupedByDate() -> [FeedSection] {
        let calendar = Calendar.current

        // Group posts by day
        let grouped = Dictionary(grouping: self) { post in
            calendar.startOfDay(for: post.record.createdAt)
        }

        // Sort by date descending (newest first) and create sections
        return grouped
            .sorted { $0.key > $1.key }
            .map { date, posts in
                let sortedPosts = posts.sorted { $0.record.createdAt > $1.record.createdAt }
                return FeedSection(date: date, posts: sortedPosts)
            }
    }
}

// MARK: - Date Parsing Utilities

extension ISO8601DateFormatter {
    /// Parse ISO8601 date string, trying with fractional seconds first, then without
    static func flexibleDate(from string: String) -> Date? {
        // Try with fractional seconds first (for real API data like "2025-08-11T18:34:55.966Z")
        let formatterWithFractional = ISO8601DateFormatter()
        formatterWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatterWithFractional.date(from: string) {
            return date
        }

        // Fallback to format without fractional seconds (for test data like "2024-01-01T12:00:00Z")
        let formatterBasic = ISO8601DateFormatter()
        return formatterBasic.date(from: string)
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
