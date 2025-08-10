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
        print("🔐 Handling OAuth callback: \(url)")
        
        // Parse URL parameters
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            print("❌ Failed to parse URL components")
            return
        }
        
        let params = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value ?? "") })
        
        // Validate required parameters
        guard let accessToken = params["access_token"],
              let refreshToken = params["refresh_token"],
              let did = params["did"],
              let handle = params["handle"],
              let sessionId = params["session_id"] else {
            print("❌ Missing required OAuth parameters")
            return
        }
        
        print("✅ OAuth success for handle: \(handle)")
        
        // Process OAuth authentication
        Task { @MainActor in
            do {
                let oauthAuthData = AnchorKit.OAuthAuthenticationData(
                    accessToken: accessToken,
                    refreshToken: refreshToken,
                    did: did,
                    handle: handle,
                    sessionId: sessionId,
                    avatar: params["avatar"],
                    displayName: params["display_name"]
                )
                
                let success = try await authStore.authenticateWithOAuth(oauthAuthData)
                
                if success {
                    print("🎉 OAuth authentication completed for handle: \(handle)")
                }
            } catch {
                print("❌ OAuth authentication failed: \(error.localizedDescription)")
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
            }
        }
    }
}
