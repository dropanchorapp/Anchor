//
//  NearbyPlacesView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 06/07/2025.
//

import SwiftUI
import CoreLocation
import Foundation
import AnchorKit

struct NearbyPlacesView: View {
    @Environment(LocationService.self) private var locationService
    @Environment(\.dismiss) private var dismiss
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
        NavigationStack {
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
                        
                        Text("Try adjusting your search or category filter")
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
            .navigationTitle("Nearby Places")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search places...")
            .task {
                await loadNearbyPlaces(forceFreshLocation: false)
            }
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

struct CategoryFilterButton: View {
    let category: PlaceCategorization.CategoryGroup?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let category = category {
                    Text(category.icon)
                        .font(.body)
                    Text(category.rawValue.capitalized)
                        .font(.callout)
                        .fontWeight(.medium)
                } else {
                    Text("All")
                        .font(.callout)
                        .fontWeight(.medium)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color.clear)
            .foregroundColor(isSelected ? .white : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct PlaceRowView: View {
    let placeWithDistance: AnchorPlaceWithDistance
    let onTap: () -> Void
    
    private var place: Place {
        placeWithDistance.place
    }
    
    private var distance: String {
        placeWithDistance.formattedDistance
    }
    
    private var categoryGroup: PlaceCategorization.CategoryGroup? {
        place.categoryGroup
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Category icon
                Text(categoryGroup?.icon ?? "📍")
                    .font(.title2)
                    .frame(width: 40, height: 40)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(place.name)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text("OpenStreetMap POI")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "location")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(distance)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
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

#Preview("Default") {
    NearbyPlacesView { place in
        print("Selected place: \(place.name)")
    }
    .environment(LocationService())
}

#Preview("No Places Found") {
    // Mock the empty state UI directly
    NavigationStack {
        VStack(spacing: 0) {
            // Category filter (same as in the actual view)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    CategoryFilterButton(
                        category: nil,
                        isSelected: true,
                        action: { }
                    )
                    
                    ForEach(PlaceCategorization.CategoryGroup.allCases, id: \.self) { category in
                        CategoryFilterButton(
                            category: category,
                            isSelected: false,
                            action: { }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            
            // Empty state UI
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
                
                Text("Try adjusting your search or category filter")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            Spacer()
        }
        .navigationTitle("Nearby Places")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") { }
            }
        }
        .searchable(text: .constant(""), prompt: "Search places...")
    }
}
