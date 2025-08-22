//
//  AnchorAuthService.swift
//  AnchorKit
//
//  Created by Tijs Teulings on 13/08/2025.
//

import Foundation

// MARK: - Auth Service Protocol

/// Service protocol for Anchor authentication operations
@MainActor
public protocol AnchorAuthServiceProtocol {
    /// Exchange authorization code with PKCE verification for secure mobile OAuth
    func exchangeAuthorizationCodeWithPKCE(_ code: String, codeVerifier: String) async throws -> AuthCredentialsProtocol

    /// Validate current session and automatically refresh tokens if needed
    func validateSession(_ credentials: AuthCredentials) async throws -> AuthCredentials

    /// Explicitly refresh tokens using refresh token
    func refreshTokens(_ credentials: AuthCredentials) async throws -> AuthCredentials

    /// Check if tokens should be refreshed (proactive refresh logic)
    func shouldRefreshTokens(_ credentials: AuthCredentials) -> Bool
}

// MARK: - Anchor Auth Service

/// Authentication service for Anchor backend OAuth authentication
///
/// Handles OAuth authentication flow completion by:
/// - Converting OAuth tokens to authentication credentials
/// - Storing credentials securely with session ID for backend API access
/// - Session validation and automatic token refresh
/// - Integrating with existing authentication flow
@Observable
public final class AnchorAuthService: AnchorAuthServiceProtocol {
    // MARK: - Properties

    private let storage: CredentialsStorageProtocol
    private let session: URLSessionProtocol
    private let baseURL: URL
    private let tokenExchanger: OAuthTokenExchanger
    private let sessionValidator: SessionValidator
    private let tokenRefresher: TokenRefresher
    private let tokenLifecycleManager: TokenLifecycleManager

    // MARK: - Initialization

    /// Initialize auth service with storage and networking
    public init(
        storage: CredentialsStorageProtocol,
        session: URLSessionProtocol = URLSession.shared,
        baseURL: String = "https://dropanchor.app"
    ) {
        self.storage = storage
        self.session = session
        self.baseURL = URL(string: baseURL)!
        self.tokenExchanger = OAuthTokenExchanger(
            storage: storage,
            session: session,
            baseURL: self.baseURL
        )
        self.sessionValidator = SessionValidator(
            storage: storage,
            session: session,
            baseURL: self.baseURL
        )
        self.tokenRefresher = TokenRefresher(
            storage: storage,
            session: session,
            baseURL: self.baseURL
        )
        self.tokenLifecycleManager = TokenLifecycleManager()
    }

    /// Convenience initializer for production use
    public convenience init() {
        let storage = KeychainCredentialsStorage()
        self.init(storage: storage)
    }

    // MARK: - OAuth Methods

    /// Exchange authorization code with PKCE verification for secure mobile OAuth
    public func exchangeAuthorizationCodeWithPKCE(_ code: String, codeVerifier: String) async throws -> AuthCredentialsProtocol {
        return try await tokenExchanger.exchangeAuthorizationCodeWithPKCE(code, codeVerifier: codeVerifier)
    }

    // MARK: - Session Validation Methods

    /// Validate current session and automatically refresh tokens if needed
    public func validateSession(_ credentials: AuthCredentials) async throws -> AuthCredentials {
        return try await sessionValidator.validateSession(credentials)
    }

    /// Explicitly refresh tokens using refresh token
    public func refreshTokens(_ credentials: AuthCredentials) async throws -> AuthCredentials {
        return try await tokenRefresher.refreshTokens(credentials)
    }

    /// Check if tokens should be refreshed (proactive refresh logic)
    public func shouldRefreshTokens(_ credentials: AuthCredentials) -> Bool {
        return tokenLifecycleManager.shouldRefreshTokens(credentials)
    }

}
