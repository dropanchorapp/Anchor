//
//  OAuthService.swift
//  AnchorKit
//
//  Created by Claude on 10/08/2025.
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
    public let avatar: String?
    public let displayName: String?
    
    public init(
        accessToken: String,
        refreshToken: String,
        did: String,
        handle: String,
        sessionId: String,
        avatar: String? = nil,
        displayName: String? = nil
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.did = did
        self.handle = handle
        self.sessionId = sessionId
        self.avatar = avatar
        self.displayName = displayName
    }
}

// MARK: - OAuth Service Protocol

/// Service protocol for OAuth authentication operations
@MainActor
public protocol OAuthServiceProtocol {
    /// Process OAuth authentication data and store credentials
    func processOAuthAuthentication(_ authData: OAuthAuthenticationData) async throws -> AuthCredentialsProtocol
}

// MARK: - OAuth Service

/// OAuth authentication service for AT Protocol
///
/// Handles OAuth authentication flow completion by:
/// - Converting OAuth tokens to AT Protocol credentials
/// - Storing credentials securely
/// - Integrating with existing authentication flow
@Observable
public final class OAuthService: OAuthServiceProtocol {
    // MARK: - Properties
    
    private let storage: CredentialsStorageProtocol
    private let client: ATProtoClientProtocol
    
    // MARK: - Initialization
    
    /// Initialize OAuth service with dependencies
    public init(
        storage: CredentialsStorageProtocol,
        client: ATProtoClientProtocol
    ) {
        self.storage = storage
        self.client = client
    }
    
    /// Convenience initializer for production use
    public convenience init(session: URLSessionProtocol = URLSession.shared) {
        let storage = KeychainCredentialsStorage()
        let client = ATProtoClient(session: session)
        self.init(storage: storage, client: client)
    }
    
    // MARK: - OAuth Methods
    
    /// Process OAuth authentication data and create AT Protocol credentials
    public func processOAuthAuthentication(_ authData: OAuthAuthenticationData) async throws -> AuthCredentialsProtocol {
        // Create credentials from OAuth data
        let credentials = createCredentials(from: authData)
        
        // Store credentials securely
        try await storage.save(credentials)
        
        print("✅ OAuth credentials stored for handle: \(credentials.handle)")
        
        return credentials
    }
    
    // MARK: - Private Methods
    
    /// Convert OAuth authentication data to AT Protocol credentials
    private func createCredentials(from authData: OAuthAuthenticationData) -> AuthCredentials {
        let expiresAt = Date().addingTimeInterval(3600) // OAuth tokens typically expire in 1 hour
        
        return AuthCredentials(
            handle: authData.handle,
            accessToken: authData.accessToken,
            refreshToken: authData.refreshToken,
            did: authData.did,
            pdsURL: "https://bsky.social", // Default PDS for OAuth flow
            expiresAt: expiresAt,
            appPassword: nil // OAuth doesn't use app passwords
        )
    }
}

// MARK: - OAuth Error Types

public enum OAuthError: LocalizedError {
    case invalidAuthData
    case storageError(Error)
    case networkError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidAuthData:
            return "Invalid OAuth authentication data"
        case .storageError(let error):
            return "Failed to store credentials: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}