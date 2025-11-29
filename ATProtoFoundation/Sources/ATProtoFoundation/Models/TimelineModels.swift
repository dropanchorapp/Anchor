import Foundation

// MARK: - Timeline API Response Models

/// Represents a record from an AT Protocol timeline API response
///
/// Used to parse raw API responses before converting to `ATProtoRecord`.
public struct TimelineRecord: Codable, Sendable {
    public let text: String
    public let createdAt: String
    public let type: String
    public let facets: [TimelineFacet]?

    private enum CodingKeys: String, CodingKey {
        case text, createdAt, facets
        case type = "$type"
    }

    public init(text: String, createdAt: String, type: String, facets: [TimelineFacet]? = nil) {
        self.text = text
        self.createdAt = createdAt
        self.type = type
        self.facets = facets
    }
}

/// Facet data from timeline API response
public struct TimelineFacet: Codable, Sendable {
    public let index: FacetIndex
    public let features: [FacetFeature]

    public init(index: FacetIndex, features: [FacetFeature]) {
        self.index = index
        self.features = features
    }
}

/// Byte range index for facets in API responses
///
/// AT Protocol uses byte ranges, not character ranges, for facet positions.
public struct FacetIndex: Codable, Sendable {
    public let byteStart: Int
    public let byteEnd: Int

    public init(byteStart: Int, byteEnd: Int) {
        self.byteStart = byteStart
        self.byteEnd = byteEnd
    }
}

/// Feature data from timeline API response
public struct FacetFeature: Codable, Sendable {
    public let type: String
    public let uri: String?
    public let did: String?
    public let tag: String?

    private enum CodingKeys: String, CodingKey {
        case uri, did, tag
        case type = "$type"
    }

    public init(type: String, uri: String? = nil, did: String? = nil, tag: String? = nil) {
        self.type = type
        self.uri = uri
        self.did = did
        self.tag = tag
    }
}

// MARK: - Conversion Extensions

extension ATProtoRecord {
    /// Create from timeline record data
    ///
    /// Converts raw API response data into a properly formatted `ATProtoRecord`.
    ///
    /// - Parameter timelineRecord: Raw timeline record from API
    public init(from timelineRecord: TimelineRecord) {
        text = timelineRecord.text
        type = timelineRecord.type

        // Parse created date using flexible parsing
        createdAt = ISO8601DateFormatter.flexibleDate(from: timelineRecord.createdAt) ?? Date()

        // Convert timeline facets to AT Proto facets
        facets = timelineRecord.facets?.compactMap { ATProtoFacet(from: $0) } ?? []
        formattedText = Self.formatTextWithFacets(text: text, facets: facets)
    }

    /// Internal helper to format text with facets (used by both initializers)
    private static func formatTextWithFacets(text: String, facets: [ATProtoFacet]) -> String {
        guard !facets.isEmpty else { return text }

        var result = ""
        let sortedFacets = facets.sorted { $0.index.lowerBound < $1.index.lowerBound }
        var currentIndex = 0

        for facet in sortedFacets {
            let startIndex = max(currentIndex, facet.index.lowerBound)
            let endIndex = min(facet.index.upperBound, text.count - 1)

            guard startIndex <= endIndex, endIndex < text.count else { continue }

            if startIndex > currentIndex {
                let beforeStart = text.index(text.startIndex, offsetBy: currentIndex)
                let beforeEnd = text.index(text.startIndex, offsetBy: startIndex)
                result += String(text[beforeStart ..< beforeEnd])
            }

            let facetStart = text.index(text.startIndex, offsetBy: startIndex)
            let facetEnd = text.index(text.startIndex, offsetBy: endIndex + 1)
            let linkText = String(text[facetStart ..< facetEnd])
            result += "[\(linkText)](\(facet.feature.url))"
            currentIndex = endIndex + 1
        }

        if currentIndex < text.count {
            let remainingStart = text.index(text.startIndex, offsetBy: currentIndex)
            result += String(text[remainingStart...])
        }

        return result
    }
}

extension ATProtoFacet {
    /// Create from timeline facet data
    ///
    /// Converts byte ranges to character ranges and extracts the first supported feature.
    ///
    /// - Parameter timelineFacet: Raw facet from API response
    /// - Returns: Converted facet, or nil if no supported features found
    public init?(from timelineFacet: TimelineFacet) {
        let startIndex = timelineFacet.index.byteStart
        let endIndex = timelineFacet.index.byteEnd
        guard startIndex < endIndex else { return nil }

        // Convert from AT Protocol's exclusive end index to Swift's inclusive ClosedRange
        index = startIndex ... (endIndex - 1)

        // Find the first supported feature
        for featureData in timelineFacet.features {
            if let feature = ATProtoFeature(from: featureData) {
                self.feature = feature
                return
            }
        }

        return nil
    }
}

extension ATProtoFeature {
    /// Create from timeline feature data
    ///
    /// - Parameter featureData: Raw feature from API response
    /// - Returns: Converted feature, or nil if type not supported
    public init?(from featureData: FacetFeature) {
        switch featureData.type {
        case "app.bsky.richtext.facet#link":
            guard let uri = featureData.uri else { return nil }
            self = .link(uri)
        case "app.bsky.richtext.facet#mention":
            guard let did = featureData.did else { return nil }
            self = .mention(did)
        case "app.bsky.richtext.facet#tag":
            guard let tag = featureData.tag else { return nil }
            self = .hashtag(tag)
        default:
            return nil
        }
    }
}
