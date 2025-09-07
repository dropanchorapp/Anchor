//
//  PlaceBrowseModeView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 06/07/2025.
//

import SwiftUI
import CoreLocation
import AnchorKit

struct PlaceBrowseModeView: View {
    let onPlaceSelected: (Place) -> Void
    
    @Environment(LocationService.self) private var locationService
    @State private var placesService = AnchorPlacesService()
    @State private var places: [AnchorPlaceWithDistance] = []
    @State private var isLoading = false
    @State private var error: Error?
    @State private var selectedCategory: PlaceCategorization.CategoryGroup?
    @State private var searchText = ""
    
    var filteredPlaces: [AnchorPlaceWithDistance] {
        var filtered = places
        
        // Filter by category
        if let selectedCategory = selectedCategory {
            let categoryTags = CategoryCacheService.shared.getCategoriesForGroup(selectedCategory)
            filtered = filtered.filter { place in
                categoryTags.contains { tag in
                    place.place.tags.contains { (key, value) in
                        "\(key)=\(value)" == tag
                    }
                }
            }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { place in
                place.place.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Category filter removed for simplified UI
            
            // Places list
            if isLoading {
                Spacer()
                ProgressView("Finding nearby places...")
                Spacer()
            } else if let error = error {
                Spacer()
                VStack(spacing: 12) {
                    Text("⚠️ Unable to load places")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Try Again") {
                        Task { await loadNearbyPlaces(forceFreshLocation: true) }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                Spacer()
            } else if filteredPlaces.isEmpty && !places.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Text("🔍 No places match your filters")
                        .font(.headline)
                    Text("Try adjusting your category or search")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                Spacer()
            } else if places.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Text("📍 No places found nearby")
                        .font(.headline)
                    Text("Try pulling to refresh")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                Spacer()
            } else {
                List(filteredPlaces) { placeWithDistance in
                    PlaceRowView(
                        placeWithDistance: placeWithDistance,
                        onTap: { onPlaceSelected(placeWithDistance.place) }
                    )
                }
                .refreshable {
                    await loadNearbyPlaces(forceFreshLocation: true)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Filter places by name...")
        .task {
            await loadNearbyPlaces()
        }
    }
    
    private func loadNearbyPlaces(forceFreshLocation: Bool = false) async {
        isLoading = true
        error = nil
        
        var location: CLLocation?
        
        if forceFreshLocation {
            print("📍 Pull-to-refresh: requesting fresh location...")
            if let freshCoordinates = await locationService.requestCurrentLocation() {
                location = CLLocation(
                    latitude: freshCoordinates.latitude,
                    longitude: freshCoordinates.longitude
                )
            }
        } else {
            location = locationService.currentLocation
        }
        
        guard let location = location else {
            error = LocationError.locationNotAvailable
            isLoading = false
            return
        }
        
        print("📍 Loading nearby places for location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        do {
            places = try await placesService.findNearbyPlacesWithDistance(
                near: location.coordinate,
                radiusMeters: 400
            )
            print("📍 Found \(places.count) nearby places")
        } catch {
            self.error = error
            print("❌ Error loading nearby places: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
}

enum LocationError: LocalizedError {
    case locationNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .locationNotAvailable:
            return "Current location is not available"
        }
    }
}

#Preview {
    PlaceBrowseModeView { place in
        print("Selected place: \(place.name)")
    }
    .environment(LocationService())
}
