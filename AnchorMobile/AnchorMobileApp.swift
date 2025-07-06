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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authStore)
                .environment(checkInStore)
                .environment(appStateStore)
                .environment(locationService)
                .task {
                    // Load credentials immediately when ContentView appears (backup)
                    print("📱 AnchorMobileApp: Loading stored credentials in .task")
                    let credentials = await authStore.loadStoredCredentials()
                    if let creds = credentials {
                        print("📱 AnchorMobileApp: Successfully loaded credentials for @\(creds.handle)")
                    } else {
                        print("📱 AnchorMobileApp: No stored credentials found")
                    }
                }
        }
    }
}
