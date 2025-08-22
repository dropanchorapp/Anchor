//
//  SettingsView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 27/06/2025.
//

import SwiftUI
import AnchorKit

struct SettingsView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(CheckInStore.self) private var checkInStore
    
    var body: some View {
        NavigationStack {
            List {
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
                            
                            Text("Location-based check-ins for Bluesky")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("v1.0.0")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
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
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
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
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("App")
                } footer: {
                    Text("Anchor is a free, open-source app that respects your privacy. " +
                         "All data is stored locally on your device.")
                }
                
                // Support Section
                Section {
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
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
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
