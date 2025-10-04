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
    let onPlaceSelected: (AnchorPlaceWithDistance) -> Void
    
    @State private var selectedTab: Tab = .search

    enum Tab: String, CaseIterable {
        case search = "Search"
        case browse = "Browse"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Segmented control for tab selection
            Picker("Mode", selection: $selectedTab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 12)
            
            // Content based on selected tab
            switch selectedTab {
            case .search:
                PlaceSearchTabView(onPlaceSelected: onPlaceSelected)
            case .browse:
                PlaceBrowseTabView(onPlaceSelected: onPlaceSelected)
            }
        }
    }
}

#Preview {
    PlaceBrowseView { place in
        debugPrint("Selected place: \(place.place.name)")
    }
    .environment(LocationService())
}
