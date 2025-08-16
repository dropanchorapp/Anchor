//
//  NearbyPlacesContentView.swift
//  AnchorMobile
//
//  Created by Claude on 16/08/2025.
//

import SwiftUI
import CoreLocation
import Foundation
import AnchorKit

// Content view without navigation wrapper - for use in CheckInView
struct NearbyPlacesContentView: View {
    @Environment(LocationService.self) private var locationService
    @State private var placesService = AnchorPlacesService()
    @State private var places: [AnchorPlaceWithDistance] = []
    @State private var isLoading = false
    @State private var error: Error?
    @State private var searchText = ""
    @State private var selectedCategory: PlaceCategorization.CategoryGroup?
    
    let onPlaceSelected: (Place) -> Void
    
    var filteredPlaces: [AnchorPlaceWithDistance] {
        var filtered = places
        
        // Filter by category
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { placeWithDistance in
                placeWithDistance.place.categoryGroup == selectedCategory
            }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { placeWithDistance in
                placeWithDistance.place.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    CategoryFilterButton(
                        category: nil,
                        isSelected: selectedCategory == nil,
                        action: { selectedCategory = nil }
                    )
                    
                    ForEach(PlaceCategorization.CategoryGroup.allCases, id: \.self) { category in
                        CategoryFilterButton(
                            category: category,
                            isSelected: selectedCategory == category,
                            action: { selectedCategory = category }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            
            // Places list
            if isLoading {
                Spacer()
                ProgressView("Finding nearby places...")
                    .padding()
                Spacer()
            } else if let error = error {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    
                    Text("Unable to find nearby places")
                        .font(.headline)
                    
                    Text(error.localizedDescription)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Try Again") {
                        Task {
                            await loadNearbyPlaces(forceFreshLocation: false)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                Spacer()
            } else if filteredPlaces.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image("anchor-no-locations")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 0.5)
                        )
                    
                    Text("No places found")
                        .font(.headline)
                    
                    Text("Pull down to refresh or try adjusting your search")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                Spacer()
            } else {
                List(filteredPlaces) { placeWithDistance in
                    PlaceRowView(
                        placeWithDistance: placeWithDistance
                    ) {
                        onPlaceSelected(placeWithDistance.place)
                    }
                    .listRowInsets(EdgeInsets())
                }
                .listStyle(.plain)
                .refreshable {
                    await loadNearbyPlaces(forceFreshLocation: true)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search places...")
        .task {
            await loadNearbyPlaces(forceFreshLocation: false)
        }
    }
    
    private func loadNearbyPlaces(forceFreshLocation: Bool = false) async {
        isLoading = true
        error = nil
        
        var location: CLLocation?
        
        if forceFreshLocation {
            // Force fresh location update when user pulls to refresh
            print("📍 Pull-to-refresh: requesting fresh location...")
            if let freshCoordinates = await locationService.requestCurrentLocation() {
                location = CLLocation(
                    latitude: freshCoordinates.latitude,
                    longitude: freshCoordinates.longitude
                )
            }
        } else {
            // Use existing location if available
            location = locationService.currentLocation
        }
        
        guard let location = location else {
            error = LocationError.locationNotAvailable
            isLoading = false
            return
        }
        
        print("📍 Loading nearby places at \(String(format: "%.6f", location.coordinate.latitude)), " +
              "\(String(format: "%.6f", location.coordinate.longitude))")
        
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
