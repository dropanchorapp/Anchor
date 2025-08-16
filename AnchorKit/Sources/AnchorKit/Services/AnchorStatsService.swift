//
//  AnchorStatsService.swift
//  AnchorKit
//
//  Created by Tijs Teulings on 13/08/2025.
//

import Foundation

// MARK: - Stats Service Protocol

/// Service protocol for Anchor statistics operations
@MainActor
public protocol AnchorStatsServiceProtocol {
    /// Get AppView health metrics and processing statistics
    func getStats() async throws -> AnchorStatsResponse
}

// MARK: - Anchor Stats Service

/// Service for retrieving system statistics and health metrics from the Anchor backend
/// Provides read-only access to AppView processing statistics and system health data
@MainActor
public final class AnchorStatsService: AnchorStatsServiceProtocol {
    // MARK: - Properties

    private let session: URLSessionProtocol
    private let baseURL: URL

    // MARK: - Initialization

    public init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
        self.baseURL = URL(string: "https://dropanchor.app/api")!
    }

    // MARK: - Stats Methods

    /// Get AppView health metrics and processing statistics
    /// - Returns: Statistics about the AppView system including user counts, checkin counts, and system health
    public func getStats() async throws -> AnchorStatsResponse {
        let url = baseURL.appendingPathComponent("/stats")

        print("📊 StatsService: Fetching system statistics from: \(url)")

        let request = URLRequest(url: url)
        return try await performRequest(request, responseType: AnchorStatsResponse.self)
    }

    // MARK: - Private Methods

    /// Perform HTTP request and decode response
    /// - Parameters:
    ///   - request: URLRequest to perform
    ///   - responseType: Type to decode response into
    /// - Returns: Decoded response object
    private func performRequest<T: Codable>(_ request: URLRequest, responseType: T.Type) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AnchorStatsError.invalidResponse
            }

            print("📊 StatsService: Response status: \(httpResponse.statusCode)")

            // Check for HTTP errors
            guard 200...299 ~= httpResponse.statusCode else {
                // Try to decode error response
                if let errorResponse = try? JSONDecoder().decode(AnchorStatsErrorResponse.self, from: data) {
                    throw AnchorStatsError.apiError(httpResponse.statusCode, errorResponse.error)
                } else {
                    throw AnchorStatsError.httpError(httpResponse.statusCode)
                }
            }

            // Decode successful response
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let result = try decoder.decode(responseType, from: data)

            print("✅ StatsService: Successfully fetched statistics")

            return result

        } catch let error as AnchorStatsError {
            throw error
        } catch {
            print("❌ StatsService: Network error: \(error)")
            throw AnchorStatsError.networkError(error)
        }
    }
}

// MARK: - Response Models

/// Statistics response from the Anchor AppView API
public struct AnchorStatsResponse: Codable, Sendable {
    public let totalCheckins: Int
    public let totalUsers: Int
    public let uniqueUsers: Int?
    public let uniquePlaces: Int?
    public let recentActivity: Int?
    public let lastProcessingRun: String?
    public let lastUpdate: String?
    public let timestamp: String

    public init(
        totalCheckins: Int,
        totalUsers: Int,
        uniqueUsers: Int? = nil,
        uniquePlaces: Int? = nil,
        recentActivity: Int? = nil,
        lastProcessingRun: String? = nil,
        lastUpdate: String? = nil,
        timestamp: String
    ) {
        self.totalCheckins = totalCheckins
        self.totalUsers = totalUsers
        self.uniqueUsers = uniqueUsers
        self.uniquePlaces = uniquePlaces
        self.recentActivity = recentActivity
        self.lastProcessingRun = lastProcessingRun
        self.lastUpdate = lastUpdate
        self.timestamp = timestamp
    }
}

/// Error response from the Stats API
public struct AnchorStatsErrorResponse: Codable, Sendable {
    public let error: String

    public init(error: String) {
        self.error = error
    }
}

// MARK: - Stats Error Types

/// Errors that can occur when retrieving statistics
public enum AnchorStatsError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case apiError(Int, String)
    case networkError(Error)
    case decodingError(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from stats API"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .apiError(let statusCode, let message):
            return "API error (\(statusCode)): \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}
