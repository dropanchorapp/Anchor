import SwiftUI
import SwiftData
import AnchorKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Disable automatic window tabbing to prevent tab-related UI elements
        NSWindow.allowsAutomaticWindowTabbing = false
    }
}

@main
struct AnchorMenubarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // Shared service instances - created once at app level
    @State private var locationService: LocationService
    @State private var blueskyService: BlueskyService
    @State private var nearbyPlacesService: NearbyPlacesService

    // Shared model container
    let container: ModelContainer

    init() {
        // Create shared model container first
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

        // Initialize services that depend on other services
        let locationService = LocationService()
        let blueskyService = BlueskyService(context: container.mainContext)
        let nearbyPlacesService = NearbyPlacesService(locationService: locationService)

        self._locationService = State(initialValue: locationService)
        self._blueskyService = State(initialValue: blueskyService)
        self._nearbyPlacesService = State(initialValue: nearbyPlacesService)
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .frame(width: 320, height: 400)
                .environment(locationService)
                .environment(blueskyService)
                .environment(nearbyPlacesService)
                .task {
                    // Load credentials immediately when ContentView appears
                    _ = await blueskyService.loadStoredCredentials()

                    // Handle location services - only update location if we already have permission
                    // Don't request permission on every app start
                    if locationService.hasLocationPermission {
                        await locationService.checkAndUpdateLocationForAppUsage()
                    }
                }
        } label: {
            Label {
                Text("Anchor")
            } icon: {
                ZStack {
                    // Main anchor icon
                    Image(systemName: "sailboat.fill")
                        .foregroundStyle(.primary)

                    // Status indicator overlay
                    Image(systemName: statusIndicatorIcon)
                        .foregroundStyle(statusIndicatorColor)
                        .font(.system(size: 8))
                        .offset(x: 8, y: -6)
                }
            }
        }
        .menuBarExtraStyle(.window)
        .modelContainer(container)

        Window("Settings", id: "settings") {
            SettingsWindow()
                .environment(blueskyService)
                .environment(locationService)
                .environment(nearbyPlacesService)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .modelContainer(container)
    }

    // MARK: - Menu Bar Icon

    /// Status indicator icon for authentication state
    private var statusIndicatorIcon: String {
        if blueskyService.isAuthenticated {
            return "checkmark.circle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }

    /// Status indicator color for authentication state
    private var statusIndicatorColor: Color {
        if blueskyService.isAuthenticated {
            return .green
        } else {
            return .red
        }
    }
}
