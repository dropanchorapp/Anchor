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

// MARK: - Discovery Mode Enum
enum PlaceDiscoveryMode: String, CaseIterable {
    case none = "none"
    case browse = "browse"
    case search = "search"
    
    var title: String {
        switch self {
        case .none: return "Choose"
        case .browse: return "Browse Nearby"
        case .search: return "Search Nearby"
        }
    }
    
    var icon: String {
        switch self {
        case .none: return ""
        case .browse: return "📋"
        case .search: return "🔍"
        }
    }
    
    var description: String {
        switch self {
        case .none: return ""
        case .browse: return "See what's around you by category"
        case .search: return "Type what you're looking for"
        }
    }
}

struct NearbyPlacesView: View {
    let onPlaceSelected: (AnchorPlaceWithDistance) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            PlaceBrowseView(onPlaceSelected: onPlaceSelected)
                .navigationTitle("Nearby Places")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

#Preview("Default") {
    NearbyPlacesView { placeWithDistance in
        print("Selected place: \(placeWithDistance.place.name)")
    }
    .environment(LocationService())
}