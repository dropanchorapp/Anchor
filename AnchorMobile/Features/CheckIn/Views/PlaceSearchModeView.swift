//
//  PlaceSearchModeView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 06/07/2025.
//

import SwiftUI
import CoreLocation
import AnchorKit

struct PlaceSearchModeView: View {
    let onPlaceSelected: (Place) -> Void
    
    @Environment(LocationService.self) private var locationService
    @State private var placesService = AnchorPlacesService()
    @State private var searchResults: [AnchorPlaceWithDistance] = []
    @State private var isSearching = false
    @State private var searchError: Error?
    @State private var searchText = ""
    @State private var hasSearched = false
    
    var body: some View {
        VStack(spacing: 0) {
            if !hasSearched && searchText.isEmpty {
                // Initial search state
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
            } else if isSearching {
                // Loading state with skeleton views
                VStack(spacing: 0) {
                    ForEach(0..<5, id: \.self) { _ in
                        SearchResultSkeleton()
                    }
                    Spacer()
                }
            } else if let searchError = searchError {
                // Error state
                Spacer()
                VStack(spacing: 12) {
                    Text("⚠️ Search failed")
                        .font(.headline)
                    Text(searchError.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Try Again") {
                        Task {
                            await performSearch(query: searchText)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                Spacer()
            } else if searchResults.isEmpty && hasSearched {
                // Empty results state
                Spacer()
                VStack(spacing: 12) {
                    Text("🔍 No places found")
                        .font(.headline)
                    
                    if !searchText.isEmpty {
                        Text("No places found for \"\(searchText)\"")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text("Try a different search term or check your spelling")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                Spacer()
            } else {
                // Results list
                List(searchResults) { placeWithDistance in
                    PlaceRowView(
                        placeWithDistance: placeWithDistance,
                        onTap: {
                            onPlaceSelected(placeWithDistance.place)
                        }
                    )
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search for places like \"sushi bar\"...")
        .onSubmit(of: .search) {
            if searchText.count >= 3 {
                Task {
                    await performSearch(query: searchText)
                }
            }
        }
        .onChange(of: searchText) { oldValue, newValue in
            if newValue.isEmpty {
                searchResults = []
                hasSearched = false
                searchError = nil
            }
        }
    }
    
    private func performSearch(query: String) async {
        isSearching = true
        searchError = nil
        hasSearched = true
        
        guard let location = locationService.currentLocation else {
            searchError = LocationError.locationNotAvailable
            isSearching = false
            return
        }
        
        print("🔍 Performing search for '\(query)' at \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        do {
            searchResults = try await placesService.searchPlaces(
                query: query,
                near: location.coordinate,
                limit: 10
            )
            print("✅ Search completed: found \(searchResults.count) results for '\(query)'")
        } catch {
            searchError = error
            searchResults = []
            print("❌ Search error for '\(query)': \(error.localizedDescription)")
        }
        
        isSearching = false
    }
}

struct SearchResultSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 40, height: 40)
                .shimmer()
            
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(height: 16)
                    .shimmer()
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray6))
                    .frame(height: 12)
                    .frame(maxWidth: 120)
                    .shimmer()
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

// MARK: - Shimmer Effect
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        Color.white.opacity(0.4),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase)
                .clipped()
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 400
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerEffect())
    }
}

#Preview {
    PlaceSearchModeView { place in
        print("Selected place: \(place.name)")
    }
    .environment(LocationService())
}