import SwiftUI
import SwiftData
import AnchorKit

struct SettingsWindow: View {
    @Environment(BlueskyService.self) private var blueskyService
    @Environment(LocationService.self) private var locationService
    @Environment(NearbyPlacesService.self) private var nearbyPlacesService
    @Environment(\.modelContext) private var modelContext

    @State private var handle = ""
    @State private var appPassword = ""
    @State private var isAuthenticating = false
    @State private var authError: String?
    @State private var showingAuthError = false
    @State private var showingAppPasswordInfo = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("⚓ Anchor Settings")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Spacer()
                }
                .padding()

                Divider()

                ScrollView {
                    VStack(spacing: 24) {
                        // Authentication Section
                        authenticationSection

                        Divider()

                        // Location Section
                        locationSection
                    }
                    .padding()
                }
            }
        }
        .frame(width: 400, height: 500)
        .alert("Authentication Error", isPresented: $showingAuthError) {
            Button("OK") {}
        } message: {
            Text(authError ?? "Unknown error occurred")
        }
        .alert("App Password Info", isPresented: $showingAppPasswordInfo) {
            Button("Open Bluesky Settings") {
                NSWorkspace.shared.open(blueskyService.getAppPasswordURL())
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("App passwords are secure tokens that let Anchor post to your Bluesky account. " +
                 "You can create and manage them in your Bluesky settings.")
        }
    }

    @ViewBuilder
    private var authenticationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("🔐 Bluesky Account")
                    .font(.headline)

                Spacer()

                if blueskyService.isAuthenticated {
                    Button("Sign Out") {
                        Task {
                            await blueskyService.signOut()
                            clearForm()
                        }
                    }
                    .buttonStyle(.bordered)
                    .foregroundStyle(.red)
                }
            }

            if blueskyService.isAuthenticated {
                authenticatedView
            } else {
                authenticationForm
            }
        }
    }

    @ViewBuilder
    private var authenticatedView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Signed in to Bluesky")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let handle = blueskyService.credentials?.handle {
                        Text("@\(handle)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .padding()
            .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

            Text("You can now post check-ins to your Bluesky timeline!")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var authenticationForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sign in to post check-ins to your Bluesky timeline")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Handle")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("your-handle.bsky.social", text: $handle)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textCase(.lowercase)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("App Password")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button("What's this?") {
                        showingAppPasswordInfo = true
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.blue)
                }

                SecureField("App password", text: $appPassword)
                    .textFieldStyle(.roundedBorder)
            }

            Button(action: authenticateWithBluesky) {
                HStack {
                    if isAuthenticating {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(isAuthenticating ? "Signing in..." : "Sign In")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isAuthenticating || handle.isEmpty || appPassword.isEmpty)

            VStack(alignment: .leading, spacing: 4) {
                Text("💡 Don't have an app password?")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Button("Create one in Bluesky Settings") {
                    NSWorkspace.shared.open(blueskyService.getAppPasswordURL())
                }
                .buttonStyle(.plain)
                .font(.caption2)
                .foregroundStyle(.blue)
            }
        }
    }

    @ViewBuilder
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📍 Location Services")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Location Permission")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack {
                    Image(systemName: locationService.hasLocationPermission
                        ? "checkmark.circle.fill"
                        : "xmark.circle.fill")
                        .foregroundStyle(locationService.hasLocationPermission ? .green : .red)

                    Text(locationService.hasLocationPermission ? "Authorized" : "Not Authorized")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()
                }

                if !locationService.hasLocationPermission {
                    Text("Location access is required to find nearby places for check-ins")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .padding(.top, 4)
                }
            }
        }
    }

    // MARK: - Methods

    private func authenticateWithBluesky() {
        guard !isAuthenticating else { return }

        isAuthenticating = true
        authError = nil

        Task {
            do {
                let success = try await blueskyService.authenticate(
                    handle: handle,
                    appPassword: appPassword
                )

                await MainActor.run {
                    isAuthenticating = false
                    if success {
                        clearForm()
                    } else {
                        authError = "Authentication failed"
                        showingAuthError = true
                    }
                }

            } catch ATProtoError.authenticationFailed {
                await MainActor.run {
                    isAuthenticating = false
                    authError = "Invalid handle or app password"
                    showingAuthError = true
                }

            } catch {
                await MainActor.run {
                    isAuthenticating = false
                    authError = "Network error: \(error.localizedDescription)"
                    showingAuthError = true
                }
            }
        }
    }

    private func clearForm() {
        handle = ""
        appPassword = ""
    }
}

#Preview {
    SettingsWindow()
        .environment(BlueskyService(storage: InMemoryCredentialsStorage()))
}
