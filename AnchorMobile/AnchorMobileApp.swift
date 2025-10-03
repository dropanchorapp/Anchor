//
//  AnchorMobileApp.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 27/06/2025.
//

import SwiftUI
import AnchorKit

@main
struct AnchorMobileApp: App {
    // Shared services
    @State private var authStore = AuthStore()
    @State private var checkInStore: CheckInStore
    @State private var feedStore = FeedStore()
    @State private var appStateStore = AppStateStore()
    @State private var locationService = LocationService()

    init() {
        // Initialize services with proper dependencies
        let authStore = AuthStore()
        let checkInStore = CheckInStore(authStore: authStore)

        self._authStore = State(initialValue: authStore)
        self._checkInStore = State(initialValue: checkInStore)
    }

    // MARK: - URL Scheme Handling
    
    private func handleIncomingURL(_ url: URL) {
        print("📱 Received URL: \(url)")
        
        guard url.scheme == "anchor-app" else {
            print("❌ Unknown URL scheme: \(url.scheme ?? "nil")")
            return
        }
        
        switch url.host {
        case "auth-callback":
            handleAuthCallback(url)
        default:
            print("❌ Unknown URL host: \(url.host ?? "nil")")
        }
    }
    
    private func handleAuthCallback(_ url: URL) {
        print("🔐 Handling secure OAuth callback: \(url)")
        
        // Handle secure OAuth callback using PKCE-protected flow
        Task { @MainActor in
            do {
                let success = try await authStore.handleSecureOAuthCallback(url)
                
                if success {
                    print("🎉 Secure OAuth authentication completed successfully")
                } else {
                    print("❌ Secure OAuth authentication returned false")
                }
            } catch {
                print("❌ Secure OAuth authentication failed: \(error.localizedDescription)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if appStateStore.isInitialized {
                    ContentView()
                        .environment(authStore)
                        .environment(checkInStore)
                        .environment(feedStore)
                        .environment(appStateStore)
                        .environment(locationService)
                } else {
                    // Show a simple loading view during initialization
                    VStack {
                        ProgressView()
                        Text(appStateStore.initializationStep)
                            .padding(.top, 8)
                    }
                }
            }
            .onOpenURL { url in
                handleIncomingURL(url)
            }
            .task {
                await appStateStore.initializeApp(
                    authStore: authStore,
                    locationService: locationService
                )
                
                // Validate session on app launch
                await authStore.validateSessionOnAppLaunch()
                
                // Refresh location on app launch
                await locationService.checkAndUpdateLocationForAppUsage()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                Task {
                    // Validate session when app becomes active (returns from background)
                    await authStore.validateSessionOnAppResume()
                    
                    // Refresh location when app becomes active (returns from background)
                    await locationService.checkAndUpdateLocationForAppUsage()
                }
            }
        }
    }
}
