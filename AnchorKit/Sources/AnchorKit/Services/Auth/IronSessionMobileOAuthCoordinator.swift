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
    private let config: OAuthConfiguration
    private let cookieManager: CookieManagerProtocol

    // MARK: - Initialization

    public init(
        credentialsStorage: CredentialsStorageProtocol = KeychainCredentialsStorage(),
        session: URLSessionProtocol = URLSession.shared,
        config: OAuthConfiguration = .default,
        cookieManager: CookieManagerProtocol = HTTPCookieManager()
    ) {
        self.credentialsStorage = credentialsStorage
        self.session = session
        self.config = config
        self.cookieManager = cookieManager
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
        let authURL = config.baseURL.appendingPathComponent("/mobile-auth")
        print("✅ IronSessionMobileOAuthCoordinator: Direct OAuth flow URL generated")
        print("🔗 IronSessionMobileOAuthCoordinator: OAuth URL: \(authURL)")

        return authURL
    }

    /// Complete Iron Session OAuth flow
    ///
    /// Handles OAuth callback URL from backend. Backend sets HttpOnly cookie with session.
    /// The backend has already completed the OAuth flow and set the session cookie.
    ///
    /// - Parameter callbackURL: OAuth callback URL from WebView
    /// - Returns: Authentication credentials with user info
    /// - Throws: OAuth errors if flow completion fails
    public func completeIronSessionOAuthFlow(callbackURL: URL) async throws -> AuthCredentialsProtocol {
        print("🔐 IronSessionMobileOAuthCoordinator: Completing Iron Session OAuth flow")
        print("🔐 IronSessionMobileOAuthCoordinator: Callback URL: \(callbackURL)")

        // Parse session data from callback URL
        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            print("❌ IronSessionMobileOAuthCoordinator: Invalid callback URL format")
            throw IronSessionOAuthError.invalidCallback
        }

        // Extract DID and session token from callback
        // Mobile OAuth flow includes session_token in URL since ASWebAuthenticationSession
        // cannot share cookies with URLSession
        guard let did = queryItems.first(where: { $0.name == "did" })?.value,
              let sessionToken = queryItems.first(where: { $0.name == "session_token" })?.value else {
            print("❌ IronSessionMobileOAuthCoordinator: Missing required parameters in callback")
            print("🔍 IronSessionMobileOAuthCoordinator: Available query items: \(queryItems.map(\.name))")
            throw IronSessionOAuthError.invalidCallback
        }

        print("✅ IronSessionMobileOAuthCoordinator: Successfully parsed callback parameters")
        print("🔐 IronSessionMobileOAuthCoordinator: DID: \(did)")
        print("🔐 IronSessionMobileOAuthCoordinator: Session token length: \(sessionToken.count)")

        // Manually set session cookie since ASWebAuthenticationSession doesn't share cookies
        // This cookie will be automatically included in all URLSession requests
        let expiresAt = Date().addingTimeInterval(config.sessionDuration)
        cookieManager.saveSessionCookie(
            sessionToken: sessionToken,
            expiresAt: expiresAt,
            domain: config.cookieDomain
        )

        // Validate session to get user info from backend using cookie
        // Make direct request without requiring credentials (cookie-only auth)
        let sessionURL = config.baseURL.appendingPathComponent("/api/auth/session")
        var sessionRequest = URLRequest(url: sessionURL)
        sessionRequest.httpMethod = "GET"
        sessionRequest.setValue("AnchorApp/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        // Cookie is automatically included by URLSession from HTTPCookieStorage.shared

        do {
            let (data, response) = try await session.data(for: sessionRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                debugPrint("❌ IronSessionMobileOAuthCoordinator: Invalid response type")
                throw IronSessionOAuthError.networkError
            }

            debugPrint("🔐 IronSessionMobileOAuthCoordinator: Session validation response: \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 200 else {
                debugPrint("❌ IronSessionMobileOAuthCoordinator: Session validation failed: \(httpResponse.statusCode)")
                throw IronSessionOAuthError.invalidCallback
            }

            let sessionData = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            guard let sessionData = sessionData,
                  let actualHandle = sessionData["userHandle"] as? String else {
                debugPrint("❌ IronSessionMobileOAuthCoordinator: Could not get handle from session")
                throw IronSessionOAuthError.invalidCallback
            }

            // Create credentials with session ID for cookie recreation on app restart
            let credentials = AuthCredentials(
                handle: actualHandle,
                accessToken: "iron-session-backend-managed", // Tokens are backend-managed
                refreshToken: "iron-session-backend-managed", // Tokens are backend-managed
                did: did,
                pdsURL: "determined-by-backend", // Backend resolves actual PDS URL
                expiresAt: Date().addingTimeInterval(config.sessionDuration),
                sessionId: sessionToken // Store session ID to recreate cookie on app restart
            )

            debugPrint("✅ IronSessionMobileOAuthCoordinator: Retrieved handle: @\(actualHandle)")
            return credentials

        } catch {
            debugPrint("❌ IronSessionMobileOAuthCoordinator: Failed to validate session: \(error)")
            throw IronSessionOAuthError.invalidCallback
        }
    }

    /// Refresh session using Iron Session backend
    ///
    /// Calls the mobile refresh token endpoint to extend session lifetime.
    /// Uses HttpOnly cookie for authentication following BFF pattern.
    ///
    /// - Returns: Updated credentials with refreshed expiration
    /// - Throws: Refresh errors if session refresh fails
    public func refreshIronSession() async throws -> AuthCredentialsProtocol {
        print("🔄 IronSessionMobileOAuthCoordinator: Refreshing Iron Session")

        // Load current credentials
        guard let currentCredentials = await credentialsStorage.load() else {
            print("❌ IronSessionMobileOAuthCoordinator: No current session to refresh")
            throw IronSessionOAuthError.noCurrentSession
        }

        print("🔄 IronSessionMobileOAuthCoordinator: Found current session to refresh")

        // Call mobile refresh endpoint using cookie authentication
        let url = config.baseURL.appendingPathComponent("/mobile/refresh-token")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("AnchorApp/1.0 (iOS)", forHTTPHeaderField: "User-Agent")

        // Cookie is automatically included by URLSession from HTTPCookieStorage.shared

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

    /// Parse refresh response and create updated credentials (BFF pattern)
    ///
    /// - Parameters:
    ///   - data: Response data from refresh endpoint
    ///   - currentCredentials: Current credentials to use as base for updates
    /// - Returns: Updated credentials with refreshed expiration
    /// - Throws: IronSessionOAuthError if parsing fails
    private func parseRefreshResponse(
        data: Data,
        currentCredentials: AuthCredentials
    ) throws -> AuthCredentials {
        // Parse refresh response - expect new session token for cookie update
        guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = jsonResponse["success"] as? Bool,
              success,
              let payload = jsonResponse["payload"] as? [String: Any],
              let did = payload["did"] as? String,
              let newSessionToken = payload["sid"] as? String else {
            print("❌ IronSessionMobileOAuthCoordinator: Invalid refresh response format")
            throw IronSessionOAuthError.sessionRefreshFailed
        }

        print("✅ IronSessionMobileOAuthCoordinator: Session refreshed successfully")
        print("🔄 IronSessionMobileOAuthCoordinator: Using BFF pattern - OAuth tokens managed server-side")
        print("🔄 IronSessionMobileOAuthCoordinator: New session token length: \(newSessionToken.count)")

        // Update session cookie with new token
        let expiresAt = Date().addingTimeInterval(config.sessionDuration)
        cookieManager.saveSessionCookie(
            sessionToken: newSessionToken,
            expiresAt: expiresAt,
            domain: config.cookieDomain
        )

        // Update credentials with new session ID and expiration (BFF pattern)
        // OAuth tokens are managed server-side, session via HttpOnly cookie
        return AuthCredentials(
            handle: currentCredentials.handle,
            accessToken: "iron-session-backend-managed", // Tokens managed server-side
            refreshToken: "iron-session-backend-managed", // Tokens managed server-side
            did: did,
            pdsURL: currentCredentials.pdsURL,
            expiresAt: Date().addingTimeInterval(config.sessionDuration),
            sessionId: newSessionToken // Store new session ID to recreate cookie on app restart
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
