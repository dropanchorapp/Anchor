//
//  OAuthTokenExchanger.swift
//  AnchorKit
//
//  Created by Tijs Teulings on 16/08/2025.
//

import Foundation

/// Service responsible for OAuth 2.1 token exchange operations
@MainActor
public final class OAuthTokenExchanger {
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
    
    // MARK: - Token Exchange Methods
    
    /// Exchange authorization code with PKCE verification for secure mobile OAuth
    public func exchangeAuthorizationCodeWithPKCE(_ code: String, codeVerifier: String) async throws -> AuthCredentialsProtocol {
        return try await performTokenExchange(requestBody: ["code": code, "code_verifier": codeVerifier])
    }
    
    // MARK: - Private Methods
    
    /// Shared OAuth 2.1 compliant token exchange implementation
    private func performTokenExchange(requestBody: [String: String]) async throws -> AuthCredentialsProtocol {
        print("🔐 OAuthTokenExchanger: Performing OAuth 2.1 token exchange")
        
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
            
            print("🔐 OAuthTokenExchanger: Token exchange HTTP Status: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ OAuthTokenExchanger: Token exchange failed: \(errorMessage)")
                throw AnchorAuthError.networkError(NSError(domain: "HTTPError", code: httpResponse.statusCode))
            }
            
            // Parse the OAuth 2.1 compliant token response
            let tokenResponse = try JSONDecoder().decode(TokenExchangeResponse.self, from: data)
            
            print("🔐 OAuthTokenExchanger: Token exchange successful for handle: \(tokenResponse.handle)")
            print("🔐 OAuthTokenExchanger: Token expires in: \(tokenResponse.expires_in) seconds (OAuth 2.1 standard)")
            print("🔐 OAuthTokenExchanger: PDS URL from backend: '\(tokenResponse.pds_url)'")
            print("🔐 OAuthTokenExchanger: DID: \(tokenResponse.did)")
            print("🔐 OAuthTokenExchanger: Session ID: \(tokenResponse.session_id)")
            
            // Calculate expiration time from expires_in following OAuth 2.1 spec
            let expiresAt = Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in))
            print("🔐 OAuthTokenExchanger: Calculated expiration date: \(expiresAt)")
            
            // Validate PDS URL
            guard !tokenResponse.pds_url.isEmpty, URL(string: tokenResponse.pds_url) != nil else {
                print("❌ OAuthTokenExchanger: Invalid PDS URL: '\(tokenResponse.pds_url)'")
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
            
            print("🔐 OAuthTokenExchanger: Created OAuth 2.1 compliant credentials with session ID: " +
                  "\(credentials.sessionId ?? "nil")")
            
            // Store credentials securely
            do {
                try await storage.save(credentials)
                print("✅ OAuthTokenExchanger: Credentials stored successfully")
            } catch {
                print("❌ OAuthTokenExchanger: Failed to store credentials: \(error)")
                throw AnchorAuthError.storageError(error)
            }
            
            print("✅ OAuthTokenExchanger: OAuth 2.1 authentication process completed for handle: \(credentials.handle)")
            return credentials
            
        } catch {
            if error is AnchorAuthError {
                throw error
            } else {
                print("❌ OAuthTokenExchanger: Token exchange network error: \(error)")
                throw AnchorAuthError.networkError(error)
            }
        }
    }
}
