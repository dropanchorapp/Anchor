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
    @State private var feedStore: FeedStore?
    @State private var selectedPost: FeedPost?

    var body: some View {
        NavigationStack {
            Group {
                // Use direct authentication check instead of computed property to avoid SwiftUI evaluation issues
                if authStore.isAuthenticated && authStore.credentials != nil && authStore.credentials?.accessToken.isEmpty == false {
                    // Feed content
                    Group {
                        if let feedStore = feedStore, feedStore.isLoading {
                            FeedLoadingView()
                        } else if let feedStore = feedStore, let error = feedStore.error {
                            FeedErrorView(error: error) {
                                Task {
                                    await loadFeed()
                                }
                            }
                        } else if let feedStore = feedStore, feedStore.posts.isEmpty {
                            FeedEmptyView {
                                Task {
                                    await loadFeed()
                                }
                            }
                        } else if let feedStore = feedStore {
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
                        } else {
                            // Fallback case when feedStore is nil
                            FeedInitializingView()
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
                CheckInDetailView(post: post)
            }
            .task {
                // Initialize feedStore with authStore (always initialize, regardless of auth state)
                if feedStore == nil {
                    feedStore = FeedStore(authStore: authStore)
                }
                
                // Only load feed if authenticated
                if authStore.isAuthenticated && authStore.credentials != nil {
                    await loadFeedIfNeeded()
                }
            }
            .onChange(of: authStore.isAuthenticated) { oldValue, newValue in
                // When user logs in, automatically fetch the feed
                if !oldValue && newValue && authStore.credentials != nil {
                    Task {
                        // Force a fresh feed load when authentication becomes available
                        appStateStore.invalidateFeedCache()
                        await loadFeed()
                    }
                }
            }
            .onChange(of: authStore.credentials?.accessToken) { _, newToken in
                // When credentials change (e.g., token refresh), refetch if we have a new valid token
                if let newToken = newToken, !newToken.isEmpty, authStore.isAuthenticated {
                    Task {
                        await loadFeed()
                    }
                }
            }
            .onChange(of: appStateStore.isAppActive) { oldValue, newValue in
                // When app becomes active, check if we should refresh
                if !oldValue && newValue && authStore.isAuthenticated {
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
        guard let feedStore = feedStore else { 
            return 
        }
        
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
            CheckInDetailView(post: post)
        }
    }
    .environment(authStore)
    .environment(CheckInStore(authStore: authStore))
    .environment(AppStateStore())
}
