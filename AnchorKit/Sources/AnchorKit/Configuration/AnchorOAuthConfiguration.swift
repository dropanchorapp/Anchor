//
//  AnchorOAuthConfiguration.swift
//  AnchorKit
//
//  Anchor-specific OAuth configuration
//

import Foundation
import ATProtoFoundation

extension OAuthConfiguration {
    /// Anchor app OAuth configuration for production use
    public static let anchor = OAuthConfiguration(
        baseURL: URL(string: "https://dropanchor.app")!,
        userAgent: "AnchorApp/1.0 (iOS)",
        sessionCookieName: "sid",
        cookieDomain: "dropanchor.app",
        callbackURLScheme: "anchor-app",
        sessionDuration: 86400 * 7,
        refreshThreshold: 3600,
        maxRetryAttempts: 3,
        maxRetryDelay: 8.0
    )
}
