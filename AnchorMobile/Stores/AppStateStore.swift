//
//  AppStateStore.swift
//  AnchorMobile
//
//  Created by Claude on 28/06/2025.
//

import Foundation
import SwiftUI
import UIKit
import AnchorKit

/// Observable store for managing AnchorMobile-specific app state
/// 
/// Handles app lifecycle events, fetch timing, and mobile-specific settings
/// to optimize user experience and prevent unnecessary network requests.
@MainActor
@Observable
public final class AppStateStore {
    
    // MARK: - Properties
    
    /// Whether the app has completed initialization
    private(set) var isInitialized = false
    
    /// Current initialization step (for debugging/monitoring)
    private(set) var initializationStep: String = "Not started"
    
    /// Last time the feed was fetched
    private(set) var lastFeedFetchTime: Date?
    
    /// Last time the app became active
    private(set) var lastAppBecameActiveTime: Date?
    
    /// Whether the app is currently in the foreground
    private(set) var isAppActive = true
    
    /// Minimum time interval before allowing automatic feed refresh (5 minutes)
    private let minimumFetchInterval: TimeInterval = 5 * 60
    
    // MARK: - Initialization
    
    public init() {
        setupAppStateObservation()
    }
    
    // MARK: - App Lifecycle Management
    
    private func setupAppStateObservation() {
        // Observe app lifecycle changes
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleAppBecameActive()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleAppWillResignActive()
            }
        }
    }
    
    private func handleAppBecameActive() {
        isAppActive = true
        lastAppBecameActiveTime = Date()
        print("📱 App became active at \(Date())")
    }
    
    private func handleAppWillResignActive() {
        isAppActive = false
        print("📱 App will resign active at \(Date())")
    }
    
    // MARK: - Feed Fetch Management
    
    /// Check if enough time has passed since the last feed fetch to warrant a new one
    /// - Returns: True if feed should be refreshed, false if too recent
    public func shouldRefreshFeed() -> Bool {
        guard let lastFetch = lastFeedFetchTime else {
            // Never fetched before, should refresh
            return true
        }
        
        let timeSinceLastFetch = Date().timeIntervalSince(lastFetch)
        let shouldRefresh = timeSinceLastFetch >= minimumFetchInterval
        
        print("🕒 Time since last feed fetch: \(Int(timeSinceLastFetch))s, should refresh: \(shouldRefresh)")
        
        return shouldRefresh
    }
    
    /// Check if feed should be refreshed when app becomes active
    /// Only refreshes if it's been more than 5 minutes since last fetch
    /// - Returns: True if feed should be refreshed due to app activation
    public func shouldRefreshFeedOnAppActivation() -> Bool {
        guard isAppActive else { return false }
        
        // Only refresh if enough time has passed
        return shouldRefreshFeed()
    }
    
    /// Mark that a feed fetch has occurred
    public func recordFeedFetch() {
        lastFeedFetchTime = Date()
        print("✅ Recorded feed fetch at \(Date())")
    }
    
    /// Force next feed fetch to occur (useful for manual refresh)
    public func invalidateFeedCache() {
        lastFeedFetchTime = nil
        print("🔄 Feed cache invalidated - next fetch will proceed")
    }
    
    // MARK: - App Initialization
    
    /// Perform sequential app initialization
    /// - Parameters:
    ///   - authStore: Authentication store for loading credentials
    ///   - locationService: Location service for requesting permissions
    public func initializeApp(authStore: AuthStore, locationService: LocationService) async {
        guard !isInitialized else {
            print("📱 App already initialized, skipping")
            return
        }
        
        print("📱 AppStateStore: Starting sequential initialization")
        
        // Step 1: Load stored credentials
        initializationStep = "Loading credentials"
        print("📱 Step 1: Loading stored credentials...")
        let credentials = await authStore.loadStoredCredentials()
        if let creds = credentials {
            print("✅ Successfully loaded credentials for @\(creds.handle)")
        } else {
            print("ℹ️ No stored credentials found - user needs to sign in")
        }
        
        // Step 2: Check location permissions (non-blocking)
        initializationStep = "Checking location permissions"
        print("📱 Step 2: Checking location permissions...")
        
        // Check current permission status without triggering request
        // This avoids blocking the UI during app initialization
        if locationService.hasLocationPermission {
            print("✅ Location permission already granted")
        } else if locationService.shouldRequestPermission {
            print("ℹ️ Location permission not yet requested - will prompt when needed")
        } else {
            print("⚠️ Location permission denied - user can enable in settings later")
        }
        
        // Don't await permission request during initialization - let the user trigger it later
        // This prevents the "UI unresponsiveness" warning and improves app startup time
        
        // Step 3: Mark app as initialized
        initializationStep = "Completed"
        print("📱 Step 3: Initialization complete")
        isInitialized = true
        
        // Step 4: Record app launch
        recordAppLaunch()
    }
    
    // MARK: - App Launch
    
    /// Record that the app has launched
    public func recordAppLaunch() {
        lastAppBecameActiveTime = Date()
        isAppActive = true
        print("📱 App launched at \(Date())")
    }
    
    // MARK: - Convenience Methods
    
    /// Get formatted time since last fetch for debugging
    public var timeSinceLastFetchFormatted: String {
        guard let lastFetch = lastFeedFetchTime else {
            return "Never"
        }
        
        let interval = Date().timeIntervalSince(lastFetch)
        let minutes = Int(interval / 60)
        let seconds = Int(interval.truncatingRemainder(dividingBy: 60))
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s ago"
        } else {
            return "\(seconds)s ago"
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
} 
