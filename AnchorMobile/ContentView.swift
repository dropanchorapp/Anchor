//
//  ContentView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 27/06/2025.
//

import SwiftUI

struct ContentView: View {
    @SceneStorage("selectedTab") private var selectedTabIndex = 0
    
    var body: some View {
        TabView(selection: $selectedTabIndex) {
            Tab("Feed", systemImage: "list.bullet", value: 0) {
                FeedView()
            }
            
            Tab("Check-in", systemImage: "location", value: 1) {
                CheckInView()
            }

            Tab("Settings", systemImage: "gear", value: 2) {
                SettingsView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

#Preview {
    ContentView()
}
