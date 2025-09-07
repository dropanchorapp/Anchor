//
//  PlaceSearchTabView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 06/07/2025.
//

import SwiftUI
import CoreLocation
import AnchorKit

struct PlaceSearchTabView: View {
    let onPlaceSelected: (AnchorPlaceWithDistance) -> Void
    
    @Environment(LocationService.self) private var locationService
    @State private var placesService = AnchorPlacesService()
    @State private var searchResults: [AnchorPlaceWithDistance] = []
    @State private var isSearching = false
    @State private var searchError: Error?
    @State private var searchText = ""
    @State private var hasSearched = false
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar for API search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search for places like \"sushi bar\"...", text: $searchText)
                    .focused($isSearchFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        if searchText.count >= 3 {
                            Task { await performSearch() }
                        }
                    }
                    .onChange(of: searchText) { _, newValue in
                        if newValue.isEmpty {
                            searchResults = []
                            hasSearched = false
                            searchError = nil
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
            .padding(.horizontal)
            .padding(.bottom, 12)
            
            // Content
            if isSearching {
                VStack(spacing: 0) {
                    ForEach(0..<5, id: \.self) { _ in
                        SearchResultSkeleton()
                    }
                    Spacer()
                }
            } else if let searchError = searchError {
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
                List(searchResults) { placeWithDistance in
                    PlaceRowView(
                        placeWithDistance: placeWithDistance,
                        onTap: { onPlaceSelected(placeWithDistance) }
                    )
                }
                .listStyle(.plain)
            }
        }
        .onAppear {
            isSearchFocused = true
        }
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
        
        debugPrint("🔍 Performing search for '\(searchText)' at " +
                   "\(location.coordinate.latitude), \(location.coordinate.longitude)")
        
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