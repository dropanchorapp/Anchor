//
//  AnchorAuthService.swift
//  AnchorKit
//
//  BFF-based authentication service for Anchor
//

import Foundation
import ATProtoFoundation

// MARK: - Auth Service Protocol

/// Service protocol for BFF authentication operations
@MainActor
public protocol AnchorAuthServiceProtocol {
    /// Validate current session using BFF backend
    func validateSession(_ credentials: AuthCredentials) async throws -> AuthCredentials

    /// Refresh tokens using BFF backend
    func refreshTokens(_ credentials: AuthCredentials) async throws -> AuthCredentials

    /// Check if tokens should be refreshed (proactive refresh logic)
    func shouldRefreshTokens(_ credentials: AuthCredentials) -> Bool
}

// MARK: - Anchor Auth Service

/// BFF-based authentication service for Anchor
///
/// Simplified service that works with BFF backend:
/// - Session validation through sealed session tokens
/// - Automatic token refresh via backend endpoints
/// - No complex OAuth token management (handled by backend)
@Observable
public final class AnchorAuthService: AnchorAuthServiceProtocol {
    // MARK: - Properties

    private let storage: CredentialsStorageProtocol
    private let oauthCoordinator: MobileOAuthCoordinator

    // MARK: - Initialization

    /// Initialize auth service with OAuth coordinator
    public init(
        storage: CredentialsStorageProtocol,
        session: URLSessionProtocol = URLSession.shared,
        config: OAuthConfiguration = .anchor
    ) {
        self.storage = storage
        self.oauthCoordinator = MobileOAuthCoordinator(
            credentialsStorage: storage,
            session: session,
            config: config
        )
    }

    /// Convenience initializer for production use
    public convenience init() {
        let storage = KeychainCredentialsStorage()
        self.init(storage: storage)
    }

    // MARK: - BFF Session Methods

    /// Validate current session using BFF backend
    public func validateSession(_ credentials: AuthCredentials) async throws -> AuthCredentials {
        // For BFF, validation is implicit - if we have a session ID, we're valid
        // The backend validates the sealed session token on each request
        guard credentials.sessionId != nil else {
            throw AuthenticationError.invalidCredentials("Invalid authentication data")
        }

        // Return the credentials as-is since validation happens on the backend
        return credentials
    }

    /// Refresh tokens using BFF backend
    public func refreshTokens(_ credentials: AuthCredentials) async throws -> AuthCredentials {
        // Use OAuth coordinator to refresh
        let refreshedCredentials = try await oauthCoordinator.refreshSession()

        // Cast to AuthCredentials
        guard let authCredentials = refreshedCredentials as? AuthCredentials else {
            throw AuthenticationError.invalidCredentials("Invalid authentication data")
        }

        return authCredentials
    }

    /// Check if tokens should be refreshed (proactive refresh logic)
    public func shouldRefreshTokens(_ credentials: AuthCredentials) -> Bool {
        // For BFF, we rely on server-side expiration
        // Refresh if the session is close to expiring (within 1 hour)
        let oneHourFromNow = Date().addingTimeInterval(60 * 60)
        return credentials.expiresAt <= oneHourFromNow
    }
}
