//
//  AnchorAuthService.swift
//  AnchorKit
//
//  Iron Session-based authentication service for Anchor
//

import Foundation

// MARK: - Auth Service Protocol

/// Service protocol for Iron Session authentication operations
@MainActor
public protocol AnchorAuthServiceProtocol {
    /// Validate current session using Iron Session backend
    func validateSession(_ credentials: AuthCredentials) async throws -> AuthCredentials

    /// Refresh tokens using Iron Session backend
    func refreshTokens(_ credentials: AuthCredentials) async throws -> AuthCredentials

    /// Check if tokens should be refreshed (proactive refresh logic)
    func shouldRefreshTokens(_ credentials: AuthCredentials) -> Bool
}

// MARK: - Anchor Auth Service

/// Iron Session-based authentication service for Anchor
///
/// Simplified service that works with Iron Session backend:
/// - Session validation through sealed session tokens
/// - Automatic token refresh via Iron Session endpoints
/// - No complex OAuth token management (handled by backend)
@Observable
public final class AnchorAuthService: AnchorAuthServiceProtocol {
    // MARK: - Properties

    private let storage: CredentialsStorageProtocol
    private let ironSessionCoordinator: IronSessionMobileOAuthCoordinator

    // MARK: - Initialization

    /// Initialize auth service with Iron Session coordinator
    public init(
        storage: CredentialsStorageProtocol,
        session: URLSessionProtocol = URLSession.shared,
        baseURL: String = "https://dropanchor.app"
    ) {
        self.storage = storage
        self.ironSessionCoordinator = IronSessionMobileOAuthCoordinator(
            credentialsStorage: storage,
            session: session,
            baseURL: baseURL
        )
    }

    /// Convenience initializer for production use
    public convenience init() {
        let storage = KeychainCredentialsStorage()
        self.init(storage: storage)
    }

    // MARK: - Iron Session Methods

    /// Validate current session using Iron Session backend
    public func validateSession(_ credentials: AuthCredentials) async throws -> AuthCredentials {
        // For Iron Session, validation is implicit - if we have a session ID, we're valid
        // The backend validates the sealed session token on each request
        guard credentials.sessionId != nil else {
            throw AnchorAuthError.invalidAuthData
        }
        
        // Return the credentials as-is since validation happens on the backend
        return credentials
    }

    /// Refresh tokens using Iron Session backend
    public func refreshTokens(_ credentials: AuthCredentials) async throws -> AuthCredentials {
        // Use Iron Session coordinator to refresh
        let refreshedCredentials = try await ironSessionCoordinator.refreshIronSession()
        
        // Cast to AuthCredentials
        guard let authCredentials = refreshedCredentials as? AuthCredentials else {
            throw AnchorAuthError.invalidAuthData
        }
        
        return authCredentials
    }

    /// Check if tokens should be refreshed (proactive refresh logic)
    public func shouldRefreshTokens(_ credentials: AuthCredentials) -> Bool {
        // For Iron Session, we rely on server-side expiration
        // Refresh if the session is close to expiring (within 1 hour)
        let oneHourFromNow = Date().addingTimeInterval(60 * 60)
        return credentials.expiresAt < oneHourFromNow
    }
}
