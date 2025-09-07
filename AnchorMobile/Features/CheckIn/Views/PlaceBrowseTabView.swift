//
//  PlaceBrowseTabView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 06/07/2025.
//

import SwiftUI
import CoreLocation
import AnchorKit

struct PlaceBrowseTabView: View {
    let onPlaceSelected: (AnchorPlaceWithDistance) -> Void
    
    @Environment(LocationService.self) private var locationService
    @State private var placesService = AnchorPlacesService()
    @State private var places: [AnchorPlaceWithDistance] = []
    @State private var isLoading = false
    @State private var error: Error?
    @State private var searchText = ""
    
    var filteredPlaces: [AnchorPlaceWithDistance] {
        var filtered = places
        
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
            // Search bar for filtering nearby places
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Filter places by name...", text: $searchText)
                    .submitLabel(.search)
                
                if !searchText.isEmpty {
                    Button(action: { 
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.bottom, 12)
            
            // Content
            if isLoading {
                VStack(spacing: 0) {
                    ForEach(0..<5, id: \.self) { _ in
                        SearchResultSkeleton()
                    }
                    Spacer()
                }
            } else if let error = error {
                VStack(spacing: 0) {
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
                }
            } else if filteredPlaces.isEmpty && !places.isEmpty {
                VStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: 12) {
                        Text("🔍 No places match your filter")
                            .font(.headline)
                        Text("Try adjusting your search")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    Spacer()
                }
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
                        onTap: { onPlaceSelected(placeWithDistance) }
                    )
                }
                .listStyle(.plain)
                .refreshable {
                    await loadNearbyPlaces(forceFreshLocation: true)
                }
            }
        }
        .task {
            await loadNearbyPlaces()
        }
    }
    
    private func loadNearbyPlaces(forceFreshLocation: Bool = false) async {
        isLoading = true
        error = nil
        
        var location: CLLocation?
        
        if forceFreshLocation {
            debugPrint("📍 Pull-to-refresh: requesting fresh location...")
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
        
        debugPrint("📍 Loading nearby places for location: \(location.coordinate.latitude), " +
                   "\(location.coordinate.longitude)")
        
        do {
            places = try await placesService.findNearbyPlacesWithDistance(
                near: location.coordinate,
                radiusMeters: 400
            )
            debugPrint("📍 Found \(places.count) nearby places")
        } catch {
            self.error = error
            debugPrint("❌ Error loading nearby places: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
}