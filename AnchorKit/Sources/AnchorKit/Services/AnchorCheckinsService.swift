//
//  AnchorCheckinsService.swift
//  AnchorKit
//
//  Created by Tijs Teulings on 13/08/2025.
//

import Foundation

// MARK: - Checkin Service Protocol

/// Service protocol for Anchor checkin operations
@MainActor
public protocol AnchorCheckinsServiceProtocol {
    /// Create a checkin using the backend API with Iron Session authentication
    func createCheckin(place: Place, message: String?) async throws -> CheckinResult
}

// MARK: - Anchor Checkins Service

/// Service for creating and managing checkins via the Anchor backend
/// Uses Iron Session authentication for secure API access with automatic token management
@MainActor
public final class AnchorCheckinsService: AnchorCheckinsServiceProtocol {
    // MARK: - Properties

    private let apiClient: IronSessionAPIClient

    // MARK: - Initialization

    public init(
        credentialsStorage: CredentialsStorageProtocol = KeychainCredentialsStorage(),
        session: URLSessionProtocol = URLSession.shared,
        baseURL: String = "https://dropanchor.app"
    ) {
        self.apiClient = IronSessionAPIClient(
            credentialsStorage: credentialsStorage,
            session: session,
            baseURL: baseURL
        )
    }
    
    /// Convenience initializer for testing with custom API client
    public init(apiClient: IronSessionAPIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Checkin Methods

    /// Create a checkin using the backend API with Iron Session authentication
    /// 
    /// Automatically handles authentication using stored Iron Session credentials.
    /// Includes proactive token refresh and reactive 401 handling.
    ///
    /// - Parameters:
    ///   - place: The place/location for the checkin
    ///   - message: Optional text message for the checkin
    /// - Returns: Result indicating success and optional checkin ID
    /// - Throws: AnchorCheckinsError for various failure scenarios
    public func createCheckin(place: Place, message: String?) async throws -> CheckinResult {
        print("🏁 CheckinsService: Creating checkin for place: \(place.name)")
        print("🏁 CheckinsService: Location: (\(place.latitude), \(place.longitude))")
        
        do {
            // Create request body
            let requestBody = CheckinRequest(place: place, message: message)
            
            // Use Iron Session API client for authenticated request
            // This handles proactive token refresh, reactive 401 handling, and retries automatically
            let responseData: CheckinResponse = try await apiClient.authenticatedJSONRequest(
                path: "/api/checkins",
                method: "POST",
                requestBody: requestBody
            )
            
            print("🏁 CheckinsService: Response - Success: \(responseData.success)")
            if let checkinUri = responseData.checkinUri {
                print("🏁 CheckinsService: Checkin URI: \(checkinUri)")
            }

            if responseData.success {
                print("✅ CheckinsService: Checkin creation successful")

                // Extract rkey from checkinUri to create shareable ID
                let checkinId = responseData.checkinUri.flatMap { uri in
                    extractRkey(from: uri)
                }

                return CheckinResult(success: true, checkinId: checkinId)
            } else {
                let errorMessage = responseData.error ?? "Unknown error"
                print("❌ CheckinsService: Server error: \(errorMessage)")
                throw AnchorCheckinsError.serverError(errorMessage)
            }
            
        } catch {
            print("❌ CheckinsService: Checkin creation failed: \(error)")
            
            // Map Iron Session errors to Checkin errors
            if let apiError = error as? IronSessionAPIError {
                switch apiError {
                case .notAuthenticated:
                    throw AnchorCheckinsError.authenticationRequired
                case .authenticationFailed:
                    throw AnchorCheckinsError.authenticationRequired
                case .networkError:
                    throw AnchorCheckinsError.networkError(error)
                case .apiError(let statusCode):
                    throw AnchorCheckinsError.httpError(statusCode)
                }
            } else {
                throw AnchorCheckinsError.networkError(error)
            }
        }
    }

    // MARK: - Private Methods

    /// Extract rkey from AT Protocol URI (at://did:plc:abc/collection/rkey)
    /// - Parameter uri: AT Protocol URI string
    /// - Returns: Extracted rkey or nil if extraction fails
    private func extractRkey(from uri: String) -> String? {
        let components = uri.split(separator: "/")
        return components.last.map(String.init)
    }
}

// MARK: - Request/Response Models

/// Request model for creating a checkin via the Iron Session backend API
private struct CheckinRequest: Codable {
    let place: BackendPlace
    let message: String?

    struct BackendPlace: Codable {
        let name: String
        let latitude: Double
        let longitude: Double
        let tags: [String: String]
        
        // Additional fields that the backend expects from the reactivated endpoint
        var category: String?
        var categoryGroup: String?
        var icon: String?
    }

    init(place: Place, message: String?) {
        self.place = BackendPlace(
            name: place.name,
            latitude: place.latitude,
            longitude: place.longitude,
            tags: place.tags,
            category: place.category,
            categoryGroup: place.categoryGroup?.rawValue,
            icon: place.icon
        )
        self.message = message
    }
}

/// Response model from the Iron Session backend API for checkin operations
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
