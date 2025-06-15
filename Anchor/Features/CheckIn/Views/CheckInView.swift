import SwiftUI
import SwiftData
import AnchorKit

struct CheckInView: View {
    // MARK: - Properties
    let place: Place
    let onCancel: () -> Void
    let onComplete: () -> Void

    // MARK: - State
    @State private var message = ""
    @State private var isPosting = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var shouldCreateBlueskyPost: Bool

    // MARK: - Services
    @Environment(BlueskyService.self) private var blueskyService
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Initialization
    init(place: Place, onCancel: @escaping () -> Void, onComplete: @escaping () -> Void) {
        self.place = place
        self.onCancel = onCancel
        self.onComplete = onComplete
        self._shouldCreateBlueskyPost = State(initialValue: AnchorSettings.current.createBlueskyPosts)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                Text("Check In")
                    .font(.headline)

                Spacer()

                Button("Post") {
                    Task {
                        await postCheckIn()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isPosting)
            }
            .padding()

            Divider()

            // Place info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("📍")
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(place.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        if let category = place.category {
                            Text(category.capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal)
            }

            Divider()

            // Message input
            VStack(alignment: .leading, spacing: 8) {
                Text("Add a message (optional)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                TextEditor(text: $message)
                    .font(.body)
                    .frame(minHeight: 60, maxHeight: 120)
                    .padding(8)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)
            }
            
            // Bluesky posting toggle
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Also post to Bluesky", isOn: $shouldCreateBlueskyPost)
                    .font(.subheadline)
                    .disabled(!blueskyService.isAuthenticated)
                    .padding(.horizontal)
                
                if shouldCreateBlueskyPost && !blueskyService.isAuthenticated {
                    Text("Sign in to Bluesky to enable posting")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
            }

            if !blueskyService.isAuthenticated && shouldCreateBlueskyPost {
                VStack(spacing: 8) {
                    Text("⚠️ Not signed in to Bluesky")
                        .foregroundStyle(.orange)
                        .font(.caption)

                    Text("Sign in through Settings to post to Bluesky")
                        .foregroundStyle(.secondary)
                        .font(.caption2)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }

            Spacer(minLength: 16)

            if isPosting {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(shouldCreateBlueskyPost ? "Creating check-in and post..." : "Creating check-in...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
        .alert("Check-in Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "Unknown error occurred")
        }
    }

    // MARK: - Methods

    private func postCheckIn() async {
        guard !isPosting else { return }

        await MainActor.run {
            isPosting = true
            errorMessage = nil
        }

        do {
            let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
            let messageToPost = trimmedMessage.isEmpty ? nil : trimmedMessage

            let success = try await blueskyService.createCheckinWithOptionalPost(
                place: place,
                customMessage: messageToPost,
                shouldCreatePost: shouldCreateBlueskyPost,
                context: modelContext
            )

            await MainActor.run {
                isPosting = false
                if success {
                    onComplete()
                } else {
                    errorMessage = "Failed to post check-in"
                    showingError = true
                }
            }

        } catch ATProtoError.missingCredentials {
            await MainActor.run {
                isPosting = false
                errorMessage = shouldCreateBlueskyPost ? "Please sign in to Bluesky to create posts" : "Authentication required"
                showingError = true
            }

        } catch ATProtoError.authenticationFailed {
            await MainActor.run {
                isPosting = false
                errorMessage = "Your Bluesky credentials are invalid. Please sign in again."
                showingError = true
            }

        } catch ATProtoError.httpError(401) {
            await MainActor.run {
                isPosting = false
                errorMessage = "Your session has expired. Please sign in again."
                showingError = true
            }
            
        } catch AnchorPDSError.authenticationRequired {
            await MainActor.run {
                isPosting = false
                errorMessage = "Authentication required for AnchorPDS"
                showingError = true
            }
            
        } catch AnchorPDSError.serverError(let message) {
            await MainActor.run {
                isPosting = false
                errorMessage = "AnchorPDS error: \(message)"
                showingError = true
            }

        } catch {
            await MainActor.run {
                isPosting = false
                errorMessage = "Network error: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
}

private extension Place {
    var categoryIcon: String {
        if let category = self.category {
            switch category {
            case "climbing": return "🧗‍♂️"
            case "restaurant", "fast_food": return "🍽️"
            case "cafe": return "☕"
            case "bar", "pub": return "🍺"
            case "sports", "outdoor": return "🏪"
            case "museum": return "🏛️"
            case "attraction": return "🎯"
            default: return "📍"
            }
        }
        return "📍"
    }
}

#Preview {
    CheckInView(
        place: Place(
            elementType: .way,
            elementId: 123456,
            name: "Test Climbing Gym",
            latitude: 0,
            longitude: 0,
            tags: ["leisure": "climbing"]
        ),
        onCancel: {},
        onComplete: {}
    )
    .environment(BlueskyService())
}
