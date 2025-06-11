import SwiftUI
import AnchorKit

struct NearbyTabView: View {
    @Environment(LocationService.self) private var locationService
    @Environment(NearbyPlacesService.self) private var nearbyPlacesService
    let onPlaceSelected: (Place) -> Void

    @State private var searchText = ""

    var filteredPlaces: [Place] {
        nearbyPlacesService.filteredPlaces(searchText: searchText)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search places...", text: $searchText)
                        .textFieldStyle(.plain)

                    Button(action: {
                        Task {
                            await nearbyPlacesService.refreshLocationAndSearch()
                        }
                    }) {
                        Image(systemName: "location.fill")
                            .foregroundStyle((locationService.locationAge ?? 1000) < 600 ? .green : .blue)
                    }
                    .buttonStyle(.plain)
                    .disabled(nearbyPlacesService.isLoading || !locationService.hasLocationPermission)
                    .help("Refresh location \(locationService.locationFreshnessDescription)")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))

                if !locationService.hasLocationPermission {
                    LocationPermissionView()
                }
            }
            .padding()

            Divider()

            // Places list
            if nearbyPlacesService.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Finding nearby places...")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = nearbyPlacesService.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                        .font(.title2)
                    Text(error)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                    Button("Try Again") {
                        Task {
                            await nearbyPlacesService.searchNearbyPlaces()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else if filteredPlaces.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: searchText.isEmpty ? "location.magnifyingglass" : "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .font(.title2)
                    Text(searchText.isEmpty ? "No places found nearby" : "No places match your search")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(filteredPlaces) { place in
                            PlaceRowView(place: place) {
                                onPlaceSelected(place)
                            }
                        }
                    }
                }
            }
        }
        .task {
            if locationService.hasLocationPermission && nearbyPlacesService.places.isEmpty {
                await nearbyPlacesService.searchNearbyPlaces()
            }
        }
        .onChange(of: locationService.hasLocationPermission) { _, hasPermission in
            if hasPermission && nearbyPlacesService.places.isEmpty {
                Task {
                    await nearbyPlacesService.searchNearbyPlaces()
                }
            }
        }
    }
}

#Preview {
    let locationService = LocationService()
    return NearbyTabView { _ in }
        .environment(locationService)
        .environment(NearbyPlacesService(locationService: locationService))
}
