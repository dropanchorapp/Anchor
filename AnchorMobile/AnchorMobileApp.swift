//
//  AnchorMobileApp.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 27/06/2025.
//

import SwiftUI
import SwiftData
import AnchorKit

@main
struct AnchorMobileApp: App {
    // Shared services
    @State private var authStore = AuthStore()
    @State private var checkInStore: CheckInStore

    // Shared model container
    let container: ModelContainer

    init() {
        // Create shared model container with same configuration as menu bar app
        do {
            let schema = Schema([
                AuthCredentials.self
            ])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1",
                cloudKitDatabase: .none
            )
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Failed to initialize model container: \(error)")
        }

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
                .task {
                    // Load credentials immediately when ContentView appears
                    _ = await authStore.loadStoredCredentials()
                }
        }
        .modelContainer(container)
    }
}
