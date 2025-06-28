//
//  ContentView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 27/06/2025.
//

import SwiftUI

struct ContentView: View {

    var body: some View {
        TabView {
            FeedView()
                .tabItem {
                    Label("Feed", systemImage: "list.bullet")
                }
            
            CheckInView()
                .tabItem {
                    Label("Check-in", systemImage: "location")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
}
