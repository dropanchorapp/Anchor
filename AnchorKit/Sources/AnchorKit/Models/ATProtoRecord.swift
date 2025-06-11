import Foundation

/// Represents an AT Protocol record with rich text support
public struct ATProtoRecord: Sendable {
    public let text: String
    public let formattedText: String // Markdown formatted version
    public let facets: [ATProtoFacet]
    public let createdAt: Date
    public let type: String

    public init(text: String, facets: [ATProtoFacet] = [], createdAt: Date = Date(), type: String = "app.bsky.feed.post") {
        self.text = text
        self.facets = facets
        self.createdAt = createdAt
        self.type = type
        self.formattedText = Self.formatTextWithFacets(text: text, facets: facets)
    }

    /// Convert raw text and facets to markdown
    private static func formatTextWithFacets(text: String, facets: [ATProtoFacet]) -> String {
        guard !facets.isEmpty else { return text }

        var result = ""
        let sortedFacets = facets.sorted { $0.index.lowerBound < $1.index.lowerBound }
        var currentIndex = 0

        for facet in sortedFacets {
            let startIndex = max(currentIndex, facet.index.lowerBound)
            let endIndex = min(facet.index.upperBound, text.count - 1)

            // Skip if facet range is invalid
            guard startIndex <= endIndex && endIndex < text.count else { continue }

            // Add text before facet
            if startIndex > currentIndex {
                let beforeStart = text.index(text.startIndex, offsetBy: currentIndex)
                let beforeEnd = text.index(text.startIndex, offsetBy: startIndex)
                result += String(text[beforeStart..<beforeEnd])
            }

            // Add facet as markdown link - use endIndex + 1 for exclusive upper bound in range
            let facetStart = text.index(text.startIndex, offsetBy: startIndex)
            let facetEnd = text.index(text.startIndex, offsetBy: endIndex + 1)
            let linkText = String(text[facetStart..<facetEnd])
            result += "[\(linkText)](\(facet.feature.url))"
            currentIndex = endIndex + 1
        }

        // Add remaining text after last facet
        if currentIndex < text.count {
            let remainingStart = text.index(text.startIndex, offsetBy: currentIndex)
            result += String(text[remainingStart...])
        }

        return result
    }
}

/// Represents a facet (rich text annotation) in AT Protocol
public struct ATProtoFacet: Sendable {
    public let index: ClosedRange<Int>
    public let feature: ATProtoFeature

    public init(index: ClosedRange<Int>, feature: ATProtoFeature) {
        self.index = index
        self.feature = feature
    }
}

/// Different types of rich text features supported by AT Protocol
public enum ATProtoFeature: Sendable {
    case link(String)
    case mention(String) // DID
    case hashtag(String)

    public var url: String {
        switch self {
        case .link(let url):
            return url
        case .mention(let did):
            // Convert DID to profile URL
            return "https://bsky.app/profile/\(did)"
        case .hashtag(let tag):
            // Convert hashtag to search URL
            let encodedTag = tag.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) ?? tag
            return "https://bsky.app/search?q=%23\(encodedTag)"
        }
    }
}

// MARK: - Creation from Timeline Data

extension ATProtoRecord {
    /// Create from timeline record data
    init(from timelineRecord: TimelineRecord) {
        self.text = timelineRecord.text
        self.type = timelineRecord.type

        // Parse created date
        let formatter = ISO8601DateFormatter()
        self.createdAt = formatter.date(from: timelineRecord.createdAt) ?? Date()

        // Convert timeline facets to AT Proto facets
        self.facets = timelineRecord.facets?.compactMap { ATProtoFacet(from: $0) } ?? []
        self.formattedText = Self.formatTextWithFacets(text: text, facets: facets)
    }
}

extension ATProtoFacet {
    /// Create from timeline facet data
    init?(from timelineFacet: TimelineFacet) {
        let startIndex = timelineFacet.index.byteStart
        let endIndex = timelineFacet.index.byteEnd
        guard startIndex < endIndex else { return nil }

        // Convert from AT Protocol's exclusive end index to Swift's inclusive ClosedRange
        self.index = startIndex...(endIndex - 1)

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
    init?(from featureData: FacetFeature) {
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

// MARK: - Updated Timeline Models

internal struct TimelineRecord: Codable {
    let text: String
    let createdAt: String
    let type: String
    let facets: [TimelineFacet]?

    private enum CodingKeys: String, CodingKey {
        case text, createdAt, facets
        case type = "$type"
    }
}

internal struct TimelineFacet: Codable {
    let index: FacetIndex
    let features: [FacetFeature]
}

internal struct FacetIndex: Codable {
    let byteStart: Int
    let byteEnd: Int
}

internal struct FacetFeature: Codable {
    let type: String
    let uri: String?
    let did: String?
    let tag: String?

    private enum CodingKeys: String, CodingKey {
        case uri, did, tag
        case type = "$type"
    }
}
