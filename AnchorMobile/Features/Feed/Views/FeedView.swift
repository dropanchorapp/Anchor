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
    @Environment(AppStateStore.self) private var appStateStore
    @State private var feedStore = FeedStore()
    @State private var selectedPost: FeedPost?

    var body: some View {
        NavigationStack {
            Group {
                if authStore.isAuthenticated &&
                   authStore.credentials != nil &&
                   authStore.credentials?.accessToken.isEmpty == false {
                    // Feed content
                    Group {
                        if feedStore.isLoading {
                            FeedLoadingView()
                        } else if let error = feedStore.error {
                            FeedErrorView(error: error) {
                                Task {
                                    await loadFeed()
                                }
                            }
                        } else if feedStore.posts.isEmpty {
                            FeedEmptyView {
                                Task {
                                    await loadFeed()
                                }
                            }
                        } else {
                            List(feedStore.posts, id: \.id) { post in
                                FeedPostView(post: post) {
                                    selectedPost = post
                                }
                                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                .listRowSeparator(.visible, edges: .bottom)
                                .listRowBackground(Color.clear)
                            }
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)
                        }
                    }
                    .refreshable {
                        // Manual refresh always bypasses time restrictions
                        appStateStore.invalidateFeedCache()
                        await loadFeed()
                    }
                } else {
                    FeedNotAuthenticatedView()
                }
            }
            .navigationTitle("Feed")
            .navigationDestination(item: $selectedPost) { post in
                FeedPostDetailView(post: post)
            }
            .onAppear {
                // Set credentials for profile resolution
                feedStore.setCredentials(authStore.credentials)
                
                // Load feed on first appearance
                Task {
                    await loadFeedIfNeeded()
                }
            }
            .onChange(of: authStore.credentials?.did) { _, _ in
                // Update credentials in feedStore when they change
                feedStore.setCredentials(authStore.credentials)
            }
            .onChange(of: appStateStore.isAppActive) { oldValue, newValue in
                // When app becomes active, check if we should refresh
                if !oldValue && newValue {
                    Task {
                        await loadFeedIfNeeded()
                    }
                }
            }
        }
    }

    /// Load feed only if enough time has passed since last fetch (5+ minutes)
    private func loadFeedIfNeeded() async {
        guard appStateStore.shouldRefreshFeed() else {
            return
        }
        
        await loadFeed()
    }
    
    /// Force load feed regardless of timing (used for manual refresh and auth changes)
    private func loadFeed() async {
        do {
            _ = try await feedStore.fetchGlobalFeed()
            
            // Record successful fetch
            appStateStore.recordFeedFetch()
        } catch is CancellationError {
            // Ignore cancellation errors - they're expected when pull-to-refresh interrupts ongoing requests
        } catch {
            // Error is now handled by FeedStore and displayed in UI
        }
    }
}

// MARK: - Previews
#Preview("Empty State - Not Authenticated") {
    let authStore = AuthStore(storage: InMemoryCredentialsStorage())
    FeedView()
        .environment(authStore)
        .environment(CheckInStore(authStore: authStore))
        .environment(AppStateStore())
}

#Preview("Empty State - No Posts") {
    let authStore = AuthStore(storage: InMemoryCredentialsStorage())
    
    FeedView()
        .environment(authStore)
        .environment(CheckInStore(authStore: authStore))
        .environment(AppStateStore())
        .onAppear {
            // Simulate authenticated state for preview
            Task {
                try? await authStore.authenticate(handle: "preview.user.bsky.social", appPassword: "preview-app-password")
            }
        }
}

#Preview("Filled State") {
    let authStore = AuthStore(storage: InMemoryCredentialsStorage())
    
    // Create a simple view that mimics FeedView but with hardcoded posts
    NavigationStack {
        ScrollView {
            LazyVStack(spacing: 8) {
                FeedPostView(post: sampleCoffeeShopPost) { }
                    .padding(.horizontal)
                
                FeedPostView(post: sampleRestaurantPost) { }
                    .padding(.horizontal)
                
                FeedPostView(post: sampleClimbingPost) { }
                    .padding(.horizontal)
            }
            .padding(.top)
        }
        .navigationTitle("Feed")
        .navigationDestination(for: FeedPost.self) { post in
            FeedPostDetailView(post: post)
        }
    }
    .environment(authStore)
    .environment(CheckInStore(authStore: authStore))
    .environment(AppStateStore())
}
