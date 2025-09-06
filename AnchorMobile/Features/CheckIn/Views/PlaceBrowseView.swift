//
//  PlaceBrowseView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 06/07/2025.
//

import SwiftUI
import CoreLocation
import AnchorKit

struct PlaceBrowseView: View {
    let onPlaceSelected: (Place) -> Void
    
    @Environment(LocationService.self) private var locationService
    @State private var placesService = AnchorPlacesService()
    @State private var places: [AnchorPlaceWithDistance] = []
    @State private var searchResults: [AnchorPlaceWithDistance] = []
    @State private var isLoading = false
    @State private var isSearching = false
    @State private var error: Error?
    @State private var searchError: Error?
    @State private var selectedCategory: PlaceCategorization.CategoryGroup?
    @State private var searchText = ""
    @State private var searchMode: SearchMode = .filter
    @State private var hasSearched = false
    @FocusState private var isSearchFocused: Bool
    
    enum SearchMode {
        case filter  // Filter existing places by name
        case search  // Search for new places via API
    }
    
    var searchPlaceholder: String {
        switch searchMode {
        case .filter:
            return "Filter places by name..."
        case .search:
            return "Search for places like \"sushi bar\"..."
        }
    }
    
    var displayedPlaces: [AnchorPlaceWithDistance] {
        if searchMode == .search {
            return searchResults
        }
        
        // Filter mode - filter existing places
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
    
    var showSearchSuggestion: Bool {
        searchMode == .filter && displayedPlaces.isEmpty && !places.isEmpty && !isLoading
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
            .padding(.vertical, 12)
            
            // Search bar with toggle
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField(searchPlaceholder, text: $searchText)
                        .focused($isSearchFocused)
                        .onSubmit {
                            if searchMode == .search && searchText.count >= 3 {
                                Task { await performSearch() }
                            }
                        }
                        .onChange(of: searchText) { _, newValue in
                            if searchMode == .search {
                                if newValue.isEmpty {
                                    searchResults = []
                                    hasSearched = false
                                    searchError = nil
                                }
                            }
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: { 
                            searchText = ""
                            searchResults = []
                            hasSearched = false
                            searchError = nil
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
                
                // Toggle button
                Button(action: toggleSearchMode) {
                    HStack(spacing: 4) {
                        Image(systemName: searchMode == .filter ? "line.3.horizontal.decrease.circle" : "magnifyingglass.circle")
                        Text(searchMode == .filter ? "Filter" : "Search")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(searchMode == .search ? Color.accentColor : Color(.systemGray5))
                    .foregroundColor(searchMode == .search ? .white : .primary)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
            
            // Content
            if isLoading {
                // Loading state with skeleton views
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
                    
                    // Search suggestion for when browse fails
                    SearchSuggestionView {
                        switchToSearchMode()
                    }
                }
            } else if searchMode == .search {
                // Search mode content
                if isSearching {
                    // Search loading state
                    VStack(spacing: 0) {
                        ForEach(0..<5, id: \.self) { _ in
                            SearchResultSkeleton()
                        }
                        Spacer()
                    }
                } else if let searchError = searchError {
                    // Search error state
                    Spacer()
                    VStack(spacing: 12) {
                        Text("⚠️ Search failed")
                            .font(.headline)
                        Text(searchError.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Try Again") {
                            Task { await performSearch() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    Spacer()
                } else if searchResults.isEmpty && hasSearched {
                    // Search empty results
                    Spacer()
                    VStack(spacing: 12) {
                        Text("🔍 No places found")
                            .font(.headline)
                        
                        if !searchText.isEmpty {
                            Text("No places found for \"\(searchText)\"")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Text("Try a different search term")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    Spacer()
                } else if !hasSearched && searchText.isEmpty {
                    // Search initial state
                    Spacer()
                    VStack(spacing: 20) {
                        Text("🔍 Search for specific places nearby")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Examples:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("• \"coffee shop\"")
                                    Text("• \"sushi bar\"")
                                    Text("• \"climbing gym\"")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("• \"italian restaurant\"")
                                    Text("• \"book store\"")
                                    Text("• \"bike shop\"")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding()
                    Spacer()
                } else {
                    // Search results list
                    List(displayedPlaces) { placeWithDistance in
                        PlaceRowView(
                            placeWithDistance: placeWithDistance,
                            onTap: { onPlaceSelected(placeWithDistance.place) }
                        )
                    }
                    .listStyle(.plain)
                }
            } else if displayedPlaces.isEmpty && !places.isEmpty {
                // Filter empty results
                VStack(spacing: 0) {
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
                    
                    if showSearchSuggestion {
                        SearchSuggestionView {
                            switchToSearchMode()
                        }
                    }
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
                // Browse mode places list
                List {
                    ForEach(displayedPlaces) { placeWithDistance in
                        PlaceRowView(
                            placeWithDistance: placeWithDistance,
                            onTap: { onPlaceSelected(placeWithDistance.place) }
                        )
                    }
                    
                    if searchMode == .filter && showSearchSuggestion {
                        SearchSuggestionView {
                            switchToSearchMode()
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    }
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
    
    private func toggleSearchMode() {
        searchMode = searchMode == .filter ? .search : .filter
        searchText = ""
        searchResults = []
        hasSearched = false
        searchError = nil
    }
    
    private func switchToSearchMode() {
        searchMode = .search
        searchText = ""
        searchResults = []
        hasSearched = false
        searchError = nil
        isSearchFocused = true
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
        
        debugPrint("📍 Loading nearby places for location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
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
    
    private func performSearch() async {
        guard !searchText.isEmpty && searchText.count >= 3 else { return }
        
        isSearching = true
        searchError = nil
        hasSearched = true
        
        guard let location = locationService.currentLocation else {
            searchError = LocationError.locationNotAvailable
            isSearching = false
            return
        }
        
        debugPrint("🔍 Performing search for '\(searchText)' at \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        do {
            searchResults = try await placesService.searchPlaces(
                query: searchText,
                near: location.coordinate,
                limit: 10
            )
            debugPrint("✅ Search completed: found \(searchResults.count) results for '\(searchText)'")
        } catch {
            searchError = error
            searchResults = []
            debugPrint("❌ Search error for '\(searchText)': \(error.localizedDescription)")
        }
        
        isSearching = false
    }
}

struct SearchSuggestionView: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text("Didn't find what you're looking for?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.caption)
                    Text("Search for places nearby")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.accentColor)
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}


#Preview {
    PlaceBrowseView { place in
        debugPrint("Selected place: \(place.name)")
    }
    .environment(LocationService())
}