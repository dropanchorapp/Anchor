//
//  SignInButton.swift
//  AnchorMobile
//
//  Reusable sign-in button that launches ASWebAuthenticationSession
//

import SwiftUI
import AuthenticationServices
import AnchorKit

/// Reusable sign-in button that launches secure OAuth flow
struct SignInButton: View {
    @Environment(AuthStore.self) private var authStore
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage: String?
    @State private var authSession: ASWebAuthenticationSession?

    var body: some View {
        Button(action: startSignIn) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.title3)
                }
                Text(isLoading ? "Connecting..." : "Sign in with Bluesky")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(isLoading)
        .alert("Authentication Error", isPresented: $showingError) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "Unknown error occurred")
        }
    }

    private func startSignIn() {
        guard !isLoading else { return }

        isLoading = true

        Task {
            do {
                let oauthURL = try await authStore.startDirectOAuthFlow()

                await MainActor.run {
                    startWebAuthenticationSession(with: oauthURL)
                }

            } catch {
                errorMessage = "Failed to start sign-in: \(error.localizedDescription)"
                showingError = true
                isLoading = false
            }
        }
    }

    private func startWebAuthenticationSession(with url: URL) {
        // Create ASWebAuthenticationSession for secure OAuth
        authSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: "anchor-app"
        ) { callbackURL, error in
            Task { @MainActor in
                self.isLoading = false

                if let error = error {
                    if (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin {
                        debugPrint("🔐 Sign-in cancelled by user")
                    } else {
                        self.errorMessage = "Sign-in failed: \(error.localizedDescription)"
                        self.showingError = true
                    }
                    return
                }

                guard let callbackURL = callbackURL else {
                    self.errorMessage = "Sign-in failed: No callback received"
                    self.showingError = true
                    return
                }

                // Handle the OAuth callback
                do {
                    _ = try await self.authStore.handleSecureOAuthCallback(callbackURL)
                } catch {
                    self.errorMessage = "Sign-in failed: \(error.localizedDescription)"
                    self.showingError = true
                }
            }
        }

        // Configure session
        authSession?.presentationContextProvider = WebAuthPresentationContextProvider()
        authSession?.prefersEphemeralWebBrowserSession = false

        // Start the authentication session
        authSession?.start()
    }
}

// MARK: - ASWebAuthenticationSession Support

/// Presentation context provider for ASWebAuthenticationSession
class WebAuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Find the key window in any connected window scene
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                if let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
                    return keyWindow
                }
            }
        }

        // If no key window found, try to find any window in any scene
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                if let window = windowScene.windows.first {
                    return window
                }
            }
        }

        // If no existing windows, create a new window with the first available scene
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                return UIWindow(windowScene: windowScene)
            }
        }

        // This should never happen in a normal iOS app
        fatalError("No UIWindowScene available for ASWebAuthenticationSession presentation anchor")
    }
}

// MARK: - Preview

#Preview {
    SignInButton()
        .environment(AuthStore(storage: InMemoryCredentialsStorage()))
        .padding()
}
