import Foundation

/// Protocol for authentication credentials to enable testing
public protocol AuthCredentialsProtocol: Sendable {
    var handle: String { get }
    var accessToken: String { get }
    var refreshToken: String { get }
    var did: String { get }
    var pdsURL: String { get }
    var expiresAt: Date { get }
    var appPassword: String? { get }
    var sessionId: String? { get }
    var isExpired: Bool { get }
    var isValid: Bool { get }
}

/// Stores Bluesky authentication credentials
public struct AuthCredentials: AuthCredentialsProtocol, Sendable, Codable {
    /// Bluesky handle (e.g., "user.bsky.social")
    public var handle: String

    /// Access token for AT Protocol
    public var accessToken: String

    /// Refresh token for session renewal
    public var refreshToken: String

    /// DID (Decentralized Identifier) for the user
    public var did: String

    /// PDS URL where the user is authenticated
    public var pdsURL: String

    /// Token expiration date
    public var expiresAt: Date

    /// App password for automatic re-authentication (stored securely in keychain)
    public var appPassword: String?

    /// Session ID for backend API authentication (from OAuth flow)
    public var sessionId: String?

    /// Creation date for record tracking
    public var createdAt: Date

    public init(
        handle: String,
        accessToken: String,
        refreshToken: String,
        did: String,
        pdsURL: String,
        expiresAt: Date,
        appPassword: String? = nil,
        sessionId: String? = nil
    ) {
        self.handle = handle
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.did = did
        self.pdsURL = pdsURL
        self.expiresAt = expiresAt
        self.appPassword = appPassword
        self.sessionId = sessionId
        createdAt = Date()
    }
}

// MARK: - Validation

public extension AuthCredentials {
    /// Check if the access token is expired or will expire soon
    var isExpired: Bool {
        // Consider expired if less than 5 minutes remaining
        expiresAt.timeIntervalSinceNow < 300
    }

    /// Check if credentials are valid for making API calls
    /// Note: We have refresh tokens, so expired access tokens can be renewed
    var isValid: Bool {
        !handle.isEmpty &&
            !accessToken.isEmpty &&
            !refreshToken.isEmpty &&
            !did.isEmpty &&
            !pdsURL.isEmpty
    }
}
