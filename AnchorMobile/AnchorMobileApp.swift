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
            .task {
                await appStateStore.initializeApp(
                    authStore: authStore,
                    locationService: locationService
                )
            }
        }
    }
}
