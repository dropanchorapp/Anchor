//
//  AnchorAuthService.swift
//  AnchorKit
//
//  Created by Claude Code on 13/08/2025.
//

import Foundation


/// Token exchange response from backend (OAuth 2.1 compliant)
public struct TokenExchangeResponse: Codable {
    public let access_token: String
    public let refresh_token: String
    public let expires_in: Int  // OAuth 2.1 standard: lifetime in seconds
    public let token_type: String
    public let scope: String
    public let did: String
    public let handle: String
    public let pds_url: String
    public let session_id: String
    public let display_name: String?
    public let avatar: String?
}

// MARK: - Auth Service Protocol

/// Service protocol for Anchor authentication operations
@MainActor
public protocol AnchorAuthServiceProtocol {
    /// Exchange authorization code for tokens (standard OAuth flow)
    func exchangeAuthorizationCode(_ code: String) async throws -> AuthCredentialsProtocol

    /// Exchange authorization code with state for tokens (for OAuth callback handling)
    func exchangeAuthorizationCodeWithState(_ code: String, state: String) async throws -> AuthCredentialsProtocol

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
    }

    /// Convenience initializer for production use
    public convenience init() {
        let storage = KeychainCredentialsStorage()
        self.init(storage: storage)
    }

    // MARK: - OAuth Methods


    /// Exchange authorization code for tokens (standard OAuth 2.1 flow)
    public func exchangeAuthorizationCode(_ code: String) async throws -> AuthCredentialsProtocol {
        return try await performTokenExchange(requestBody: ["code": code])
    }

    /// Exchange authorization code with state for tokens (for OAuth callback handling)
    public func exchangeAuthorizationCodeWithState(_ code: String, state: String) async throws -> AuthCredentialsProtocol {
        return try await performTokenExchange(requestBody: ["code": code, "state": state])
    }

    // MARK: - Private Methods

    /// Shared OAuth 2.1 compliant token exchange implementation
    private func performTokenExchange(requestBody: [String: String]) async throws -> AuthCredentialsProtocol {
        print("🔐 AnchorAuthService: Performing OAuth 2.1 token exchange")

        let url = baseURL.appendingPathComponent("/api/auth/exchange")

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("AnchorApp", forHTTPHeaderField: "User-Agent")

        // Create request body
        let jsonData = try JSONEncoder().encode(requestBody)
        request.httpBody = jsonData

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AnchorAuthError.networkError(NSError(domain: "InvalidResponse", code: 0))
            }

            print("🔐 AnchorAuthService: Token exchange HTTP Status: \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 200 else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ AnchorAuthService: Token exchange failed: \(errorMessage)")
                throw AnchorAuthError.networkError(NSError(domain: "HTTPError", code: httpResponse.statusCode))
            }

            // Parse the OAuth 2.1 compliant token response
            let tokenResponse = try JSONDecoder().decode(TokenExchangeResponse.self, from: data)

            print("🔐 AnchorAuthService: Token exchange successful for handle: \(tokenResponse.handle)")
            print("🔐 AnchorAuthService: Token expires in: \(tokenResponse.expires_in) seconds (OAuth 2.1 standard)")
            print("🔐 AnchorAuthService: PDS URL from backend: '\(tokenResponse.pds_url)'")
            print("🔐 AnchorAuthService: DID: \(tokenResponse.did)")
            print("🔐 AnchorAuthService: Session ID: \(tokenResponse.session_id)")

            // Calculate expiration time from expires_in following OAuth 2.1 spec
            let expiresAt = Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in))
            print("🔐 AnchorAuthService: Calculated expiration date: \(expiresAt)")

            // Validate PDS URL
            guard !tokenResponse.pds_url.isEmpty, URL(string: tokenResponse.pds_url) != nil else {
                print("❌ AnchorAuthService: Invalid PDS URL: '\(tokenResponse.pds_url)'")
                throw AnchorAuthError.invalidPDSURL(tokenResponse.pds_url)
            }

            // Create credentials from OAuth 2.1 compliant response
            let credentials = AuthCredentials(
                handle: tokenResponse.handle,
                accessToken: tokenResponse.access_token,
                refreshToken: tokenResponse.refresh_token,
                did: tokenResponse.did,
                pdsURL: tokenResponse.pds_url,
                expiresAt: expiresAt,
                appPassword: nil, // OAuth doesn't use app passwords
                sessionId: tokenResponse.session_id
            )

            print("🔐 AnchorAuthService: Created OAuth 2.1 compliant credentials with session ID: \(credentials.sessionId ?? "nil")")

            // Store credentials securely
            do {
                try await storage.save(credentials)
                print("✅ AnchorAuthService: Credentials stored successfully")
            } catch {
                print("❌ AnchorAuthService: Failed to store credentials: \(error)")
                throw AnchorAuthError.storageError(error)
            }

            print("✅ AnchorAuthService: OAuth 2.1 authentication process completed for handle: \(credentials.handle)")
            return credentials

        } catch {
            if error is AnchorAuthError {
                throw error
            } else {
                print("❌ AnchorAuthService: Token exchange network error: \(error)")
                throw AnchorAuthError.networkError(error)
            }
        }
    }

    // MARK: - Session Validation Methods

    /// Validate current session and automatically refresh tokens if needed
    public func validateSession(_ credentials: AuthCredentials) async throws -> AuthCredentials {
        print("🔄 AnchorAuthService: Validating session for @\(credentials.handle)")

        let url = baseURL.appendingPathComponent("/api/auth/validate-mobile-session")

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("AnchorApp", forHTTPHeaderField: "User-Agent")

        // Create request body with current credentials
        let requestBody = [
            "access_token": credentials.accessToken,
            "refresh_token": credentials.refreshToken,
            "did": credentials.did,
            "handle": credentials.handle,
            "session_id": credentials.sessionId ?? ""
        ]

        let jsonData = try JSONEncoder().encode(requestBody)
        request.httpBody = jsonData

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AnchorAuthError.networkError(NSError(domain: "InvalidResponse", code: 0))
            }

            print("🔄 AnchorAuthService: Validation HTTP Status: \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 401 {
                    throw AnchorAuthError.invalidAuthData
                }
                throw AnchorAuthError.networkError(NSError(domain: "HTTPError", code: httpResponse.statusCode))
            }

            // Parse the validation response
            let validationResponse = try parseValidationResponse(from: data)

            guard validationResponse.valid else {
                print("❌ AnchorAuthService: Session invalid")
                throw AnchorAuthError.invalidAuthData
            }

            // Check if tokens were refreshed by the backend
            if validationResponse.refreshed == true, let newTokens = validationResponse.newTokens {
                print("🔄 AnchorAuthService: Tokens were refreshed by backend")

                // Update credentials with new tokens (use same expiration pattern as initial tokens)
                let updatedCredentials = AuthCredentials(
                    handle: credentials.handle,
                    accessToken: newTokens.accessToken,
                    refreshToken: newTokens.refreshToken,
                    did: credentials.did,
                    pdsURL: credentials.pdsURL,
                    expiresAt: Date().addingTimeInterval(4 * 60 * 60), // 4 hours, consistent with backend
                    appPassword: credentials.appPassword,
                    sessionId: credentials.sessionId
                )

                // Store updated credentials
                try await storage.save(updatedCredentials)
                print("✅ AnchorAuthService: Updated credentials saved with new tokens")

                return updatedCredentials
            }

            print("✅ AnchorAuthService: Session valid, no token refresh needed")
            return credentials

        } catch {
            if error is AnchorAuthError {
                throw error
            } else {
                print("❌ AnchorAuthService: Session validation network error: \(error)")
                throw AnchorAuthError.networkError(error)
            }
        }
    }

    /// Explicitly refresh tokens using refresh token
    public func refreshTokens(_ credentials: AuthCredentials) async throws -> AuthCredentials {
        print("🔄 AnchorAuthService: Explicitly refreshing tokens for @\(credentials.handle)")

        let url = baseURL.appendingPathComponent("/api/auth/refresh-mobile-token")

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("AnchorApp", forHTTPHeaderField: "User-Agent")

        // Create request body
        let requestBody = [
            "refresh_token": credentials.refreshToken,
            "did": credentials.did,
            "handle": credentials.handle
        ]

        let jsonData = try JSONEncoder().encode(requestBody)
        request.httpBody = jsonData

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AnchorAuthError.networkError(NSError(domain: "InvalidResponse", code: 0))
            }

            print("🔄 AnchorAuthService: Refresh HTTP Status: \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 404 {
                    throw AnchorAuthError.invalidAuthData
                }
                throw AnchorAuthError.networkError(NSError(domain: "HTTPError", code: httpResponse.statusCode))
            }

            // Parse the refresh response
            let refreshResponse = try parseRefreshResponse(from: data)

            guard refreshResponse.success, let newTokens = refreshResponse.newTokens else {
                print("❌ AnchorAuthService: Token refresh failed")
                throw AnchorAuthError.invalidAuthData
            }

            // Update credentials with new tokens (use same expiration pattern as initial tokens)
            let updatedCredentials = AuthCredentials(
                handle: credentials.handle,
                accessToken: newTokens.accessToken,
                refreshToken: newTokens.refreshToken,
                did: credentials.did,
                pdsURL: credentials.pdsURL,
                expiresAt: Date().addingTimeInterval(4 * 60 * 60), // 4 hours, consistent with backend
                appPassword: credentials.appPassword,
                sessionId: credentials.sessionId
            )

            // Store updated credentials
            try await storage.save(updatedCredentials)
            print("✅ AnchorAuthService: Token refresh successful, new credentials saved")

            return updatedCredentials

        } catch {
            if error is AnchorAuthError {
                throw error
            } else {
                print("❌ AnchorAuthService: Token refresh network error: \(error)")
                throw AnchorAuthError.networkError(error)
            }
        }
    }

    /// Check if tokens should be refreshed (proactive refresh logic)
    public func shouldRefreshTokens(_ credentials: AuthCredentials) -> Bool {
        // Refresh if tokens are expired or will expire within 10 minutes
        let tenMinutesFromNow = Date().addingTimeInterval(600)
        let shouldRefresh = credentials.expiresAt < tenMinutesFromNow

        if shouldRefresh {
            print("🔄 AnchorAuthService: Tokens should be refreshed (expire at \(credentials.expiresAt))")
        }

        return shouldRefresh
    }

    // MARK: - Private Methods


    /// Parse session validation response from backend
    private func parseValidationResponse(from data: Data) throws -> (valid: Bool, refreshed: Bool?, newTokens: (accessToken: String, refreshToken: String)?) {
        struct ValidationResponse: Codable {
            let valid: Bool
            let refreshed: Bool?
            let tokens: Tokens?
            let error: String?

            struct Tokens: Codable {
                let access_token: String
                let refresh_token: String
            }
        }

        let response = try JSONDecoder().decode(ValidationResponse.self, from: data)

        let newTokens: (accessToken: String, refreshToken: String)?
        if let tokens = response.tokens {
            newTokens = (accessToken: tokens.access_token, refreshToken: tokens.refresh_token)
        } else {
            newTokens = nil
        }

        return (valid: response.valid, refreshed: response.refreshed, newTokens: newTokens)
    }

    /// Parse token refresh response from backend
    private func parseRefreshResponse(from data: Data) throws -> (success: Bool, newTokens: (accessToken: String, refreshToken: String)?) {
        struct RefreshResponse: Codable {
            let success: Bool
            let tokens: Tokens?
            let error: String?

            struct Tokens: Codable {
                let access_token: String
                let refresh_token: String
            }
        }

        let response = try JSONDecoder().decode(RefreshResponse.self, from: data)

        let newTokens: (accessToken: String, refreshToken: String)?
        if let tokens = response.tokens {
            newTokens = (accessToken: tokens.access_token, refreshToken: tokens.refresh_token)
        } else {
            newTokens = nil
        }

        return (success: response.success, newTokens: newTokens)
    }
}

// MARK: - Auth Error Types

public enum AnchorAuthError: LocalizedError {
    case invalidAuthData
    case invalidPDSURL(String)
    case storageError(Error)
    case networkError(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidAuthData:
            return "Invalid OAuth authentication data"
        case .invalidPDSURL(let url):
            return "Invalid PDS URL: \(url). This indicates an issue with OAuth flow."
        case .storageError(let error):
            return "Failed to store credentials: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
