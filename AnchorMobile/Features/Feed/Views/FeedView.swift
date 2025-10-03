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
    @Environment(FeedStore.self) private var feedStore
    @State private var selectedPost: FeedPost?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if authStore.isAuthenticated &&
                   authStore.credentials != nil &&
                   authStore.credentials?.accessToken.isEmpty == false {

                    // Personal timeline view (date-grouped sections for personal log feel)
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
                                FeedPostTimelineView(post: post) {
                                    selectedPost = post
                                }
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowSeparator(.hidden)
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
                // Load feed on first appearance
                Task {
                    await loadFeedIfNeeded()
                }
            }
            .onChange(of: authStore.credentials?.did) { _, _ in
                // Credentials change - reload feed to potentially show following feed
                Task {
                    await loadFeedIfNeeded()
                }
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
    /// **PDS-Only Architecture**: Loads only user's personal timeline
    private func loadFeed() async {
        do {
            // Use the authenticated user's DID for personal timeline
            guard let userDid = authStore.credentials?.did else {
                return
            }
            _ = try await feedStore.fetchUserFeed(for: userDid)

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
        .environment(FeedStore())
        .environment(AppStateStore())
}

#Preview("Empty State - No Posts") {
    let authStore = AuthStore(storage: InMemoryCredentialsStorage())

    FeedView()
        .environment(authStore)
        .environment(CheckInStore(authStore: authStore))
        .environment(FeedStore())
        .environment(AppStateStore())
}

#Preview("Filled State") {
    let authStore = AuthStore(storage: InMemoryCredentialsStorage())

    // Create a simple view that mimics FeedView but with hardcoded posts
    NavigationStack {
        ScrollView {
            LazyVStack(spacing: 8) {
                FeedPostFollowingView(post: sampleCoffeeShopPost) { }
                    .padding(.horizontal)

                FeedPostFollowingView(post: sampleRestaurantPost) { }
                    .padding(.horizontal)

                FeedPostFollowingView(post: sampleClimbingPost) { }
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
    .environment(FeedStore())
    .environment(AppStateStore())
}
