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
    
    @State private var selectedTab: Tab = .browse
    
    enum Tab: String, CaseIterable {
        case browse = "Browse"
        case search = "Search"
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
            case .browse:
                PlaceBrowseTabView(onPlaceSelected: onPlaceSelected)
            case .search:
                PlaceSearchTabView(onPlaceSelected: onPlaceSelected)
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
