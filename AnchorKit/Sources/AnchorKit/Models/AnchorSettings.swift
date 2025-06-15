import Foundation

/// User preferences and configuration for Anchor
public struct AnchorSettings: Codable, Sendable {
    /// Default message to use when checking in (if none provided)
    public let defaultMessage: String

    /// Whether to include emoji in check-in posts
    public let includeEmoji: Bool

    /// Maximum radius (in meters) for nearby place searches
    public let searchRadius: Double

    /// Preferred place categories to prioritize in searches
    public let preferredCategories: [String]
    
    /// Whether to create Bluesky posts when checking in (in addition to AnchorPDS records)
    public let createBlueskyPosts: Bool

    public init(
        defaultMessage: String = "",
        includeEmoji: Bool = true,
        searchRadius: Double = 1000.0, // 1km default
        preferredCategories: [String] = ["climbing", "gym", "cafe"],
        createBlueskyPosts: Bool = true // Default to enabled for backward compatibility
    ) {
        self.defaultMessage = defaultMessage
        self.includeEmoji = includeEmoji
        self.searchRadius = searchRadius
        self.preferredCategories = preferredCategories
        self.createBlueskyPosts = createBlueskyPosts
    }
}

// MARK: - Default Settings
extension AnchorSettings {
    /// Default settings for new users
    public static let `default` = AnchorSettings()
}

// MARK: - UserDefaults Storage
extension AnchorSettings {
    private static let storageKey = "anchor.settings"

    /// Save settings to UserDefaults
    public func save() throws {
        let data = try JSONEncoder().encode(self)
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    /// Load settings from UserDefaults, falling back to defaults
    public static func load() -> AnchorSettings {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let settings = try? JSONDecoder().decode(AnchorSettings.self, from: data) else {
            return .default
        }
        return settings
    }

    /// Get current settings (always returns valid settings)
    public static var current: AnchorSettings {
        load()
    }
}

// MARK: - Settings Management
extension AnchorSettings {
    /// Update the default message
    public func withDefaultMessage(_ message: String) -> AnchorSettings {
        AnchorSettings(
            defaultMessage: message,
            includeEmoji: includeEmoji,
            searchRadius: searchRadius,
            preferredCategories: preferredCategories,
            createBlueskyPosts: createBlueskyPosts
        )
    }

    /// Update emoji preference
    public func withEmojiEnabled(_ enabled: Bool) -> AnchorSettings {
        AnchorSettings(
            defaultMessage: defaultMessage,
            includeEmoji: enabled,
            searchRadius: searchRadius,
            preferredCategories: preferredCategories,
            createBlueskyPosts: createBlueskyPosts
        )
    }

    /// Update search radius
    public func withSearchRadius(_ radius: Double) -> AnchorSettings {
        AnchorSettings(
            defaultMessage: defaultMessage,
            includeEmoji: includeEmoji,
            searchRadius: max(100, min(5000, radius)), // Clamp between 100m and 5km
            preferredCategories: preferredCategories,
            createBlueskyPosts: createBlueskyPosts
        )
    }
    
    /// Update Bluesky posting preference
    public func withBlueskyPostsEnabled(_ enabled: Bool) -> AnchorSettings {
        AnchorSettings(
            defaultMessage: defaultMessage,
            includeEmoji: includeEmoji,
            searchRadius: searchRadius,
            preferredCategories: preferredCategories,
            createBlueskyPosts: enabled
        )
    }
}

// MARK: - Validation
extension AnchorSettings {
    /// Check if settings are valid
    public var isValid: Bool {
        searchRadius > 0 && searchRadius <= 10000 // Max 10km radius
    }
}
