//
//  SecureMobileOAuthCoordinator.swift
//  AnchorKit
//
//  Created by Tijs Teulings on 22/08/2025.
//

import Foundation

// MARK: - Base64URL Decoding Extension

extension Data {
    init?(base64URLEncoded string: String) {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Add padding if needed
        let padLength = 4 - (base64.count % 4)
        if padLength < 4 {
            base64 += String(repeating: "=", count: padLength)
        }
        
        self.init(base64Encoded: base64)
    }
}

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
public final class SecureMobileOAuthCoordinator: @unchecked Sendable {
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
        let response = try await initiateOAuthWithPKCE(handle: handle, codeChallenge: pkce.codeChallenge)
        print("🔐 SecureMobileOAuthCoordinator: OAuth initiated with session ID: \(response.sessionId.prefix(8))...")
        
        // Store code verifier securely for token exchange
        try await pkceStorage.storePKCEVerifier(pkce.codeVerifier, for: response.sessionId)
        print("🔐 SecureMobileOAuthCoordinator: Code verifier stored securely")
        
        // Return the actual OAuth URL from backend (bypasses web page)
        let authURL = URL(string: response.authUrl)!
        print("✅ SecureMobileOAuthCoordinator: Secure OAuth flow started successfully")
        print("🔗 SecureMobileOAuthCoordinator: OAuth URL: \(authURL)")
        
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
        
        // Parse session ID from callback URL (backend puts session ID in 'code' parameter)
        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let codeQueryItem = components.queryItems?.first(where: { $0.name == "code" }),
              let sessionId = codeQueryItem.value else {
            print("❌ SecureMobileOAuthCoordinator: Missing session ID in callback URL")
            throw SecureMobileOAuthError.invalidCallback
        }
        
        print("🔐 SecureMobileOAuthCoordinator: Found session ID from callback: \(sessionId.prefix(8))...")
        
        // Retrieve stored code verifier for PKCE validation
        guard let codeVerifier = try await pkceStorage.retrievePKCEVerifier(for: sessionId) else {
            print("❌ SecureMobileOAuthCoordinator: No code verifier found for session")
            throw SecureMobileOAuthError.missingCodeVerifier
        }

        print("🔐 SecureMobileOAuthCoordinator: Retrieved code verifier for PKCE validation")
        print("🔐 SecureMobileOAuthCoordinator: Code verifier length: \(codeVerifier.count)")

        do {
            // Use existing /api/auth/exchange endpoint with proper PKCE
            let credentials = try await exchangeTokensWithPKCE(
                sessionId: sessionId,
                codeVerifier: codeVerifier
            )
            print("✅ SecureMobileOAuthCoordinator: Token exchange successful with PKCE")
            
            // Clean up stored code verifier
            try await pkceStorage.clearPKCEVerifier(for: sessionId)
            print("🧹 SecureMobileOAuthCoordinator: Code verifier cleaned up")
            
            print("✅ SecureMobileOAuthCoordinator: Secure OAuth flow completed successfully")
            return credentials
            
        } catch {
            print("❌ SecureMobileOAuthCoordinator: Mobile OAuth completion failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    /// Exchange tokens with PKCE using the existing backend endpoint
    private func exchangeTokensWithPKCE(sessionId: String, codeVerifier: String) async throws -> AuthCredentialsProtocol {
        print("🔐 SecureMobileOAuthCoordinator: Exchanging tokens with PKCE verification")
        
        let baseURL = URL(string: "https://dropanchor.app")!
        let url = baseURL.appendingPathComponent("/api/auth/exchange")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = [
            "code": sessionId,
            "code_verifier": codeVerifier
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("🔐 SecureMobileOAuthCoordinator: Sending PKCE token exchange request")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ SecureMobileOAuthCoordinator: Invalid response type")
            throw SecureMobileOAuthError.networkError
        }
        
        print("🔐 SecureMobileOAuthCoordinator: Backend response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            print("❌ SecureMobileOAuthCoordinator: Backend error: \(httpResponse.statusCode)")
            throw SecureMobileOAuthError.authenticationFailed
        }
        
        // Parse backend response to extract credentials
        guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let handle = jsonResponse["handle"] as? String,
              let did = jsonResponse["did"] as? String,
              let accessToken = jsonResponse["access_token"] as? String,
              let refreshToken = jsonResponse["refresh_token"] as? String,
              let pdsUrl = jsonResponse["pds_url"] as? String else {
            print("❌ SecureMobileOAuthCoordinator: Invalid backend response format")
            if let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("🔍 SecureMobileOAuthCoordinator: Actual response keys: \(Array(jsonResponse.keys))")
            }
            throw SecureMobileOAuthError.authenticationFailed
        }
        
        print("✅ SecureMobileOAuthCoordinator: Successfully parsed credentials from backend")
        print("🔐 SecureMobileOAuthCoordinator: Handle: @\(handle)")
        print("🔐 SecureMobileOAuthCoordinator: DID: \(did)")
        print("🔐 SecureMobileOAuthCoordinator: PDS URL: \(pdsUrl)")
        
        // Create AuthCredentials from backend response
        let credentials = AuthCredentials(
            handle: handle,
            accessToken: accessToken,
            refreshToken: refreshToken,
            did: did,
            pdsURL: pdsUrl,
            expiresAt: Date().addingTimeInterval(3600 * 24), // 24 hours from now
            sessionId: UUID().uuidString
        )
        
        return credentials
    }
    
    /// Initiate OAuth with PKCE by calling mobile start endpoint
    private func initiateOAuthWithPKCE(handle: String, codeChallenge: String) async throws -> MobileStartResponse {
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
            
            // Parse full response 
            let responseData = try JSONDecoder().decode(MobileStartResponse.self, from: data)
            return responseData
            
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
    case authenticationFailed
    case serverError(Int, String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidCallback:
            return "Invalid OAuth callback URL"
        case .missingCodeVerifier:
            return "PKCE code verifier not found - OAuth session may have expired"
        case .networkError:
            return "Network error during OAuth flow"
        case .authenticationFailed:
            return "Authentication failed"
        case .serverError(let code, let message):
            return "OAuth server error (\(code)): \(message)"
        }
    }
}
