//
//  AnchorAuthError.swift
//  AnchorKit
//
//  Created by Tijs Teulings on 16/08/2025.
//

import Foundation

// MARK: - Auth Error Types

public enum AnchorAuthError: LocalizedError {
    case invalidAuthData
    case invalidPDSURL(String)
    case storageError(Error)
    case networkError(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidAuthData:
            return "Invalid OAuth authentication data"
        case .invalidPDSURL(let url):
            return "Invalid PDS URL: \(url). This indicates an issue with OAuth flow."
        case .storageError(let error):
            return "Failed to store credentials: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
