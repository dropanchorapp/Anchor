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

/// Stores Bluesky authentication credentials using SwiftData
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
        self.createdAt = Date()
    }
}

// MARK: - Validation
extension AuthCredentials {
    /// Check if the access token is expired or will expire soon
    public var isExpired: Bool {
        // Consider expired if less than 5 minutes remaining
        expiresAt.timeIntervalSinceNow < 300
    }

    /// Check if credentials are valid for making API calls
    public var isValid: Bool {
        !handle.isEmpty &&
            !accessToken.isEmpty &&
            !did.isEmpty &&
            !isExpired
    }
}

// MARK: - SwiftData Storage
extension AuthCredentials {
    /// Save credentials to SwiftData
    public static func save(
        _ credentials: AuthCredentials,
        to context: ModelContext
    ) throws {
        // Clear any existing credentials first
        try clearAll(from: context)

        // Insert the new credentials
        context.insert(credentials)
        try context.save()
    }

    /// Load current valid credentials from SwiftData
    public static func current(from context: ModelContext) -> AuthCredentials? {
        let descriptor = FetchDescriptor<AuthCredentials>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            let allCredentials = try context.fetch(descriptor)
            print("🔍 Found \(allCredentials.count) stored credentials")

            guard let credentials = allCredentials.first else {
                print("🔍 No credentials found in database")
                return nil
            }

            print("🔍 Checking credentials for @\(credentials.handle), expires: \(credentials.expiresAt), valid: \(credentials.isValid)")

            // Check if credentials are still valid
            if credentials.isValid {
                return credentials
            } else {
                print("🔍 Credentials expired, cleaning up")
                // Clean up invalid credentials
                try? clearAll(from: context)
                return nil
            }
        } catch {
            print("🔍 Error fetching credentials: \(error)")
            return nil
        }
    }

    /// Remove all credentials from SwiftData
    public static func clearAll(from context: ModelContext) throws {
        let descriptor = FetchDescriptor<AuthCredentials>()
        let credentials = try context.fetch(descriptor)

        for credential in credentials {
            context.delete(credential)
        }

        try context.save()
    }
}
