//
//  AnchorFeedService.swift
//  AnchorKit
//
//  Created by Tijs Teulings on 13/08/2025.
//

import Foundation

// MARK: - Feed Service Protocol

/// Service protocol for Anchor feed operations
/// **PDS-Only Architecture**: Focuses on personal location logging, not social feeds
/// Authentication via HttpOnly cookies (BFF pattern)
@MainActor
public protocol AnchorFeedServiceProtocol {
    func getUserCheckins(did: String, limit: Int, cursor: String?) async throws -> AnchorFeedResponse
    func deleteCheckin(did: String, rkey: String) async throws
}

// MARK: - Anchor Feed Service

/// Service for reading feed data from the Anchor backend
/// **PDS-Only Architecture**: Provides read-only access to user's personal timeline
@MainActor
public final class AnchorFeedService: AnchorFeedServiceProtocol {
    // MARK: - Properties

    private let session: URLSessionProtocol
    private let baseURL: URL

    // MARK: - Initialization

    public init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
        self.baseURL = URL(string: "https://dropanchor.app/api")!

        // Configure URLSession for cookie-based authentication (BFF pattern)
        configureSessionForCookies(session)
    }

    /// Configure URLSession to use shared cookie storage for authentication
    private func configureSessionForCookies(_ session: URLSessionProtocol) {
        // Only configure real URLSession instances, not test mocks
        guard let urlSession = session as? URLSession else { return }

        // Ensure we're using shared cookie storage for authentication
        urlSession.configuration.httpCookieAcceptPolicy = .always
        urlSession.configuration.httpShouldSetCookies = true
        urlSession.configuration.httpCookieStorage = HTTPCookieStorage.shared
    }

    // MARK: - Feed Methods

    /// Get check-ins for a specific user with pagination support
    /// Uses new REST-style endpoint: GET /api/checkins/:did
    /// - Parameters:
    ///   - did: User's DID identifier
    ///   - limit: Number of check-ins to return (default: 50)
    ///   - cursor: ISO timestamp for pagination
    /// - Returns: User feed response with check-ins and cursor
    public func getUserCheckins(
        did: String,
        limit: Int = 50,
        cursor: String? = nil
    ) async throws -> AnchorFeedResponse {
        // Use new REST-style endpoint: /api/checkins/:did
        var components = URLComponents(
            url: baseURL.appendingPathComponent("/checkins/\(did)"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit))
        ]
        if let cursor = cursor {
            components.queryItems?.append(URLQueryItem(name: "cursor", value: cursor))
        }

        let request = URLRequest(url: components.url!)
        return try await performRequest(request, responseType: AnchorFeedResponse.self)
    }

    /// Delete a check-in (only the author can delete their own check-ins)
    /// Uses REST endpoint: DELETE /api/checkins/:did/:rkey
    /// Authentication via HttpOnly cookie (BFF pattern).
    /// - Parameters:
    ///   - did: User's DID identifier
    ///   - rkey: Record key of the check-in to delete
    /// - Throws: AnchorFeedError if deletion fails
    public func deleteCheckin(did: String, rkey: String) async throws {
        let url = baseURL.appendingPathComponent("/checkins/\(did)/\(rkey)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        // Cookie authentication - sid cookie automatically included from HTTPCookieStorage.shared

        _ = try await performRequest(request, responseType: AnchorFeedDeleteResponse.self)
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
                throw AnchorFeedError.invalidResponse
            }

            // Check for HTTP errors
            guard 200...299 ~= httpResponse.statusCode else {
                // Try to decode error response
                if let errorResponse = try? JSONDecoder().decode(AnchorFeedErrorResponse.self, from: data) {
                    throw AnchorFeedError.apiError(httpResponse.statusCode, errorResponse.error)
                } else {
                    throw AnchorFeedError.httpError(httpResponse.statusCode)
                }
            }

            // Decode successful response
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(responseType, from: data)

        } catch let error as AnchorFeedError {
            throw error
        } catch {
            throw AnchorFeedError.networkError(error)
        }
    }
}
