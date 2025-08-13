//
//  AnchorAuthService.swift
//  AnchorKit
//
//  Created by Claude Code on 13/08/2025.
//

import Foundation

// MARK: - OAuth Authentication Data

/// OAuth authentication data received from the authentication flow
public struct OAuthAuthenticationData {
    public let accessToken: String
    public let refreshToken: String
    public let did: String
    public let handle: String
    public let sessionId: String
    public let pdsURL: String
    public let avatar: String?
    public let displayName: String?
    
    public init(
        accessToken: String,
        refreshToken: String,
        did: String,
        handle: String,
        sessionId: String,
        pdsURL: String,
        avatar: String? = nil,
        displayName: String? = nil
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.did = did
        self.handle = handle
        self.sessionId = sessionId
        self.pdsURL = pdsURL
        self.avatar = avatar
        self.displayName = displayName
    }
}

// MARK: - Auth Service Protocol

/// Service protocol for Anchor authentication operations
@MainActor
public protocol AnchorAuthServiceProtocol {
    /// Process OAuth authentication data and store credentials
    func processOAuthAuthentication(_ authData: OAuthAuthenticationData) async throws -> AuthCredentialsProtocol
    
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
    
    /// Process OAuth authentication data and create authentication credentials
    public func processOAuthAuthentication(_ authData: OAuthAuthenticationData) async throws -> AuthCredentialsProtocol {
        print("🔐 AnchorAuthService: Processing OAuth authentication for handle: \(authData.handle)")
        print("🔐 AnchorAuthService: DID: \(authData.did)")
        print("🔐 AnchorAuthService: PDS URL: \(authData.pdsURL)")
        print("🔐 AnchorAuthService: Session ID: \(authData.sessionId)")
        print("🔐 AnchorAuthService: Has access token: \(authData.accessToken.isEmpty == false)")
        print("🔐 AnchorAuthService: Has refresh token: \(authData.refreshToken.isEmpty == false)")
        
        // Validate PDS URL
        guard !authData.pdsURL.isEmpty, URL(string: authData.pdsURL) != nil else {
            print("❌ AnchorAuthService: Invalid PDS URL: \(authData.pdsURL)")
            throw AnchorAuthError.invalidPDSURL(authData.pdsURL)
        }
        
        // Create credentials from OAuth data
        let credentials = createCredentials(from: authData)
        
        print("🔐 AnchorAuthService: Created credentials with session ID: \(credentials.sessionId ?? "nil")")
        
        // Store credentials securely
        try await storage.save(credentials)
        
        print("✅ AnchorAuthService: Credentials stored for handle: \(credentials.handle) with PDS: \(credentials.pdsURL)")
        
        return credentials
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
                
                // Update credentials with new tokens
                let updatedCredentials = AuthCredentials(
                    handle: credentials.handle,
                    accessToken: newTokens.accessToken,
                    refreshToken: newTokens.refreshToken,
                    did: credentials.did,
                    pdsURL: credentials.pdsURL,
                    expiresAt: Date().addingTimeInterval(3600), // Reset expiration
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
            
            // Update credentials with new tokens
            let updatedCredentials = AuthCredentials(
                handle: credentials.handle,
                accessToken: newTokens.accessToken,
                refreshToken: newTokens.refreshToken,
                did: credentials.did,
                pdsURL: credentials.pdsURL,
                expiresAt: Date().addingTimeInterval(3600), // Reset expiration
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
    
    /// Convert OAuth authentication data to authentication credentials
    private func createCredentials(from authData: OAuthAuthenticationData) -> AuthCredentials {
        let expiresAt = Date().addingTimeInterval(3600) // OAuth tokens typically expire in 1 hour
        
        return AuthCredentials(
            handle: authData.handle,
            accessToken: authData.accessToken,
            refreshToken: authData.refreshToken,
            did: authData.did,
            pdsURL: authData.pdsURL, // Use resolved PDS URL from OAuth flow
            expiresAt: expiresAt,
            appPassword: nil, // OAuth doesn't use app passwords
            sessionId: authData.sessionId // Backend API session ID
        )
    }
    
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
