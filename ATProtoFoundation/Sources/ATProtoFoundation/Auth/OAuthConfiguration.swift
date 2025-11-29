import Foundation

/// Configuration for OAuth authentication and session management
///
/// Centralizes all OAuth-related constants and time intervals that were previously
/// hardcoded throughout the codebase. Enables environment-specific configuration
/// and makes values explicit and testable.
public struct OAuthConfiguration: Sendable {
    /// Base URL for the OAuth backend (BFF pattern)
    public let baseURL: URL

    /// User-Agent header value for API requests
    public let userAgent: String

    /// Cookie name for session ID
    public let sessionCookieName: String

    /// Domain for session cookies
    public let cookieDomain: String

    /// URL scheme for OAuth callback (e.g., "anchor-app")
    public let callbackURLScheme: String

    /// Duration before session expires (7 days)
    public let sessionDuration: TimeInterval

    /// Time before expiration to trigger proactive token refresh (1 hour)
    public let refreshThreshold: TimeInterval

    /// Maximum number of retry attempts for failed requests
    public let maxRetryAttempts: Int

    /// Maximum delay between retries (8 seconds)
    public let maxRetryDelay: TimeInterval

    /// Default production configuration for Anchor app
    public static let `default` = OAuthConfiguration(
        baseURL: URL(string: "https://dropanchor.app")!,
        userAgent: "AnchorApp/1.0 (iOS)",
        sessionCookieName: "sid",
        cookieDomain: "dropanchor.app",
        callbackURLScheme: "anchor-app",
        sessionDuration: 60 * 60 * 24 * 7, // 7 days
        refreshThreshold: 60 * 60, // 1 hour
        maxRetryAttempts: 3,
        maxRetryDelay: 8.0
    )

    /// Initialize with custom configuration
    public init(
        baseURL: URL,
        userAgent: String,
        sessionCookieName: String,
        cookieDomain: String,
        callbackURLScheme: String,
        sessionDuration: TimeInterval,
        refreshThreshold: TimeInterval,
        maxRetryAttempts: Int,
        maxRetryDelay: TimeInterval
    ) {
        self.baseURL = baseURL
        self.userAgent = userAgent
        self.sessionCookieName = sessionCookieName
        self.cookieDomain = cookieDomain
        self.callbackURLScheme = callbackURLScheme
        self.sessionDuration = sessionDuration
        self.refreshThreshold = refreshThreshold
        self.maxRetryAttempts = maxRetryAttempts
        self.maxRetryDelay = maxRetryDelay
    }
}
