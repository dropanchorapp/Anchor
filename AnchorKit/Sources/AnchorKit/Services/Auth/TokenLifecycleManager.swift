//
//  TokenLifecycleManager.swift
//  AnchorKit
//
//  Created by Tijs Teulings on 16/08/2025.
//

import Foundation

/// Service responsible for token lifecycle management and proactive refresh logic
public final class TokenLifecycleManager {
    // MARK: - Token Lifecycle Methods
    
    /// Check if tokens should be refreshed (proactive refresh logic)
    public func shouldRefreshTokens(_ credentials: AuthCredentials) -> Bool {
        // Refresh if tokens are expired or will expire within 10 minutes
        let tenMinutesFromNow = Date().addingTimeInterval(600)
        let shouldRefresh = credentials.expiresAt < tenMinutesFromNow
        
        if shouldRefresh {
            print("🔄 TokenLifecycleManager: Tokens should be refreshed (expire at \(credentials.expiresAt))")
        }
        
        return shouldRefresh
    }
}
