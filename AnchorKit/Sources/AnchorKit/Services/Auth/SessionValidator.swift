//
//  SessionValidator.swift
//  AnchorKit
//
//  Created by Tijs Teulings on 16/08/2025.
//

import Foundation

/// Result of session validation
private struct ValidationResult {
    let valid: Bool
    let refreshed: Bool?
    let newTokens: (accessToken: String, refreshToken: String)?
}

/// Service responsible for session validation and management
@MainActor
public final class SessionValidator {
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
    
    // MARK: - Session Validation Methods
    
    /// Validate current session and automatically refresh tokens if needed
    public func validateSession(_ credentials: AuthCredentials) async throws -> AuthCredentials {
        print("🔄 SessionValidator: Validating session for @\(credentials.handle)")
        
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
            
            print("🔄 SessionValidator: Validation HTTP Status: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 401 {
                    throw AnchorAuthError.invalidAuthData
                }
                throw AnchorAuthError.networkError(NSError(domain: "HTTPError", code: httpResponse.statusCode))
            }
            
            // Parse the validation response
            let validationResponse = try parseValidationResponse(from: data)
            
            guard validationResponse.valid else {
                print("❌ SessionValidator: Session invalid")
                throw AnchorAuthError.invalidAuthData
            }
            
            // Check if tokens were refreshed by the backend
            if validationResponse.refreshed == true, let newTokens = validationResponse.newTokens {
                print("🔄 SessionValidator: Tokens were refreshed by backend")
                
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
                print("✅ SessionValidator: Updated credentials saved with new tokens")
                
                return updatedCredentials
            }
            
            print("✅ SessionValidator: Session valid, no token refresh needed")
            return credentials
            
        } catch {
            if error is AnchorAuthError {
                throw error
            } else {
                print("❌ SessionValidator: Session validation network error: \(error)")
                throw AnchorAuthError.networkError(error)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Parse session validation response from backend
    private func parseValidationResponse(from data: Data) throws -> ValidationResult {
        struct ValidationResponse: Codable {
            let valid: Bool
            let refreshed: Bool?
            let tokens: Tokens?
            let error: String?
        }
        
        struct Tokens: Codable {
            let access_token: String
            let refresh_token: String
        }
        
        let response = try JSONDecoder().decode(ValidationResponse.self, from: data)
        
        let newTokens: (accessToken: String, refreshToken: String)?
        if let tokens = response.tokens {
            newTokens = (accessToken: tokens.access_token, refreshToken: tokens.refresh_token)
        } else {
            newTokens = nil
        }
        
        return ValidationResult(valid: response.valid, refreshed: response.refreshed, newTokens: newTokens)
    }
}
