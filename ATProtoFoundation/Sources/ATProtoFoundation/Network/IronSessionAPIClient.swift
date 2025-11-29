//
//  IronSessionAPIClient.swift  
//  AnchorKit
//
//  API client that uses Iron Session sealed session IDs for authentication
//

import Foundation

/// Represents a file attachment for multipart/form-data requests
public struct MultipartFile {
    public let fieldName: String
    public let filename: String
    public let data: Data
    public let contentType: String

    public init(fieldName: String, filename: String, data: Data, contentType: String) {
        self.fieldName = fieldName
        self.filename = filename
        self.data = data
        self.contentType = contentType
    }
}

/// API client for Iron Session authentication
///
/// Makes authenticated API calls using HttpOnly cookies for session management.
/// Follows AT Protocol OAuth BFF (Backend-For-Frontend) pattern where:
/// - Backend manages OAuth tokens server-side
/// - Client uses HttpOnly session cookies for authentication
/// - No bearer tokens exposed to client
///
/// Note: This class performs network operations and should NOT be @MainActor isolated
/// to avoid blocking the UI thread. Network calls run on background threads.
public final class IronSessionAPIClient: @unchecked Sendable {

    // MARK: - Properties

    internal let credentialsStorage: CredentialsStorageProtocol
    internal let session: URLSessionProtocol
    internal let config: OAuthConfiguration
    internal let logger: Logger

    // MARK: - Initialization

    public init(
        credentialsStorage: CredentialsStorageProtocol,
        session: URLSessionProtocol = URLSession.shared,
        config: OAuthConfiguration = .default,
        logger: Logger = DebugLogger()
    ) {
        self.credentialsStorage = credentialsStorage
        self.session = session
        self.config = config
        self.logger = logger

        // Configure URLSession for cookie-based authentication
        configureSessionForCookies(session)
    }

    /// Configure URLSession to use shared cookie storage
    private func configureSessionForCookies(_ session: URLSessionProtocol) {
        // Only configure real URLSession instances, not test mocks
        guard let urlSession = session as? URLSession else { return }

        // Ensure we're using shared cookie storage
        // This allows cookies set by ASWebAuthenticationSession to be available
        urlSession.configuration.httpCookieAcceptPolicy = .always
        urlSession.configuration.httpShouldSetCookies = true
        urlSession.configuration.httpCookieStorage = HTTPCookieStorage.shared
    }

    // MARK: - Authenticated API Calls

    /// Make authenticated API request using session cookies
    ///
    /// Uses HttpOnly session cookies for authentication following AT Protocol BFF pattern.
    /// URLSession automatically includes cookies from HTTPCookieStorage.shared.
    ///
    /// **Proactive Token Refresh**: Automatically refreshes session before it expires to prevent 401 errors.
    ///
    /// - Parameters:
    ///   - path: API endpoint path
    ///   - method: HTTP method (default: GET)
    ///   - body: Request body data (optional)
    /// - Returns: Response data
    /// - Throws: API errors if request fails
    public func authenticatedRequest(
        path: String,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> Data {
        return try await authenticatedRequest(path: path, method: method, body: body, retryCount: 0)
    }

    /// Internal method with retry counting to prevent infinite loops
    private func authenticatedRequest(
        path: String,
        method: String = "GET",
        body: Data? = nil,
        retryCount: Int = 0
    ) async throws -> Data {

        // Load and refresh credentials
        let credentials = try await loadAndRefreshCredentials()

        // Build and execute request
        let request = buildAuthenticatedRequest(path: path, method: method, body: body, credentials: credentials)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                logger.log("❌ Invalid response type", level: .error, category: .network)
                throw AuthenticationError.networkError("Invalid response type")
            }

            logger.log("🌐 Response status: \(httpResponse.statusCode)", level: .debug, category: .network)

            // Handle authentication failure with retry
            if httpResponse.statusCode == 401 {
                return try await handleAuthenticationFailure(
                    path: path,
                    method: method,
                    body: body,
                    retryCount: retryCount
                )
            }

            // Handle other errors
            guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
                logger.log("❌ API error: \(httpResponse.statusCode)", level: .error, category: .network)
                throw AuthenticationError.apiError(httpResponse.statusCode, "API error")
            }

            logger.log("✅ Request completed successfully", level: .info, category: .network)
            return data

        } catch {
            throw error is AuthenticationError ? error : AuthenticationError.networkError(error.localizedDescription)
        }
    }

    /// Load credentials and perform proactive token refresh if needed
    private func loadAndRefreshCredentials() async throws -> AuthCredentials {
        guard var credentials = await credentialsStorage.load() else {
            logger.log("❌ No credentials found", level: .error, category: .auth)
            throw AuthenticationError.invalidCredentials("Not authenticated - no session ID found")
        }

        // **PROACTIVE TOKEN REFRESH**: Check if tokens need refresh before making request
        credentials = try await performProactiveTokenRefresh(credentials: credentials)
        return credentials
    }

    /// Build authenticated URLRequest with headers
    ///
    /// Cookies are automatically included by URLSession from HTTPCookieStorage.shared.
    /// No Authorization header needed - backend uses HttpOnly cookies for auth.
    private func buildAuthenticatedRequest(
        path: String,
        method: String,
        body: Data?,
        credentials: AuthCredentials
    ) -> URLRequest {
        logger.log("🌐 Making authenticated request to \(path)", level: .debug, category: .network)

        let url = config.baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method

        // Add standard headers (cookies added automatically by URLSession)
        request.setValue(config.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Add body if provided
        if let body = body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return request
    }

    /// Handle 401 authentication failure with exponential backoff and retry
    private func handleAuthenticationFailure(
        path: String,
        method: String,
        body: Data?,
        retryCount: Int
    ) async throws -> Data {
        let maxRetries = 3

        // Check retry limit
        guard retryCount < maxRetries else {
            debugPrint("❌ IronSessionAPIClient: Maximum retry attempts (\(maxRetries)) exceeded for \(path)")
            throw AuthenticationError.invalidCredentials("Authentication failed after maximum retry attempts")
        }

        debugPrint(
            "🔐 IronSessionAPIClient: Session expired, attempting refresh " +
            "(attempt \(retryCount + 1)/\(maxRetries))"
        )

        // Exponential backoff
        let backoffDelay = min(pow(2.0, Double(retryCount)), 8.0) // Cap at 8 seconds
        try await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))

        // Attempt session refresh
        do {
            try await refreshSession()
            debugPrint("✅ IronSessionAPIClient: Session refreshed, retrying request")
        } catch {
            debugPrint("❌ IronSessionAPIClient: Token refresh failed: \(error)")
            // If refresh failed, there's no point in retrying the request
            throw error
        }

        // Retry with incremented counter
        return try await authenticatedRequest(
            path: path,
            method: method,
            body: body,
            retryCount: retryCount + 1
        )
    }

    /// Refresh session using OAuth coordinator
    internal func refreshSession() async throws {
        let coordinator = IronSessionMobileOAuthCoordinator(
            credentialsStorage: credentialsStorage,
            session: session,
            config: config
        )

        let refreshedCredentials = try await coordinator.refreshIronSession()
        // Save to storage - Swift will automatically hop to MainActor for @MainActor isolated method
        try await credentialsStorage.save(refreshedCredentials)
    }

    /// Make authenticated JSON request without request body
    ///
    /// Convenience method for JSON API calls with automatic response decoding.
    ///
    /// - Parameters:
    ///   - path: API endpoint path
    ///   - method: HTTP method (default: GET)
    /// - Returns: Decoded response object
    /// - Throws: API errors if request fails
    public func authenticatedJSONRequest<R: Codable>(
        path: String,
        method: String = "GET"
    ) async throws -> R {
        let responseData = try await authenticatedRequest(path: path, method: method, body: nil)
        return try JSONDecoder().decode(R.self, from: responseData)
    }

    /// Make authenticated JSON request with request body
    ///
    /// Convenience method for JSON API calls with automatic encoding/decoding.
    ///
    /// - Parameters:
    ///   - path: API endpoint path
    ///   - method: HTTP method (default: POST)
    ///   - requestBody: Object to encode as JSON
    /// - Returns: Decoded response object
    /// - Throws: API errors if request fails
    public func authenticatedJSONRequest<T: Codable, R: Codable>(
        path: String,
        method: String = "POST",
        requestBody: T
    ) async throws -> R {
        let bodyData = try JSONEncoder().encode(requestBody)
        let responseData = try await authenticatedRequest(path: path, method: method, body: bodyData)
        return try JSONDecoder().decode(R.self, from: responseData)
    }

    /// Check if user is currently authenticated
    ///
    /// Validates that we have credentials. Session is managed via HttpOnly cookie.
    ///
    /// - Returns: True if authenticated, false otherwise
    public func isAuthenticated() async -> Bool {
        guard await credentialsStorage.load() != nil else {
            return false
        }
        return true
    }

    /// Get current user info from session
    ///
    /// Returns basic user information from stored credentials.
    ///
    /// - Returns: User info if authenticated, nil otherwise
    public func getCurrentUser() async -> (handle: String, did: String)? {
        guard let credentials = await credentialsStorage.load() else {
            return nil
        }
        return (handle: credentials.handle, did: credentials.did)
    }

    // MARK: - Private Methods

    /// Perform proactive token refresh if needed
    /// 
    /// - Parameter credentials: Current credentials to check and potentially refresh
    /// - Returns: Updated credentials (refreshed if needed, original if not needed or failed)
    /// - Throws: AuthenticationError if refresh fails unrecoverably
    private func performProactiveTokenRefresh(credentials: AuthCredentials) async throws -> AuthCredentials {
        guard shouldRefreshTokensProactively(credentials) else {
            return credentials
        }

        logger.log("🔄 Proactively refreshing tokens before request", level: .info, category: .session)

        do {
            let coordinator = IronSessionMobileOAuthCoordinator(
                credentialsStorage: credentialsStorage,
                session: session,
                config: config
            )
            let refreshedCredentials = try await coordinator.refreshIronSession()

            // Update credentials and save to storage
            guard let authCredentials = refreshedCredentials as? AuthCredentials else {
                logger.log("⚠️ Failed to cast refreshed credentials", level: .warning, category: .session)
                return credentials // Continue with existing tokens
            }

            // Save to storage - Swift will automatically hop to MainActor for @MainActor isolated method
            try await credentialsStorage.save(authCredentials)
            logger.log("✅ Proactive token refresh successful", level: .info, category: .session)
            return authCredentials

        } catch {
            // If the session is definitely expired, don't continue with invalid tokens
            if let authError = error as? AuthenticationError, case .sessionExpiredUnrecoverable = authError {
                logger.log("❌ Proactive refresh failed with unrecoverable error, aborting request", level: .error, category: .session)
                throw authError
            }
            
            logger.log("⚠️ Proactive refresh failed, continuing with existing tokens: \(error)", level: .warning, category: .session)
            return credentials // Continue with existing tokens - reactive refresh will handle 401 if needed
        }
    }

    /// Check if tokens should be refreshed proactively
    ///
    /// Determines if tokens are close enough to expiry to warrant a proactive refresh.
    /// Uses a 1-hour buffer to prevent 401 errors from occurring.
    ///
    /// - Parameter credentials: Current credentials to check
    /// - Returns: True if tokens should be refreshed proactively
    private func shouldRefreshTokensProactively(_ credentials: AuthCredentials) -> Bool {
        // Refresh if the session will expire within 1 hour (3600 seconds)
        let oneHourFromNow = Date().addingTimeInterval(60 * 60)
        let shouldRefresh = credentials.expiresAt < oneHourFromNow

        if shouldRefresh {
            logger.log("🔄 Token expires at \(credentials.expiresAt), current time + 1h = \(oneHourFromNow)", level: .debug, category: .session)
        }

        return shouldRefresh
    }
}
