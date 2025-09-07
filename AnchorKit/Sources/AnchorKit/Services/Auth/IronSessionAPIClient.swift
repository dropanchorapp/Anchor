//
//  IronSessionAPIClient.swift  
//  AnchorKit
//
//  API client that uses Iron Session sealed session IDs for authentication
//

import Foundation

/// API client for Iron Session authentication
///
/// Makes authenticated API calls using sealed session IDs stored in credentials.
/// Similar to BookHive's mobile client approach where session IDs are sent as cookies.
@MainActor
public final class IronSessionAPIClient: @unchecked Sendable {
    
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
    
    // MARK: - Authenticated API Calls
    
    /// Make authenticated API request using sealed session token
    ///
    /// Automatically includes sealed session token as Bearer authorization header for backend authentication.
    /// The backend will validate and use the Iron Session for API calls.
    /// 
    /// **Proactive Token Refresh**: Automatically refreshes tokens before they expire to prevent 401 errors.
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
        
        // Load current credentials to get sealed session ID
        guard var credentials = await credentialsStorage.load(),
              let sealedSessionId = credentials.sessionId else {
            print("❌ IronSessionAPIClient: No credentials or session ID found")
            throw IronSessionAPIError.notAuthenticated
        }
        
        // **PROACTIVE TOKEN REFRESH**: Check if tokens need refresh before making request
        credentials = await performProactiveTokenRefresh(credentials: credentials)
        
        // Build request URL
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Add sealed session token as Bearer authorization header (use updated credentials)
        let currentSessionId = credentials.sessionId ?? sealedSessionId
        request.setValue("Bearer \(currentSessionId)", forHTTPHeaderField: "Authorization")
        request.setValue("AnchorApp/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add body if provided
        if let body = body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        print("🌐 IronSessionAPIClient: Making authenticated request to \(path)")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ IronSessionAPIClient: Invalid response type")
                throw IronSessionAPIError.networkError
            }
            
            print("🌐 IronSessionAPIClient: Response status: \(httpResponse.statusCode)")
            
            // Handle authentication failure
            if httpResponse.statusCode == 401 {
                // Check retry limit to prevent infinite loops
                let maxRetries = 3
                if retryCount >= maxRetries {
                    debugPrint("❌ IronSessionAPIClient: Maximum retry attempts (\(maxRetries)) exceeded for \(path)")
                    throw IronSessionAPIError.authenticationFailed
                }
                
                debugPrint("🔐 IronSessionAPIClient: Session expired, attempting refresh (attempt \(retryCount + 1)/\(maxRetries))")
                
                // Exponential backoff: wait before retry
                let backoffDelay = min(pow(2.0, Double(retryCount)), 8.0) // Cap at 8 seconds
                try await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
                
                // Try to refresh session
                let coordinator = IronSessionMobileOAuthCoordinator(
                    credentialsStorage: credentialsStorage,
                    session: session
                )
                
                do {
                    let refreshedCredentials = try await coordinator.refreshIronSession()
                    
                    // Save refreshed credentials
                    try await credentialsStorage.save(refreshedCredentials)
                    debugPrint("✅ IronSessionAPIClient: Session refreshed, retrying request")
                    
                    // Retry with refreshed session and incremented counter
                    return try await authenticatedRequest(path: path, method: method, body: body, retryCount: retryCount + 1)
                    
                } catch {
                    debugPrint("❌ IronSessionAPIClient: Token refresh failed: \(error)")
                    
                    // If this was our last retry, throw authentication failed
                    if retryCount >= maxRetries - 1 {
                        throw IronSessionAPIError.authenticationFailed
                    }
                    
                    // Otherwise, try again with incremented counter
                    return try await authenticatedRequest(path: path, method: method, body: body, retryCount: retryCount + 1)
                }
            }
            
            // Handle other errors
            guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
                print("❌ IronSessionAPIClient: API error: \(httpResponse.statusCode)")
                throw IronSessionAPIError.apiError(httpResponse.statusCode)
            }
            
            print("✅ IronSessionAPIClient: Request completed successfully")
            return data
            
        } catch {
            if error is IronSessionAPIError {
                throw error
            } else {
                print("❌ IronSessionAPIClient: Network error: \(error)")
                throw IronSessionAPIError.networkError
            }
        }
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
    /// Validates that we have credentials with a sealed session ID.
    ///
    /// - Returns: True if authenticated, false otherwise
    public func isAuthenticated() async -> Bool {
        guard let credentials = await credentialsStorage.load(),
              credentials.sessionId != nil else {
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
        guard let credentials = await credentialsStorage.load(),
              credentials.sessionId != nil else {
            return nil
        }
        return (handle: credentials.handle, did: credentials.did)
    }
    
    // MARK: - Private Methods
    
    /// Perform proactive token refresh if needed
    /// 
    /// - Parameter credentials: Current credentials to check and potentially refresh
    /// - Returns: Updated credentials (refreshed if needed, original if not needed or failed)
    private func performProactiveTokenRefresh(credentials: AuthCredentials) async -> AuthCredentials {
        guard shouldRefreshTokensProactively(credentials) else {
            return credentials
        }
        
        print("🔄 IronSessionAPIClient: Proactively refreshing tokens before request")
        
        do {
            let coordinator = IronSessionMobileOAuthCoordinator(
                credentialsStorage: credentialsStorage,
                session: session
            )
            let refreshedCredentials = try await coordinator.refreshIronSession()
            
            // Update credentials and save to storage
            guard let authCredentials = refreshedCredentials as? AuthCredentials else {
                print("⚠️ IronSessionAPIClient: Failed to cast refreshed credentials")
                return credentials // Continue with existing tokens
            }
            
            try await credentialsStorage.save(authCredentials)
            print("✅ IronSessionAPIClient: Proactive token refresh successful")
            return authCredentials
            
        } catch {
            print("⚠️ IronSessionAPIClient: Proactive refresh failed, continuing with existing tokens: \(error)")
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
            print("🔄 IronSessionAPIClient: Token expires at \(credentials.expiresAt), " +
                  "current time + 1h = \(oneHourFromNow)")
        }
        
        return shouldRefresh
    }
}

// MARK: - Iron Session API Errors

/// Errors that can occur during Iron Session API calls
public enum IronSessionAPIError: Error, LocalizedError {
    case notAuthenticated
    case networkError
    case apiError(Int)
    case authenticationFailed
    
    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated - no session ID found"
        case .networkError:
            return "Network error during API call"
        case .apiError(let statusCode):
            return "API error: HTTP \(statusCode)"
        case .authenticationFailed:
            return "Authentication failed after maximum retry attempts"
        }
    }
}
