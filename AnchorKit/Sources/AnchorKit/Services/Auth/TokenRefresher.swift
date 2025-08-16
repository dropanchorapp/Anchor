//
//  TokenRefresher.swift
//  AnchorKit
//
//  Created by Tijs Teulings on 16/08/2025.
//

import Foundation

/// Result of token refresh operation
private struct RefreshResult {
    let success: Bool
    let newTokens: (accessToken: String, refreshToken: String)?
}

/// Service responsible for token refresh operations
@MainActor
public final class TokenRefresher {
    // MARK: - Properties
    
    private let storage: CredentialsStorageProtocol
    private let session: URLSessionProtocol
    private let baseURL: URL
    
    // MARK: - Initialization
    
    public init(
        storage: CredentialsStorageProtocol,
        session: URLSessionProtocol,
        baseURL: URL
    ) {
        self.storage = storage
        self.session = session
        self.baseURL = baseURL
    }
    
    // MARK: - Token Refresh Methods
    
    /// Explicitly refresh tokens using refresh token
    public func refreshTokens(_ credentials: AuthCredentials) async throws -> AuthCredentials {
        print("🔄 TokenRefresher: Explicitly refreshing tokens for @\(credentials.handle)")
        
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
            
            print("🔄 TokenRefresher: Refresh HTTP Status: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 404 {
                    throw AnchorAuthError.invalidAuthData
                }
                throw AnchorAuthError.networkError(NSError(domain: "HTTPError", code: httpResponse.statusCode))
            }
            
            // Parse the refresh response
            let refreshResponse = try parseRefreshResponse(from: data)
            
            guard refreshResponse.success, let newTokens = refreshResponse.newTokens else {
                print("❌ TokenRefresher: Token refresh failed")
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
            print("✅ TokenRefresher: Token refresh successful, new credentials saved")
            
            return updatedCredentials
            
        } catch {
            if error is AnchorAuthError {
                throw error
            } else {
                print("❌ TokenRefresher: Token refresh network error: \(error)")
                throw AnchorAuthError.networkError(error)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Parse token refresh response from backend
    private func parseRefreshResponse(from data: Data) throws -> RefreshResult {
        struct RefreshResponse: Codable {
            let success: Bool
            let tokens: Tokens?
            let error: String?
        }
        
        struct Tokens: Codable {
            let access_token: String
            let refresh_token: String
        }
        
        let response = try JSONDecoder().decode(RefreshResponse.self, from: data)
        
        let newTokens: (accessToken: String, refreshToken: String)?
        if let tokens = response.tokens {
            newTokens = (accessToken: tokens.access_token, refreshToken: tokens.refresh_token)
        } else {
            newTokens = nil
        }
        
        return RefreshResult(success: response.success, newTokens: newTokens)
    }
}
