import SwiftUI
import SwiftData
import CoreLocation
import AnchorKit

struct ContentView: View {
    @Environment(LocationService.self) private var locationService
    @Environment(BlueskyService.self) private var blueskyService
    @Environment(NearbyPlacesService.self) private var nearbyPlacesService
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: AppTab = .feed
    @State private var selectedPlace: Place?
    @State private var showingCheckIn = false
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        print("🔍 ContentView.body evaluated - this indicates a re-render")
        return VStack(spacing: 0) {
            // Header with settings and quit buttons
            HStack {
                Text("🧭 Anchor")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button("Settings", systemImage: "gear") {
                    openSettingsWindow()
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Button("Quit", systemImage: "xmark.circle.fill") {
                    NSApp.terminate(nil)
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding()

            Divider()

            if showingCheckIn, let place = selectedPlace {
                CheckInView(
                    place: place,
                    onCancel: {
                        showingCheckIn = false
                        selectedPlace = nil
                    },
                    onComplete: {
                        showingCheckIn = false
                        selectedPlace = nil
                    }
                )
            } else {
                // Tab Content
                Group {
                    switch selectedTab {
                    case .feed:
                        FeedTabView()
                    case .nearby:
                        NearbyTabView(
                            onPlaceSelected: { place in
                                selectedPlace = place
                                showingCheckIn = true
                            }
                        )
                    }
                }
                .frame(maxHeight: .infinity)

                Divider()

                // Tab Bar
                HStack(spacing: 0) {
                    ForEach(AppTab.allCases, id: \.self) { tab in
                        Button(action: {
                            selectedTab = tab
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: tab.iconName)
                                    .font(.system(size: 16))
                                Text(tab.title)
                                    .font(.caption2)
                            }
                            .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
    }

    private func openSettingsWindow() {
        openWindow(id: "settings")
    }
}

enum AppTab: String, CaseIterable {
    case feed
    case nearby

    var title: String {
        switch self {
        case .feed: return "Feed"
        case .nearby: return "Nearby"
        }
    }

    var iconName: String {
        switch self {
        case .feed: return "list.bullet"
        case .nearby: return "location"
        }
    }
}

#Preview {
    ContentView()
}
