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
    @State private var selectedFeed: FeedType = .following

    enum FeedType: String, CaseIterable {
        case following = "Following"
        case timeline = "Timeline"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if authStore.isAuthenticated &&
                   authStore.credentials != nil &&
                   authStore.credentials?.accessToken.isEmpty == false {

                    // Segmented control for feed selection
                    Picker("Feed Type", selection: $selectedFeed) {
                        ForEach(FeedType.allCases, id: \.self) { feedType in
                            Text(feedType.rawValue).tag(feedType)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.bottom, 12)

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
                            // Different UI based on feed type
                            switch selectedFeed {
                            case .following:
                                // Following feed: compact, no date grouping
                                List(feedStore.posts, id: \.id) { post in
                                    FeedPostFollowingView(post: post) {
                                        selectedPost = post
                                    }
                                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                    .listRowSeparator(.visible, edges: .bottom)
                                    .listRowBackground(Color.clear)
                                }
                                .listStyle(.plain)
                                .scrollContentBackground(.hidden)

                            case .timeline:
                                // Timeline feed: date-grouped sections for personal log feel
                                let groupedPosts = feedStore.posts.groupedByDate()

                                ZStack {
                                    // Background timeline line that spans the entire feed
                                    HStack {
                                        Rectangle()
                                            .fill(.orange.opacity(0.3))
                                            .frame(width: 2)
                                            .padding(.leading, 19)
                                        Spacer()
                                    }

                                    List(groupedPosts) { section in
                                        Section {
                                            ForEach(section.posts, id: \.id) { post in
                                                FeedPostTimelineView(post: post) {
                                                    selectedPost = post
                                                }
                                                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                                                .listRowSeparator(.hidden)
                                                .listRowBackground(Color.clear)
                                            }
                                        } header: {
                                            FeedDateHeaderView(date: section.date)
                                                .listRowInsets(EdgeInsets())
                                        }
                                    }
                                    .listStyle(.plain)
                                    .scrollContentBackground(.hidden)
                                }
                            }
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
            .onChange(of: selectedFeed) { _, _ in
                // Feed type changed - reload feed
                Task {
                    await loadFeed()
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
            switch selectedFeed {
            case .following:
                // Use the authenticated user's DID for following feed
                guard let userDid = authStore.credentials?.did else {
                    // If not authenticated, fall back to global feed
                    _ = try await feedStore.fetchGlobalFeed()
                    return
                }
                _ = try await feedStore.fetchFollowingFeed(for: userDid)
            case .timeline:
                // Use the authenticated user's DID for timeline feed
                guard let userDid = authStore.credentials?.did else {
                    // If not authenticated, fall back to global feed
                    _ = try await feedStore.fetchGlobalFeed()
                    return
                }
                _ = try await feedStore.fetchUserFeed(for: userDid)
            }

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
    .environment(AppStateStore())
}
