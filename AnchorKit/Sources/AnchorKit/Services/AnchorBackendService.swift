//
//  AnchorBackendService.swift
//  AnchorKit
//
//  Created by Claude on 10/08/2025.
//

import Foundation

// MARK: - Backend Service Protocol

/// Result of creating a checkin
public struct CheckinResult: Sendable {
    public let success: Bool
    public let checkinId: String?
    
    public init(success: Bool, checkinId: String? = nil) {
        self.success = success
        self.checkinId = checkinId
    }
}

/// Service protocol for communicating with the Anchor backend API
@MainActor
public protocol AnchorBackendServiceProtocol {
    /// Create a checkin using the backend API
    func createCheckin(place: Place, message: String?, sessionId: String) async throws -> CheckinResult
}

// MARK: - Backend API Models

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

/// Response model from the backend API
private struct CheckinResponse: Codable {
    let success: Bool
    let checkinUri: String?
    let addressUri: String?
    let error: String?
}

// MARK: - Anchor Backend Service

/// Service for communicating with the Anchor backend API
public final class AnchorBackendService: AnchorBackendServiceProtocol {
    private let session: URLSessionProtocol
    private let baseURL: URL
    
    public init(session: URLSessionProtocol = URLSession.shared, baseURL: String = "https://dropanchor.app") {
        self.session = session
        self.baseURL = URL(string: baseURL)!
    }
    
    public func createCheckin(place: Place, message: String?, sessionId: String) async throws -> CheckinResult {
        let url = baseURL.appendingPathComponent("/api/checkins")
        
        print("🌐 BackendService: Making POST request to: \(url)")
        print("🌐 BackendService: Session ID: \(sessionId.prefix(8))...")
        print("🌐 BackendService: Place: \(place.name) at (\(place.latitude), \(place.longitude))")
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("anchor_session=\(sessionId)", forHTTPHeaderField: "Cookie")
        
        // Create request body
        let requestBody = CheckinRequest(place: place, message: message)
        let jsonData = try JSONEncoder().encode(requestBody)
        request.httpBody = jsonData
        
        print("🌐 BackendService: Request body size: \(jsonData.count) bytes")
        
        do {
            // Make request
            print("🌐 BackendService: Sending request...")
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ BackendService: Invalid response type")
                throw AnchorBackendError.invalidResponse
            }
            
            print("🌐 BackendService: HTTP Status: \(httpResponse.statusCode)")
            print("🌐 BackendService: Response size: \(data.count) bytes")
            
            // Check for authentication errors
            if httpResponse.statusCode == 401 {
                print("❌ BackendService: Authentication failed (401)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("❌ BackendService: Error response: \(responseString)")
                }
                throw AnchorBackendError.authenticationRequired
            }
            
            // Check for other HTTP errors
            guard httpResponse.statusCode == 200 else {
                print("❌ BackendService: HTTP Error \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("❌ BackendService: Error response: \(responseString)")
                }
                throw AnchorBackendError.httpError(httpResponse.statusCode)
            }
            
            // Parse response
            let checkinResponse = try JSONDecoder().decode(CheckinResponse.self, from: data)
            
            print("🌐 BackendService: Parsed response - Success: \(checkinResponse.success)")
            if let checkinUri = checkinResponse.checkinUri {
                print("🌐 BackendService: Checkin URI: \(checkinUri)")
            }
            if let addressUri = checkinResponse.addressUri {
                print("🌐 BackendService: Address URI: \(addressUri)")
            }
            
            if checkinResponse.success {
                print("✅ BackendService: Checkin creation successful")
                
                // Extract rkey from checkinUri to create shareable ID
                let checkinId = checkinResponse.checkinUri.flatMap { uri in
                    extractRkey(from: uri)
                }
                
                return CheckinResult(success: true, checkinId: checkinId)
            } else {
                let errorMessage = checkinResponse.error ?? "Unknown error"
                print("❌ BackendService: Server error: \(errorMessage)")
                throw AnchorBackendError.serverError(errorMessage)
            }
        } catch {
            if error is AnchorBackendError {
                throw error
            } else {
                print("❌ BackendService: Network error: \(error)")
                throw AnchorBackendError.networkError(error)
            }
        }
    }
}

// MARK: - Helper Functions

/// Extract rkey from AT Protocol URI (at://did:plc:abc/collection/rkey)
private func extractRkey(from uri: String) -> String? {
    let components = uri.split(separator: "/")
    return components.last.map(String.init)
}

// MARK: - Backend Errors

/// Errors that can occur when communicating with the backend
public enum AnchorBackendError: Error, LocalizedError {
    case invalidResponse
    case authenticationRequired
    case httpError(Int)
    case serverError(String)
    case networkError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .authenticationRequired:
            return "Authentication required"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
