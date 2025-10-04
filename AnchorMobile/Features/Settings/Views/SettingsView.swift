//
//  SettingsView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 27/06/2025.
//

import SwiftUI
import SwiftData
import AnchorKit
import StoreKit

struct SettingsView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(CheckInStore.self) private var checkInStore
    @Environment(\.requestReview) private var requestReview
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsArray: [AnchorSettings]

    private var settings: AnchorSettings {
        if let existing = settingsArray.first {
            return existing
        }

        // Create default settings if none exist
        let newSettings = AnchorSettings()
        modelContext.insert(newSettings)
        return newSettings
    }

    var body: some View {
        NavigationStack {
            List {
                // Place Providers Section
                Section {
                    Picker("Nearby Places", selection: Binding(
                        get: { settings.nearbyPlacesProvider },
                        set: { settings.nearbyPlacesProvider = $0 }
                    )) {
                        ForEach(PlaceProvider.nearbyProviders, id: \.self) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }

                    Picker("Place Search", selection: Binding(
                        get: { settings.placeSearchProvider },
                        set: { settings.placeSearchProvider = $0 }
                    )) {
                        ForEach(PlaceProvider.searchProviders, id: \.self) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }
                } header: {
                    Text("Data Sources")
                } footer: {
                    Text("Choose which OpenStreetMap data provider to use for discovering nearby places and searching for locations.")
                }

                // Account Section
                Section {
                    NavigationLink(destination: SecureAuthenticationView()) {
                        HStack {
                            Image(systemName: authStore.isAuthenticated ? "checkmark.circle.fill" : "person.circle")
                                .font(.title2)
                                .foregroundStyle(authStore.isAuthenticated ? .green : .secondary)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Account")
                                    .font(.headline)
                                
                                Text(authStore.isAuthenticated 
                                     ? "Connected as @\(authStore.credentials?.handle ?? "Unknown")"
                                     : "Not signed in")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                } header: {
                    Text("Bluesky")
                } footer: {
                    Text("Connect your Bluesky account to post check-ins to your timeline.")
                }
                
                // App Information Section
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .font(.title2)
                            .foregroundStyle(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("About Anchor")
                                .font(.headline)

                            Text("Location-based check-ins for AT Protocol")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()

                        Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    NavigationLink(destination: OpenSourceCreditsView()) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .font(.title2)
                                .foregroundStyle(.red)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Open Source")
                                    .font(.headline)

                                Text("Built with Swift and SwiftUI")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                    }
                    
                    Link(destination: URL(string: "https://dropanchor.app/privacy-policy")!) {
                        HStack {
                            Image(systemName: "lock.shield")
                                .font(.title2)
                                .foregroundStyle(.green)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Privacy")
                                    .font(.headline)

                                Text("Your data stays on your device")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("App")
                } footer: {
                    Text("Anchor is a free, open-source app that respects your privacy. " +
                         "All data is stored locally on your device.")
                }
                
                // Support Section
                Section {
                    Link(destination: URL(string: "https://bsky.app/profile/dropanchor.app")!) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .font(.title2)
                                .foregroundStyle(.blue)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Help & Support")
                                    .font(.headline)

                                Text("Get help with using Anchor")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        requestReview()
                    } label: {
                        HStack {
                            Image(systemName: "star.fill")
                                .font(.title2)
                                .foregroundStyle(.yellow)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Rate Anchor")
                                    .font(.headline)

                                Text("Help us improve the app")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("Support")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    let authStore = AuthStore(storage: InMemoryCredentialsStorage())
    SettingsView()
        .environment(authStore)
                    .environment(CheckInStore(authStore: authStore))
} 
