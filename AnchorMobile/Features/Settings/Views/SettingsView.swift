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
                    Text(
                        "Choose which OpenStreetMap data provider to use for " +
                        "discovering nearby places and searching for locations."
                    )
                }

                // Account Section
                Section {
                    switch authStore.authenticationState {
                    case .authenticated(let credentials):
                        // Show account info
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.green)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Account")
                                    .font(.headline)

                                Text("Connected as @\(credentials.handle)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }

                        // Sign out button
                        Button(role: .destructive) {
                            Task {
                                await authStore.signOut()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.right.square")
                                Text("Sign Out")
                            }
                        }

                    case .error(let error):
                        // Show error state with recovery actions
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.orange)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Authentication Error")
                                        .font(.headline)

                                    Text(error.localizedDescription)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }

                            // Recovery actions based on error type
                            if error.isRecoverable {
                                // Network errors - allow retry
                                HStack(spacing: 12) {
                                    Button("Retry") {
                                        Task {
                                            await authStore.validateSessionOnAppResume()
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)

                                    Button("Sign Out", role: .destructive) {
                                        Task {
                                            await authStore.signOut()
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                }
                            } else {
                                // Session expired - need re-authentication
                                VStack(spacing: 8) {
                                    SignInButton()

                                    Button("Clear Session", role: .destructive) {
                                        Task {
                                            await authStore.signOut()
                                        }
                                    }
                                    .font(.caption)
                                    .buttonStyle(.plain)
                                    .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))

                    case .sessionExpired:
                        // Show session expired - will be refreshed automatically
                        HStack(spacing: 12) {
                            ProgressView()

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Session Expired")
                                    .font(.headline)

                                Text("Refreshing your session...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }

                    case .refreshing:
                        // Show refreshing state
                        HStack(spacing: 12) {
                            ProgressView()

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Refreshing Session")
                                    .font(.headline)

                                Text("Updating your authentication...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }

                    case .authenticating:
                        // Show authenticating state
                        HStack(spacing: 12) {
                            ProgressView()

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Signing In")
                                    .font(.headline)

                                Text("Please wait...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }

                    case .unauthenticated:
                        // Show sign in button
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "person.circle")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Account")
                                        .font(.headline)

                                    Text("Not signed in")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }

                            SignInButton()
                        }
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
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
