//
//  AnchorCheckinsService.swift
//  AnchorKit
//
//  Created by Claude Code on 13/08/2025.
//

import Foundation

// MARK: - Checkin Service Protocol

/// Service protocol for Anchor checkin operations
@MainActor
public protocol AnchorCheckinsServiceProtocol {
    /// Create a checkin using the backend API with OAuth Bearer token
    func createCheckin(place: Place, message: String?, accessToken: String) async throws -> CheckinResult
}

// MARK: - Anchor Checkins Service

/// Service for creating and managing checkins via the Anchor backend
/// Handles write operations for checkin records with authentication and retry logic
@MainActor
public final class AnchorCheckinsService: AnchorCheckinsServiceProtocol {
    // MARK: - Properties

    private let session: URLSessionProtocol
    private let baseURL: URL
    private let authStore: AuthStoreProtocol?

    // MARK: - Initialization

    public init(
        session: URLSessionProtocol = URLSession.shared,
        baseURL: String = "https://dropanchor.app",
        authStore: AuthStoreProtocol? = nil
    ) {
        self.session = session
        self.baseURL = URL(string: baseURL)!
        self.authStore = authStore
    }

    // MARK: - Checkin Methods

    /// Create a checkin using the backend API with OAuth Bearer token
    /// - Parameters:
    ///   - place: The place/location for the checkin
    ///   - message: Optional text message for the checkin
    ///   - accessToken: OAuth access token for Bearer authentication
    /// - Returns: Result indicating success and optional checkin ID
    public func createCheckin(place: Place, message: String?, accessToken: String) async throws -> CheckinResult {
        return try await makeAuthenticatedRequest(accessToken: accessToken) { accessToken in
            try await createCheckinInternal(place: place, message: message, accessToken: accessToken)
        }
    }

    // MARK: - Private Methods

    /// Make an authenticated request with automatic token refresh retry
    /// - Parameters:
    ///   - accessToken: Current OAuth access token
    ///   - operation: Operation to perform with access token
    /// - Returns: Result of the operation
    private func makeAuthenticatedRequest<T: Sendable>(
        accessToken: String,
        operation: (String) async throws -> T
    ) async throws -> T {
        do {
            // First attempt with current access token
            return try await operation(accessToken)
        } catch AnchorCheckinsError.authenticationRequired {
            print("🔄 CheckinsService: Authentication failed, attempting token refresh...")

            // Try to refresh tokens if AuthStore is available
            guard let authStore = authStore else {
                print("❌ CheckinsService: No AuthStore available for token refresh")
                throw AnchorCheckinsError.authenticationRequired
            }

            // Validate/refresh session (this will refresh OAuth tokens if needed)
            await authStore.validateSessionOnAppResume()

            // Get updated credentials with refreshed access token
            guard let updatedCredentials = try? await authStore.getValidCredentials() as? AuthCredentials else {
                print("❌ CheckinsService: Failed to get updated credentials after refresh")
                throw AnchorCheckinsError.authenticationRequired
            }

            print("🔄 CheckinsService: Retrying request with refreshed access token")

            // Retry with new access token
            do {
                return try await operation(updatedCredentials.accessToken)
            } catch AnchorCheckinsError.authenticationRequired {
                print("❌ CheckinsService: Authentication still failed after refresh")
                throw AnchorCheckinsError.authenticationRequired
            }
        }
    }

    /// Internal implementation of checkin creation using OAuth Bearer token
    /// - Parameters:
    ///   - place: The place for the checkin
    ///   - message: Optional message text
    ///   - accessToken: OAuth access token for Bearer authentication
    /// - Returns: Checkin creation result
    private func createCheckinInternal(place: Place, message: String?, accessToken: String) async throws -> CheckinResult {
        let url = baseURL.appendingPathComponent("/api/checkins")

        print("🏁 CheckinsService: Creating checkin for place: \(place.name)")
        print("🏁 CheckinsService: Location: (\(place.latitude), \(place.longitude))")
        print("🏁 CheckinsService: Using OAuth Bearer token: \(accessToken.prefix(8))...")

        // Create request with OAuth Bearer token (OAuth 2.1 standard)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        // Create request body (no session_id needed with Bearer tokens)
        let requestBody = CheckinRequest(place: place, message: message)
        let jsonData = try JSONEncoder().encode(requestBody)
        request.httpBody = jsonData

        print("🏁 CheckinsService: Request body size: \(jsonData.count) bytes")

        do {
            // Make request
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ CheckinsService: Invalid response type")
                throw AnchorCheckinsError.invalidResponse
            }

            print("🏁 CheckinsService: HTTP Status: \(httpResponse.statusCode)")

            // Check for authentication errors
            if httpResponse.statusCode == 401 {
                print("❌ CheckinsService: Authentication failed (401)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("❌ CheckinsService: Error response: \(responseString)")
                }
                throw AnchorCheckinsError.authenticationRequired
            }

            // Check for other HTTP errors
            guard httpResponse.statusCode == 200 else {
                print("❌ CheckinsService: HTTP Error \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("❌ CheckinsService: Error response: \(responseString)")
                }
                throw AnchorCheckinsError.httpError(httpResponse.statusCode)
            }

            // Parse response
            let checkinResponse = try JSONDecoder().decode(CheckinResponse.self, from: data)

            print("🏁 CheckinsService: Response - Success: \(checkinResponse.success)")
            if let checkinUri = checkinResponse.checkinUri {
                print("🏁 CheckinsService: Checkin URI: \(checkinUri)")
            }

            if checkinResponse.success {
                print("✅ CheckinsService: Checkin creation successful")

                // Extract rkey from checkinUri to create shareable ID
                let checkinId = checkinResponse.checkinUri.flatMap { uri in
                    extractRkey(from: uri)
                }

                return CheckinResult(success: true, checkinId: checkinId)
            } else {
                let errorMessage = checkinResponse.error ?? "Unknown error"
                print("❌ CheckinsService: Server error: \(errorMessage)")
                throw AnchorCheckinsError.serverError(errorMessage)
            }
        } catch {
            if error is AnchorCheckinsError {
                throw error
            } else {
                print("❌ CheckinsService: Network error: \(error)")
                throw AnchorCheckinsError.networkError(error)
            }
        }
    }

    /// Extract rkey from AT Protocol URI (at://did:plc:abc/collection/rkey)
    /// - Parameter uri: AT Protocol URI string
    /// - Returns: Extracted rkey or nil if extraction fails
    private func extractRkey(from uri: String) -> String? {
        let components = uri.split(separator: "/")
        return components.last.map(String.init)
    }
}

// MARK: - Request/Response Models

/// Request model for creating a checkin via the backend API
private struct CheckinRequest: Codable {
    let place: BackendPlace
    let message: String?

    struct BackendPlace: Codable {
        let name: String
        let latitude: Double
        let longitude: Double
        let tags: [String: String]
    }

    init(place: Place, message: String?) {
        self.place = BackendPlace(
            name: place.name,
            latitude: place.latitude,
            longitude: place.longitude,
            tags: place.tags
        )
        self.message = message
    }
}

/// Response model from the backend API for checkin operations
private struct CheckinResponse: Codable {
    let success: Bool
    let checkinUri: String?
    let addressUri: String?
    let error: String?
}

/// Result of creating a checkin
public struct CheckinResult: Sendable {
    public let success: Bool
    public let checkinId: String?

    public init(success: Bool, checkinId: String? = nil) {
        self.success = success
        self.checkinId = checkinId
    }
}

// MARK: - Checkins Error Types

/// Errors that can occur when creating checkins
public enum AnchorCheckinsError: LocalizedError {
    case invalidResponse
    case authenticationRequired
    case httpError(Int)
    case serverError(String)
    case networkError(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from checkins API"
        case .authenticationRequired:
            return "Authentication required for checkin operations"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
