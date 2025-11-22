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
            TabSection {
                Tab("Feed", systemImage: "list.bullet") {
                    FeedView()
                }
                
                Tab("Check-in", systemImage: "location") {
                    CheckInView()
                }
            }

            Tab("Settings", systemImage: "gear") {
                SettingsView()
            }
        }
    }
}

#Preview {
    ContentView()
}
