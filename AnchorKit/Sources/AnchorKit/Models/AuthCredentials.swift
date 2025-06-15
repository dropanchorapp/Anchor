import Foundation
import SwiftData

/// Protocol for authentication credentials to enable testing
public protocol AuthCredentialsProtocol {
    var handle: String { get }
    var accessToken: String { get }
    var refreshToken: String { get }
    var did: String { get }
    var expiresAt: Date { get }
    var isExpired: Bool { get }
    var isValid: Bool { get }
}

/// Stores Bluesky authentication credentials
@Model
public final class AuthCredentials: AuthCredentialsProtocol {
    /// Bluesky handle (e.g., "user.bsky.social")
    public var handle: String

    /// Access token for AT Protocol
    public var accessToken: String

    /// Refresh token for session renewal
    public var refreshToken: String

    /// DID (Decentralized Identifier) for the user
    public var did: String

    /// Token expiration date
    public var expiresAt: Date

    /// Creation date for record tracking
    public var createdAt: Date

    public init(
        handle: String,
        accessToken: String,
        refreshToken: String,
        did: String,
        expiresAt: Date
    ) {
        self.handle = handle
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.did = did
        self.expiresAt = expiresAt
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
    var isValid: Bool {
        !handle.isEmpty &&
            !accessToken.isEmpty &&
            !did.isEmpty &&
            !isExpired
    }
}
