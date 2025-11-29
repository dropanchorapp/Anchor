import Foundation

// MARK: - Community Lexicon Type Constants

/// AT Protocol community lexicon type identifiers
///
/// Community lexicons provide standardized schemas for common data types.
/// These constants represent well-known community lexicons that can be used
/// across AT Protocol applications.
///
/// Apps can extend this enum with their own lexicon types:
/// ```swift
/// extension CommunityLexicon {
///     public static let myCustomType = "my.app.custom.type"
/// }
/// ```
public enum CommunityLexicon {
    // MARK: - Location Lexicons

    /// Geographic coordinates: `community.lexicon.location.geo`
    ///
    /// Represents a geographic point with latitude and longitude.
    public static let locationGeo = "community.lexicon.location.geo"

    /// Physical address: `community.lexicon.location.address`
    ///
    /// Structured address data with name, street, locality, region, country, and postal code.
    public static let locationAddress = "community.lexicon.location.address"
}

// MARK: - Bluesky Lexicon Type Constants

/// Bluesky-specific lexicon type identifiers
///
/// These are the official Bluesky app lexicons for social features.
public enum BlueskyLexicon {
    /// Bluesky post record type
    public static let feedPost = "app.bsky.feed.post"

    /// Rich text link facet
    public static let richTextLink = "app.bsky.richtext.facet#link"

    /// Rich text mention facet
    public static let richTextMention = "app.bsky.richtext.facet#mention"

    /// Rich text hashtag facet
    public static let richTextTag = "app.bsky.richtext.facet#tag"
}
