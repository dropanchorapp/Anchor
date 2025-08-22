//
//  SecureMobileOAuthCoordinator.swift
//  AnchorKit
//
//  Created by Tijs Teulings on 22/08/2025.
//

import Foundation

/// Secure OAuth coordinator for mobile PKCE authentication flow
/// 
/// Coordinates the complete secure OAuth flow:
/// 1. Generate PKCE parameters
/// 2. Initiate mobile OAuth with code_challenge
/// 3. Handle OAuth callback with PKCE verification
/// 4. Exchange tokens using code_verifier
///
/// This replaces the insecure flow that was vulnerable to protocol handler
/// interception attacks.
public final class SecureMobileOAuthCoordinator {
    // MARK: - Properties
    
    private let authService: AnchorAuthServiceProtocol
    private let pkceStorage: PKCEStorageProtocol
    private let session: URLSessionProtocol
    private let baseURL: URL
    
    // MARK: - Initialization
    
    public init(
        authService: AnchorAuthServiceProtocol,
        pkceStorage: PKCEStorageProtocol,
        session: URLSessionProtocol = URLSession.shared,
        baseURL: String = "https://dropanchor.app"
    ) {
        self.authService = authService
        self.pkceStorage = pkceStorage
        self.session = session
        self.baseURL = URL(string: baseURL)!
    }
    
    // MARK: - Secure OAuth Flow
    
    /// Start secure mobile OAuth flow with PKCE protection
    /// 
    /// Generates PKCE parameters and initiates OAuth flow with backend.
    /// Returns URL for WebView to navigate to.
    ///
    /// - Parameter handle: Bluesky handle to authenticate
    /// - Returns: OAuth URL for WebView navigation
    /// - Throws: OAuth errors if flow initialization fails
    @MainActor
    public func startSecureOAuthFlow(handle: String) async throws -> URL {
        print("🔐 SecureMobileOAuthCoordinator: Starting secure OAuth flow for @\(handle)")
        
        // Generate PKCE parameters
        let pkce = PKCEGenerator.generatePKCE()
        print("🔐 SecureMobileOAuthCoordinator: Generated PKCE parameters")
        print("🔐 SecureMobileOAuthCoordinator: Code challenge: \(pkce.codeChallenge.prefix(16))...")
        print("🔐 SecureMobileOAuthCoordinator: Code verifier length: \(pkce.codeVerifier.count)")
        
        // Call mobile OAuth start endpoint with code_challenge
        let sessionId = try await initiateOAuthWithPKCE(handle: handle, codeChallenge: pkce.codeChallenge)
        print("🔐 SecureMobileOAuthCoordinator: OAuth initiated with session ID: \(sessionId.prefix(8))...")
        
        // Store code verifier securely for token exchange
        try await pkceStorage.storePKCEVerifier(pkce.codeVerifier, for: sessionId)
        print("🔐 SecureMobileOAuthCoordinator: Code verifier stored securely")
        
        // Return mobile auth URL
        let authURL = baseURL.appendingPathComponent("/mobile-auth")
        print("✅ SecureMobileOAuthCoordinator: Secure OAuth flow started successfully")
        
        return authURL
    }
    
    /// Complete secure OAuth flow with PKCE verification
    /// 
    /// Handles OAuth callback URL and exchanges authorization code
    /// using stored PKCE code verifier for security.
    ///
    /// - Parameter callbackURL: OAuth callback URL from WebView
    /// - Returns: Authentication credentials if successful
    /// - Throws: OAuth errors if token exchange fails
    @MainActor
    public func completeSecureOAuthFlow(callbackURL: URL) async throws -> AuthCredentialsProtocol {
        print("🔐 SecureMobileOAuthCoordinator: Completing secure OAuth flow")
        print("🔐 SecureMobileOAuthCoordinator: Callback URL: \(callbackURL)")
        
        // Parse session ID from callback URL
        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let codeQueryItem = components.queryItems?.first(where: { $0.name == "code" }),
              let sessionId = codeQueryItem.value else {
            print("❌ SecureMobileOAuthCoordinator: No session ID found in callback URL")
            throw SecureMobileOAuthError.invalidCallback
        }
        
        print("🔐 SecureMobileOAuthCoordinator: Found session ID: \(sessionId.prefix(8))...")
        
        // Retrieve stored code verifier
        guard let codeVerifier = try await pkceStorage.retrievePKCEVerifier(for: sessionId) else {
            print("❌ SecureMobileOAuthCoordinator: No code verifier found for session")
            throw SecureMobileOAuthError.missingCodeVerifier
        }
        
        print("🔐 SecureMobileOAuthCoordinator: Retrieved code verifier for PKCE validation")
        print("🔐 SecureMobileOAuthCoordinator: Code verifier length: \(codeVerifier.count)")
        
        do {
            // Exchange authorization code with PKCE verification
            let credentials = try await authService.exchangeAuthorizationCodeWithPKCE(sessionId, codeVerifier: codeVerifier)
            print("✅ SecureMobileOAuthCoordinator: Token exchange successful with PKCE")
            
            // Clean up stored code verifier
            try await pkceStorage.clearPKCEVerifier(for: sessionId)
            print("🧹 SecureMobileOAuthCoordinator: Code verifier cleaned up")
            
            print("✅ SecureMobileOAuthCoordinator: Secure OAuth flow completed successfully")
            return credentials
            
        } catch {
            print("❌ SecureMobileOAuthCoordinator: Token exchange failed: \(error)")
            
            // Clean up stored code verifier even on failure
            try? await pkceStorage.clearPKCEVerifier(for: sessionId)
            print("🧹 SecureMobileOAuthCoordinator: Code verifier cleaned up after failure")
            
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    /// Initiate OAuth with PKCE by calling mobile start endpoint
    @MainActor
    private func initiateOAuthWithPKCE(handle: String, codeChallenge: String) async throws -> String {
        let url = baseURL.appendingPathComponent("/api/auth/mobile-start")
        
        // Create request with PKCE code challenge
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("AnchorApp/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        
        let requestBody = [
            "handle": handle,
            "code_challenge": codeChallenge
        ]
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        // Perform request
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SecureMobileOAuthError.networkError
            }
            
            print("🔐 SecureMobileOAuthCoordinator: Mobile start HTTP Status: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ SecureMobileOAuthCoordinator: Mobile start failed: \(errorMessage)")
                throw SecureMobileOAuthError.serverError(httpResponse.statusCode, errorMessage)
            }
            
            // Parse session ID from response
            let responseData = try JSONDecoder().decode(MobileStartResponse.self, from: data)
            return responseData.sessionId
            
        } catch {
            if error is SecureMobileOAuthError {
                throw error
            } else {
                print("❌ SecureMobileOAuthCoordinator: Network error: \(error)")
                throw SecureMobileOAuthError.networkError
            }
        }
    }
}

// MARK: - Mobile Start Response

/// Response from mobile OAuth start endpoint
private struct MobileStartResponse: Codable {
    let authUrl: String
    let handle: String
    let did: String
    let sessionId: String
    
    enum CodingKeys: String, CodingKey {
        case authUrl
        case handle
        case did
        case sessionId = "session_id"
    }
}

// MARK: - Secure Mobile OAuth Errors

/// Errors that can occur during secure mobile OAuth flow
public enum SecureMobileOAuthError: Error, LocalizedError {
    case invalidCallback
    case missingCodeVerifier
    case networkError
    case serverError(Int, String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidCallback:
            return "Invalid OAuth callback URL"
        case .missingCodeVerifier:
            return "PKCE code verifier not found - OAuth session may have expired"
        case .networkError:
            return "Network error during OAuth flow"
        case .serverError(let code, let message):
            return "OAuth server error (\(code)): \(message)"
        }
    }
}
