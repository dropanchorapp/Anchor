//
//  FeedView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 27/06/2025.
//

import SwiftUI
import AnchorKit

struct FeedView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(CheckInStore.self) private var checkInStore
    @State private var feedStore = FeedStore()

    var body: some View {
        NavigationView {
            Group {
                if authStore.isAuthenticated && authStore.credentials?.accessToken.isEmpty == false {
                    // Feed content
                    Group {
                        if feedStore.isLoading {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Loading check-ins...")
                                    .foregroundStyle(.secondary)
                                    .font(.body)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if let error = feedStore.error {
                            // Show error message
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundStyle(.orange)
                                    .font(.system(size: 40))

                                Text("Feed Unavailable")
                                    .font(.title2)
                                    .fontWeight(.semibold)

                                Text(error.localizedDescription)
                                    .foregroundStyle(.secondary)
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)

                                Button("Try Again") {
                                    Task {
                                        await loadFeed()
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if feedStore.posts.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "checkmark.bubble")
                                    .foregroundStyle(.secondary)
                                    .font(.system(size: 40))

                                Text("No check-ins found")
                                    .font(.title2)
                                    .fontWeight(.semibold)

                                Text("No check-ins found in the global feed.")
                                    .foregroundStyle(.secondary)
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)

                                Button("Refresh") {
                                    Task {
                                        await loadFeed()
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            List(feedStore.posts, id: \.id) { post in
                                FeedPostView(post: post)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    .listRowSeparator(.hidden)
                            }
                            .listStyle(.plain)
                        }
                    }
                    .refreshable {
                        await loadFeed()
                    }
                    .task {
                        await loadFeed()
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "person.slash")
                            .foregroundStyle(.orange)
                            .font(.system(size: 40))

                        Text("Sign in to see your feed")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Connect your Bluesky account to see check-ins from people you follow.")
                            .foregroundStyle(.secondary)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Text("Go to Settings to sign in")
                            .foregroundStyle(.blue)
                            .font(.callout)
                            .fontWeight(.medium)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Feed")
        }
    }

    private func loadFeed() async {
        guard let credentials = authStore.credentials else { 
            print("⚠️ No credentials available for feed loading")
            return 
        }
        
        // Validate that we have a valid access token
        guard !credentials.accessToken.isEmpty else {
            print("⚠️ Access token is empty")
            return
        }

        do {
            _ = try await feedStore.fetchGlobalFeed(credentials: credentials)
        } catch {
            print("❌ Feed loading failed: \(error)")
            // Error is now handled by FeedStore and displayed in UI
        }
    }
} 