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

// MARK: - Previews
#Preview("Empty State - Not Authenticated") {
    let authStore = AuthStore(storage: InMemoryCredentialsStorage())
    FeedView()
        .environment(authStore)
        .environment(CheckInStore(authStore: authStore))
}

#Preview("Empty State - No Posts") {
    let authStore = AuthStore(storage: InMemoryCredentialsStorage())
    // Simulate authenticated state with valid credentials
    Task {
        try? await authStore.authenticate(handle: "preview.user.bsky.social", appPassword: "preview-app-password")
    }
    
    return FeedView()
        .environment(authStore)
        .environment(CheckInStore(authStore: authStore))
}

#Preview("Filled State") {
    let authStore = AuthStore(storage: InMemoryCredentialsStorage())
    
    // Create a simple view that mimics FeedView but with hardcoded posts
    return NavigationView {
        ScrollView {
            LazyVStack(spacing: 8) {
                FeedPostView(post: mockCoffeeShopPost)
                    .padding(.horizontal)
                
                FeedPostView(post: mockRestaurantPost)
                    .padding(.horizontal)
                
                FeedPostView(post: mockClimbingPost)
                    .padding(.horizontal)
            }
            .padding(.top)
        }
        .navigationTitle("Feed")
    }
    .environment(authStore)
    .environment(CheckInStore(authStore: authStore))
}

// MARK: - Mock Data for FeedView Preview
private let mockCoffeeShopPost = FeedPost(
    id: "at://did:plc:preview1/app.bsky.feed.post/1",
    author: FeedAuthor(
        did: "did:plc:preview1",
        handle: "coffee.lover.bsky.social",
        displayName: "Coffee Enthusiast",
        avatar: nil
    ),
    record: ATProtoRecord(
        text: "Perfect espresso and cozy atmosphere ☕️",
        createdAt: Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date()
    ),
    checkinRecord: AnchorPDSCheckinRecord(
        text: "Perfect espresso and cozy atmosphere ☕️",
        createdAt: ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date()),
        locations: [
            .address(CommunityAddressLocation(name: "Blue Bottle Coffee"))
        ],
        categoryIcon: "☕️"
    )
)

private let mockRestaurantPost = FeedPost(
    id: "at://did:plc:preview2/app.bsky.feed.post/2",
    author: FeedAuthor(
        did: "did:plc:preview2",
        handle: "foodie.adventures.bsky.social",
        displayName: "Sarah Chen",
        avatar: nil
    ),
    record: ATProtoRecord(
        text: "Amazing dim sum brunch! 🥟",
        createdAt: Calendar.current.date(byAdding: .hour, value: -3, to: Date()) ?? Date()
    ),
    checkinRecord: AnchorPDSCheckinRecord(
        text: "Amazing dim sum brunch! 🥟",
        createdAt: ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .hour, value: -3, to: Date()) ?? Date()),
        locations: [
            .address(CommunityAddressLocation(name: "Golden Dragon Restaurant"))
        ],
        categoryIcon: "🍽️"
    )
)

private let mockClimbingPost = FeedPost(
    id: "at://did:plc:preview3/app.bsky.feed.post/3",
    author: FeedAuthor(
        did: "did:plc:preview3",
        handle: "mountain.goat.bsky.social",
        displayName: "Alex Rodriguez",
        avatar: nil
    ),
    record: ATProtoRecord(
        text: "Sent my project! 🧗‍♂️",
        createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
    ),
    checkinRecord: AnchorPDSCheckinRecord(
        text: "Sent my project! 🧗‍♂️",
        createdAt: ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()),
        locations: [
            .address(CommunityAddressLocation(name: "Yosemite Valley"))
        ],
        categoryIcon: "🧗‍♂️"
    )
)
