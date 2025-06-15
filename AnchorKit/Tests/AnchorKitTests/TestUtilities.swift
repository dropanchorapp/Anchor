import Foundation
import Testing
@testable import AnchorKit

// MARK: - Mock URL Session

final class MockURLSession: URLSessionProtocol, @unchecked Sendable {
    var data: Data?
    var response: URLResponse?
    var error: Error?
    
    // Support for multiple responses in sequence
    var responses: [(Data, URLResponse)] = []
    private var responseIndex = 0

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = error {
            throw error
        }
        
        // If we have multiple responses configured, use them in sequence
        if !responses.isEmpty {
            let currentIndex = responseIndex
            responseIndex += 1
            
            if currentIndex < responses.count {
                return responses[currentIndex]
            } else {
                // Fall back to last response if we've exhausted the list
                return responses.last ?? (Data(), URLResponse())
            }
        }

        return (data ?? Data(), response ?? URLResponse())
    }
    
    // Reset for new test
    func reset() {
        data = nil
        response = nil
        error = nil
        responses = []
        responseIndex = 0
    }
}

// MARK: - Mock Auth Credentials

struct MockAuthCredentials: AuthCredentialsProtocol {
    let handle: String
    let accessToken: String
    let refreshToken: String
    let did: String
    let expiresAt: Date
    let createdAt: Date

    init(handle: String, accessToken: String, refreshToken: String, did: String, expiresAt: Date) {
        self.handle = handle
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.did = did
        self.expiresAt = expiresAt
        self.createdAt = Date()
    }
    
    var isExpired: Bool {
        expiresAt.timeIntervalSinceNow < 300
    }
    
    var isValid: Bool {
        !handle.isEmpty &&
            !accessToken.isEmpty &&
            !did.isEmpty &&
            !isExpired
    }
} 