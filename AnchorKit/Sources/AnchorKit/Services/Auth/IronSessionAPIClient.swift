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
        
        // Load current credentials to get sealed session ID
        guard let credentials = await credentialsStorage.load(),
              let sealedSessionId = credentials.sessionId else {
            print("❌ IronSessionAPIClient: No credentials or session ID found")
            throw IronSessionAPIError.notAuthenticated
        }
        
        // Build request URL
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Add sealed session token as Bearer authorization header
        request.setValue("Bearer \(sealedSessionId)", forHTTPHeaderField: "Authorization")
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
                print("🔐 IronSessionAPIClient: Session expired, attempting refresh")
                
                // Try to refresh session
                let coordinator = IronSessionMobileOAuthCoordinator(credentialsStorage: credentialsStorage, session: session)
                let refreshedCredentials = try await coordinator.refreshIronSession()
                
                // Save refreshed credentials
                try await credentialsStorage.save(refreshedCredentials)
                print("✅ IronSessionAPIClient: Session refreshed, retrying request")
                
                // Retry with refreshed session
                return try await authenticatedRequest(path: path, method: method, body: body)
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
}

// MARK: - Iron Session API Errors

/// Errors that can occur during Iron Session API calls
public enum IronSessionAPIError: Error, LocalizedError {
    case notAuthenticated
    case networkError
    case apiError(Int)
    
    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated - no session ID found"
        case .networkError:
            return "Network error during API call"
        case .apiError(let statusCode):
            return "API error: HTTP \(statusCode)"
        }
    }
}