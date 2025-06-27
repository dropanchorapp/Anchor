import SwiftUI
import AnchorKit

struct FeedTabView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(CheckInStore.self) private var checkInStore
    @State private var feedStore = FeedStore()

    var body: some View {
        VStack(spacing: 16) {
            if authStore.isAuthenticated {
                // Feed content
                Group {
                    if feedStore.isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Loading check-ins...")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = feedStore.error {
                        // Show error message
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                                .font(.title)

                            Text("Feed Unavailable")
                                .font(.headline)

                            Text(error.localizedDescription)
                                .foregroundStyle(.secondary)
                                .font(.caption)
                                .multilineTextAlignment(.center)

                            Button("Try Again") {
                                Task {
                                    await loadFeed()
                                }
                            }
                            .buttonStyle(.borderless)
                            .foregroundStyle(.blue)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if feedStore.posts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.bubble")
                                .foregroundStyle(.secondary)
                                .font(.title)

                            Text("No check-ins found")
                                .font(.headline)

                            Text("No check-ins found in the global feed.")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                                .multilineTextAlignment(.center)

                            Button("Refresh") {
                                Task {
                                    await loadFeed()
                                }
                            }
                            .buttonStyle(.borderless)
                            .foregroundStyle(.blue)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(feedStore.posts, id: \.id) { post in
                                    FeedPostView(post: post)
                                }
                            }
                            .padding()
                        }
                    }
                }
                .refreshable {
                    await loadFeed()
                }
                .task {
                    await loadFeed()
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "person.slash")
                        .foregroundStyle(.orange)
                        .font(.title)

                    Text("Sign in to see your feed")
                        .font(.headline)

                    Text("Connect your Bluesky account to see check-ins from people you follow.")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                        .multilineTextAlignment(.center)

                    Text("Click the gear button to open Settings")
                        .foregroundStyle(.blue)
                        .font(.caption2)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func loadFeed() async {
        guard let credentials = authStore.credentials else { return }

        do {
            _ = try await feedStore.fetchGlobalFeed(credentials: credentials)
        } catch {
            // Error is now handled by FeedStore and displayed in UI
            // No need to print to console
        }
    }
}

#Preview("Authenticated with Posts") {
    let storage = InMemoryCredentialsStorage()
    let authStore = AuthStore(storage: storage)
    let checkInStore = CheckInStore(authStore: authStore)
    
    FeedTabView()
        .environment(authStore)
        .environment(checkInStore)
        .frame(width: 300, height: 500)
        .onAppear {
            Task {
                let testCredentials = AuthCredentials(
                    handle: "alice.bsky.social",
                    accessToken: "fake-jwt",
                    refreshToken: "fake-refresh",
                    did: "did:plc:test",
                    expiresAt: Date().addingTimeInterval(3600)
                )
                try? await storage.save(testCredentials)
                _ = await authStore.loadStoredCredentials()
            }
        }
}

#Preview("Unauthenticated") {
    let storage = InMemoryCredentialsStorage()
    let authStore = AuthStore(storage: storage)
    let checkInStore = CheckInStore(authStore: authStore)
    
    FeedTabView()
        .environment(authStore)
        .environment(checkInStore)
        .frame(width: 300, height: 500)
}

#Preview("Loading State") {
    let storage = InMemoryCredentialsStorage()
    let authStore = AuthStore(storage: storage)
    let checkInStore = CheckInStore(authStore: authStore)
    
    FeedTabView()
        .environment(authStore)
        .environment(checkInStore)
        .frame(width: 300, height: 500)
        .onAppear {
            Task {
                let testCredentials = AuthCredentials(
                    handle: "alice.bsky.social",
                    accessToken: "fake-jwt",
                    refreshToken: "fake-refresh",
                    did: "did:plc:test",
                    expiresAt: Date().addingTimeInterval(3600)
                )
                try? await storage.save(testCredentials)
                _ = await authStore.loadStoredCredentials()
            }
        }
}
