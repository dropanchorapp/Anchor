//
//  IronSessionMobileOAuthCoordinator.swift
//  AnchorKit
//
//  Iron Session-based OAuth coordinator for BookHive-style authentication
//

import Foundation

/// Iron Session-based OAuth coordinator for mobile authentication
/// 
/// Coordinates OAuth flow similar to BookHive's implementation:
/// 1. Use WebView to complete OAuth on backend
/// 2. Backend handles DPoP tokens server-side
/// 3. Backend returns sealed session ID for mobile use
/// 4. Store sealed session ID securely in iOS Keychain
///
/// This provides the same security benefits as BookHive's approach where
/// DPoP tokens never leave the backend server.
@MainActor
public final class IronSessionMobileOAuthCoordinator: @unchecked Sendable {
    
    // MARK: - Properties
    
    private let credentialsStorage: CredentialsStorageProtocol
    private let session: URLSessionProtocol
    private let baseURL: URL
    
    // MARK: - Initialization
    
    public init(
        credentialsStorage: CredentialsStorageProtocol = KeychainCredentialsStorage(),
        session: URLSessionProtocol = URLSession.shared,
        baseURL: String = "https://dropanchor.app"
    ) {
        self.credentialsStorage = credentialsStorage
        self.session = session
        self.baseURL = URL(string: baseURL)!
    }
    
    // MARK: - Iron Session OAuth Flow
    
    /// Start direct Iron Session OAuth flow for mobile
    ///
    /// Loads mobile auth page where user enters their handle and starts OAuth flow.
    /// Uses the new dedicated mobile OAuth endpoint.
    ///
    /// - Returns: Mobile OAuth URL for WebView navigation
    public func startDirectOAuthFlow() async throws -> URL {
        print("🔐 IronSessionMobileOAuthCoordinator: Starting direct Iron Session OAuth flow")
        
        // Load the mobile auth page
        let authURL = baseURL.appendingPathComponent("/mobile-auth")
        print("✅ IronSessionMobileOAuthCoordinator: Direct OAuth flow URL generated")
        print("🔗 IronSessionMobileOAuthCoordinator: OAuth URL: \(authURL)")
        
        return authURL
    }
    
    /// Complete Iron Session OAuth flow
    ///
    /// Handles OAuth callback URL from backend and extracts sealed session ID.
    /// The backend has already completed the OAuth flow and sealed the session.
    ///
    /// - Parameter callbackURL: OAuth callback URL from WebView  
    /// - Returns: Authentication credentials with sealed session ID
    /// - Throws: OAuth errors if flow completion fails
    public func completeIronSessionOAuthFlow(callbackURL: URL) async throws -> AuthCredentialsProtocol {
        print("🔐 IronSessionMobileOAuthCoordinator: Completing Iron Session OAuth flow")
        print("🔐 IronSessionMobileOAuthCoordinator: Callback URL: \(callbackURL)")
        
        // Parse session data from callback URL (BookHive-style)
        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            print("❌ IronSessionMobileOAuthCoordinator: Invalid callback URL format")
            throw IronSessionOAuthError.invalidCallback
        }
        
        // Extract required parameters from callback (updated format)
        guard let did = queryItems.first(where: { $0.name == "did" })?.value,
              let sealedSessionToken = queryItems.first(where: { $0.name == "session_token" })?.value else {
            print("❌ IronSessionMobileOAuthCoordinator: Missing required parameters in callback")
            print("🔍 IronSessionMobileOAuthCoordinator: Available query items: \(queryItems.map(\.name))")
            throw IronSessionOAuthError.invalidCallback
        }
        
        // Extract handle from DID - we don't get handle in callback anymore
        let handle = "user" // We'll get the handle from session validation
        
        print("✅ IronSessionMobileOAuthCoordinator: Successfully parsed callback parameters")
        print("🔐 IronSessionMobileOAuthCoordinator: Handle: @\(handle)")
        print("🔐 IronSessionMobileOAuthCoordinator: DID: \(did)")
        print("🔐 IronSessionMobileOAuthCoordinator: Sealed session token length: \(sealedSessionToken.count)")
        
        // Validate session to get handle from backend
        let apiClient = IronSessionAPIClient(baseURL: baseURL.absoluteString)
        let tempCredentials = AuthCredentials(
            handle: "temp",
            accessToken: "iron-session-backend-managed",
            refreshToken: "iron-session-backend-managed",
            did: did,
            pdsURL: "determined-by-backend",
            expiresAt: Date().addingTimeInterval(60 * 60 * 24),
            sessionId: sealedSessionToken
        )
        
        // Store temp credentials to validate session
        let credentialsStorage = KeychainCredentialsStorage()
        try await credentialsStorage.save(tempCredentials)
        
        // Validate session to get actual handle
        do {
            let responseData = try await apiClient.authenticatedRequest(path: "/api/auth/session")
            let sessionData = try JSONSerialization.jsonObject(with: responseData) as? [String: Any]
            
            guard let sessionData = sessionData,
                  let actualHandle = sessionData["userHandle"] as? String else {
                print("❌ IronSessionMobileOAuthCoordinator: Could not get handle from session")
                throw IronSessionOAuthError.invalidCallback
            }
            
            // Create final credentials with actual handle
            let credentials = AuthCredentials(
                handle: actualHandle,
                accessToken: "iron-session-backend-managed", // Placeholder - tokens are backend-managed
                refreshToken: "iron-session-backend-managed", // Placeholder - tokens are backend-managed  
                did: did,
                pdsURL: "determined-by-backend", // Backend resolves actual PDS URL
                expiresAt: Date().addingTimeInterval(60 * 60 * 24), // 24 hours session TTL
                sessionId: sealedSessionToken // This is the sealed session token for API calls
            )
            
            print("✅ IronSessionMobileOAuthCoordinator: Retrieved handle: @\(actualHandle)")
            return credentials
            
        } catch {
            print("❌ IronSessionMobileOAuthCoordinator: Failed to validate session: \(error)")
            throw IronSessionOAuthError.invalidCallback
        }
    }
    
    /// Refresh session using Iron Session backend
    ///
    /// Calls the mobile refresh token endpoint to extend session lifetime.
    /// Returns updated credentials with refreshed sealed session ID.
    ///
    /// - Returns: Updated credentials with refreshed session
    /// - Throws: Refresh errors if session refresh fails
    public func refreshIronSession() async throws -> AuthCredentialsProtocol {
        print("🔄 IronSessionMobileOAuthCoordinator: Refreshing Iron Session")
        
        // Load current credentials to get session ID
        guard let currentCredentials = await credentialsStorage.load(),
              let currentSessionId = currentCredentials.sessionId else {
            print("❌ IronSessionMobileOAuthCoordinator: No current session to refresh")
            throw IronSessionOAuthError.noCurrentSession
        }
        
        print("🔄 IronSessionMobileOAuthCoordinator: Found current session to refresh")
        
        // Call mobile refresh endpoint with Bearer token
        let url = baseURL.appendingPathComponent("/mobile/refresh-token")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Send current session ID as Bearer token
        request.setValue("Bearer \(currentSessionId)", forHTTPHeaderField: "Authorization")
        request.setValue("AnchorApp/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ IronSessionMobileOAuthCoordinator: Invalid response type during refresh")
                throw IronSessionOAuthError.networkError
            }
            
            print("🔄 IronSessionMobileOAuthCoordinator: Refresh response status: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                print("❌ IronSessionMobileOAuthCoordinator: Session refresh failed: \(httpResponse.statusCode)")
                throw IronSessionOAuthError.sessionRefreshFailed
            }
            
            return try parseRefreshResponse(data: data, currentCredentials: currentCredentials)
            
        } catch {
            if error is IronSessionOAuthError {
                throw error
            } else {
                print("❌ IronSessionMobileOAuthCoordinator: Network error during refresh: \(error)")
                throw IronSessionOAuthError.networkError
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Parse refresh response and create updated credentials (BookHive pattern)
    /// 
    /// - Parameters:
    ///   - data: Response data from refresh endpoint
    ///   - currentCredentials: Current credentials to use as base for updates
    /// - Returns: Updated credentials with refreshed sealed session ID
    /// - Throws: IronSessionOAuthError if parsing fails
    private func parseRefreshResponse(
        data: Data, 
        currentCredentials: AuthCredentials
    ) throws -> AuthCredentials {
        // Parse refresh response (BookHive pattern - sealed session IDs only)
        guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = jsonResponse["success"] as? Bool,
              success,
              let payload = jsonResponse["payload"] as? [String: Any],
              let newSealedSessionId = payload["sid"] as? String,
              let did = payload["did"] as? String else {
            print("❌ IronSessionMobileOAuthCoordinator: Invalid refresh response format")
            throw IronSessionOAuthError.sessionRefreshFailed
        }
        
        print("✅ IronSessionMobileOAuthCoordinator: Session refreshed successfully")
        print("🔄 IronSessionMobileOAuthCoordinator: New sealed session ID length: " +
              "\(newSealedSessionId.count)")
        print("🔄 IronSessionMobileOAuthCoordinator: Using BookHive pattern - OAuth tokens managed server-side")
        
        // Update credentials with new sealed session ID (BookHive pattern)
        // OAuth tokens are managed server-side and never sent to mobile client
        return AuthCredentials(
            handle: currentCredentials.handle,
            accessToken: "iron-session-backend-managed", // Tokens managed server-side
            refreshToken: "iron-session-backend-managed", // Tokens managed server-side
            did: did,
            pdsURL: currentCredentials.pdsURL,
            expiresAt: Date().addingTimeInterval(60 * 60 * 24 * 7), // 7 days session TTL
            sessionId: newSealedSessionId // Updated sealed session ID for API calls
        )
    }
}

// MARK: - Iron Session OAuth Errors

/// Errors that can occur during Iron Session OAuth flow
public enum IronSessionOAuthError: Error, LocalizedError {
    case invalidCallback
    case noCurrentSession
    case networkError
    case sessionRefreshFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidCallback:
            return "Invalid OAuth callback URL from Iron Session backend"
        case .noCurrentSession:
            return "No current session to refresh"
        case .networkError:
            return "Network error during Iron Session communication"
        case .sessionRefreshFailed:
            return "Iron Session refresh failed"
        }
    }
}
