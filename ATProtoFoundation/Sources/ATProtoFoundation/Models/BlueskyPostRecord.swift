import Foundation

/// Represents a Bluesky post record (app.bsky.feed.post) with rich text support
///
/// `BlueskyPostRecord` handles parsing and formatting of Bluesky posts with facets (rich text annotations).
/// Facets enable links, mentions, and hashtags within text content.
///
/// Example usage:
/// ```swift
/// let record = BlueskyPostRecord(
///     text: "Check out @alice.bsky.social's post!",
///     facets: [ATProtoFacet(index: 10...27, feature: .mention("did:plc:alice"))],
///     createdAt: Date()
/// )
/// print(record.formattedText) // Markdown formatted with links
/// ```
public struct BlueskyPostRecord: Sendable, Hashable {
    public let text: String
    public let formattedText: String // Markdown formatted version
    public let facets: [ATProtoFacet]
    public let createdAt: Date
    public let type: String

    public init(
        text: String,
        facets: [ATProtoFacet] = [],
        createdAt: Date = Date(),
        type: String = "app.bsky.feed.post"
    ) {
        self.text = text
        self.facets = facets
        self.createdAt = createdAt
        self.type = type
        formattedText = Self.formatTextWithFacets(text: text, facets: facets)
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
            guard startIndex <= endIndex, endIndex < text.count else { continue }

            // Add text before facet
            if startIndex > currentIndex {
                let beforeStart = text.index(text.startIndex, offsetBy: currentIndex)
                let beforeEnd = text.index(text.startIndex, offsetBy: startIndex)
                result += String(text[beforeStart ..< beforeEnd])
            }

            // Add facet as markdown link - use endIndex + 1 for exclusive upper bound in range
            let facetStart = text.index(text.startIndex, offsetBy: startIndex)
            let facetEnd = text.index(text.startIndex, offsetBy: endIndex + 1)
            let linkText = String(text[facetStart ..< facetEnd])
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
///
/// Facets annotate ranges of text with features like links, mentions, or hashtags.
/// The index uses a closed range representing character positions in the text.
public struct ATProtoFacet: Sendable, Hashable {
    /// Character index range in the text (inclusive on both ends)
    public let index: ClosedRange<Int>

    /// The feature type (link, mention, or hashtag)
    public let feature: ATProtoFeature

    public init(index: ClosedRange<Int>, feature: ATProtoFeature) {
        self.index = index
        self.feature = feature
    }
}

/// Different types of rich text features supported by AT Protocol
///
/// Features describe what a facet represents:
/// - `.link`: A URL hyperlink
/// - `.mention`: A reference to an AT Protocol user (by DID)
/// - `.hashtag`: A hashtag for categorization/search
public enum ATProtoFeature: Sendable, Hashable {
    case link(String)
    case mention(String) // DID
    case hashtag(String)

    /// URL for this feature (for rendering as links)
    public var url: String {
        switch self {
        case let .link(url):
            return url
        case let .mention(did):
            // Convert DID to profile URL
            return "https://bsky.app/profile/\(did)"
        case let .hashtag(tag):
            // Convert hashtag to search URL
            let encodedTag = tag.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) ?? tag
            return "https://bsky.app/search?q=%23\(encodedTag)"
        }
    }
}
