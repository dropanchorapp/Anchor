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
        defaultMessage: String = AnchorConfig.shared.defaultCheckInMessage,
        includeEmoji: Bool = true,
        searchRadius: Double = Double(AnchorConfig.shared.locationSearchRadius), // From config
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

public extension AnchorSettings {
    /// Default settings for new users
    static let `default` = AnchorSettings()
}

// MARK: - UserDefaults Storage

public extension AnchorSettings {
    private static let storageKey = "anchor.settings"

    /// Save settings to UserDefaults
    func save() throws {
        let data = try JSONEncoder().encode(self)
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    /// Load settings from UserDefaults, falling back to defaults
    static func load() -> AnchorSettings {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let settings = try? JSONDecoder().decode(AnchorSettings.self, from: data)
        else {
            return .default
        }
        return settings
    }

    /// Get current settings (always returns valid settings)
    static var current: AnchorSettings {
        load()
    }
}

// MARK: - Settings Management

public extension AnchorSettings {
    /// Update the default message
    func withDefaultMessage(_ message: String) -> AnchorSettings {
        AnchorSettings(
            defaultMessage: message,
            includeEmoji: includeEmoji,
            searchRadius: searchRadius,
            preferredCategories: preferredCategories,
            createBlueskyPosts: createBlueskyPosts
        )
    }

    /// Update emoji preference
    func withEmojiEnabled(_ enabled: Bool) -> AnchorSettings {
        AnchorSettings(
            defaultMessage: defaultMessage,
            includeEmoji: enabled,
            searchRadius: searchRadius,
            preferredCategories: preferredCategories,
            createBlueskyPosts: createBlueskyPosts
        )
    }

    /// Update search radius
    func withSearchRadius(_ radius: Double) -> AnchorSettings {
        AnchorSettings(
            defaultMessage: defaultMessage,
            includeEmoji: includeEmoji,
            searchRadius: max(100, min(5000, radius)), // Clamp between 100m and 5km
            preferredCategories: preferredCategories,
            createBlueskyPosts: createBlueskyPosts
        )
    }

    /// Update Bluesky posting preference
    func withBlueskyPostsEnabled(_ enabled: Bool) -> AnchorSettings {
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

public extension AnchorSettings {
    /// Check if settings are valid
    var isValid: Bool {
        searchRadius > 0 && searchRadius <= 10000 // Max 10km radius
    }
}
