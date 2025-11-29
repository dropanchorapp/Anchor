//
//  MobileOAuthCoordinator.swift
//  ATProtoFoundation
//
//  BFF (Backend-For-Frontend) OAuth coordinator for mobile authentication
//

import Foundation

/// BFF OAuth coordinator for mobile authentication
///
/// Coordinates OAuth flow using the Backend-For-Frontend pattern:
/// 1. Use WebView to complete OAuth on backend
/// 2. Backend handles DPoP tokens server-side
/// 3. Backend returns sealed session ID for mobile use
/// 4. Store sealed session ID securely in iOS Keychain
///
/// This provides security benefits where OAuth tokens and DPoP
/// never leave the backend server.
///
/// Note: This class performs network operations and should NOT be @MainActor isolated
/// to avoid blocking the UI thread. Network calls run on background threads.
public final class MobileOAuthCoordinator: @unchecked Sendable {

    // MARK: - Properties

    private let credentialsStorage: CredentialsStorageProtocol
    private let session: URLSessionProtocol
    private let config: OAuthConfiguration
    private let cookieManager: CookieManagerProtocol
    private let logger: Logger

    // MARK: - Initialization

    public init(
        credentialsStorage: CredentialsStorageProtocol,
        session: URLSessionProtocol = URLSession.shared,
        config: OAuthConfiguration = .default,
        cookieManager: CookieManagerProtocol = HTTPCookieManager(),
        logger: Logger = DebugLogger()
    ) {
        self.credentialsStorage = credentialsStorage
        self.session = session
        self.config = config
        self.cookieManager = cookieManager
        self.logger = logger
    }

    // MARK: - BFF OAuth Flow

    /// Start BFF OAuth flow for mobile
    ///
    /// Loads mobile auth page where user enters their handle and starts OAuth flow.
    /// Uses the dedicated mobile OAuth endpoint.
    ///
    /// - Returns: Mobile OAuth URL for WebView navigation
    public func startOAuthFlow() async throws -> URL {
        logger.log("Starting BFF OAuth flow", level: .info, category: .oauth)

        // Load the mobile auth page
        let authURL = config.baseURL.appendingPathComponent("/mobile-auth")
        logger.log("OAuth flow URL generated", level: .info, category: .oauth)
        logger.log("OAuth URL: \(authURL)", level: .debug, category: .oauth)

        return authURL
    }

    /// Complete BFF OAuth flow
    ///
    /// Handles OAuth callback URL from backend. Backend sets HttpOnly cookie with session.
    /// The backend has already completed the OAuth flow and set the session cookie.
    ///
    /// - Parameter callbackURL: OAuth callback URL from WebView
    /// - Returns: Authentication credentials with user info
    /// - Throws: OAuth errors if flow completion fails
    public func completeOAuthFlow(callbackURL: URL) async throws -> AuthCredentialsProtocol {
        logger.log("Completing BFF OAuth flow", level: .info, category: .oauth)
        logger.log("Callback URL: \(callbackURL)", level: .debug, category: .oauth)

        // Parse session data from callback URL
        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            logger.log("Invalid callback URL format", level: .error, category: .oauth)
            throw AuthenticationError.invalidCredentials("Invalid OAuth callback URL")
        }

        // Extract DID and session token from callback
        // Mobile OAuth flow includes session_token in URL since ASWebAuthenticationSession
        // cannot share cookies with URLSession
        guard let did = queryItems.first(where: { $0.name == "did" })?.value,
              let sessionToken = queryItems.first(where: { $0.name == "session_token" })?.value else {
            logger.log("Missing required parameters in callback", level: .error, category: .oauth)
            logger.log("Available query items: \(queryItems.map(\.name))", level: .debug, category: .oauth)
            throw AuthenticationError.invalidCredentials("Invalid OAuth callback URL")
        }

        logger.log("Successfully parsed callback parameters", level: .info, category: .oauth)
        logger.log("DID: \(did)", level: .debug, category: .oauth)
        logger.log("Session token length: \(sessionToken.count)", level: .debug, category: .oauth)

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
        sessionRequest.setValue(config.userAgent, forHTTPHeaderField: "User-Agent")
        // Cookie is automatically included by URLSession from HTTPCookieStorage.shared

        do {
            let (data, response) = try await session.data(for: sessionRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                logger.log("Invalid response type", level: .error, category: .oauth)
                throw AuthenticationError.networkError("Invalid response type")
            }

            logger.log("Session validation response: \(httpResponse.statusCode)", level: .debug, category: .oauth)

            guard httpResponse.statusCode == 200 else {
                logger.log("Session validation failed: \(httpResponse.statusCode)", level: .error, category: .oauth)
                throw AuthenticationError.invalidCredentials("Invalid OAuth callback URL")
            }

            let sessionData = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            guard let sessionData = sessionData,
                  let actualHandle = sessionData["userHandle"] as? String else {
                logger.log("Could not get handle from session", level: .error, category: .oauth)
                throw AuthenticationError.invalidCredentials("Invalid OAuth callback URL")
            }

            // Create credentials with session ID for cookie recreation on app restart
            let credentials = AuthCredentials(
                handle: actualHandle,
                accessToken: "backend-managed", // Tokens are backend-managed
                refreshToken: "backend-managed", // Tokens are backend-managed
                did: did,
                pdsURL: "determined-by-backend", // Backend resolves actual PDS URL
                expiresAt: Date().addingTimeInterval(config.sessionDuration),
                sessionId: sessionToken // Store session ID to recreate cookie on app restart
            )

            logger.log("Retrieved handle: @\(actualHandle)", level: .info, category: .oauth)
            return credentials

        } catch {
            logger.log("Failed to validate session: \(error)", level: .error, category: .oauth)
            throw AuthenticationError.invalidCredentials("Invalid OAuth callback URL")
        }
    }

    /// Refresh session using BFF backend
    ///
    /// Calls the mobile refresh token endpoint to extend session lifetime.
    /// Uses HttpOnly cookie for authentication following BFF pattern.
    ///
    /// - Returns: Updated credentials with refreshed expiration
    /// - Throws: Refresh errors if session refresh fails
    public func refreshSession() async throws -> AuthCredentialsProtocol {
        logger.log("Refreshing session", level: .info, category: .session)

        // Load current credentials
        guard let currentCredentials = await credentialsStorage.load() else {
            logger.log("No current session to refresh", level: .error, category: .session)
            throw AuthenticationError.sessionExpiredUnrecoverable
        }

        logger.log("Found current session to refresh", level: .debug, category: .session)

        // Call mobile refresh endpoint using cookie authentication
        let url = config.baseURL.appendingPathComponent("/mobile/refresh-token")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(config.userAgent, forHTTPHeaderField: "User-Agent")

        // Cookie is automatically included by URLSession from HTTPCookieStorage.shared

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                logger.log("Invalid response type during refresh", level: .error, category: .session)
                throw AuthenticationError.networkError("Invalid response type during refresh")
            }

            logger.log("Refresh response status: \(httpResponse.statusCode)", level: .debug, category: .session)

            guard httpResponse.statusCode == 200 else {
                logger.log("Session refresh failed: \(httpResponse.statusCode)", level: .error, category: .session)
                throw AuthenticationError.sessionExpiredUnrecoverable
            }

            return try parseRefreshResponse(data: data, currentCredentials: currentCredentials)

        } catch {
            if error is AuthenticationError {
                throw error
            } else {
                logger.log("Network error during refresh: \(error)", level: .error, category: .session)
                throw AuthenticationError.networkError(error.localizedDescription)
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
    /// - Throws: AuthenticationError if parsing fails
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
            logger.log("Invalid refresh response format", level: .error, category: .session)
            throw AuthenticationError.sessionExpiredUnrecoverable
        }

        logger.log("Session refreshed successfully", level: .info, category: .session)
        logger.log("Using BFF pattern - OAuth tokens managed server-side", level: .debug, category: .session)
        logger.log("New session token length: \(newSessionToken.count)", level: .debug, category: .session)

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
            accessToken: "backend-managed", // Tokens managed server-side
            refreshToken: "backend-managed", // Tokens managed server-side
            did: did,
            pdsURL: currentCredentials.pdsURL,
            expiresAt: Date().addingTimeInterval(config.sessionDuration),
            sessionId: newSessionToken // Store new session ID to recreate cookie on app restart
        )
    }
}
