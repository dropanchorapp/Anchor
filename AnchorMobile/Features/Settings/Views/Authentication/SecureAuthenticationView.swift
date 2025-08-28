//
//  SecureAuthenticationView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 22/08/2025.
//

import SwiftUI
import AuthenticationServices
import AnchorKit

/// Authentication view for Bluesky sign-in
struct SecureAuthenticationView: View {
    @Environment(AuthStore.self) private var authStore
    @State private var showingError = false
    @State private var isLoading = false
    @State private var lastError: String?
    @State private var authSession: ASWebAuthenticationSession?
    private let presentationContextProvider = WebAuthPresentationContextProvider()
    
    var body: some View {
        mainContent
            .alert("Authentication Error", isPresented: $showingError) {
                Button("OK") {
                    lastError = nil
                    showingError = false
                }
            } message: {
                Text(lastError ?? "Unknown error occurred")
            }
            .onChange(of: lastError) { _, newError in
                showingError = newError != nil
            }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Content based on authentication state
                    if authStore.isAuthenticated {
                        // Header for authenticated state
                        authenticationHeader
                        authenticatedContent
                    } else {
                        secureLoginForm
                    }
                }
                .padding()
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.large)
            .contentShape(Rectangle())
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var authenticationHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: authStore.isAuthenticated ? "checkmark.shield.fill" : "shield")
                .font(.system(size: 60))
                .foregroundStyle(authStore.isAuthenticated ? .green : .blue)
            
            Text(authStore.isAuthenticated ? "Connected" : "Sign In")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(authStore.isAuthenticated 
                 ? "Your Bluesky account is connected to Anchor"
                 : "Connect your Bluesky account to start posting check-ins")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    private var authenticatedContent: some View {
        VStack(spacing: 16) {
            // Account info card with security indicator
            if let handle = authStore.handle {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Securely signed in as")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text("@\(handle)")
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(.green)
                            .font(.title3)
                    }
                    
                }
                .padding()
                .padding()
                .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
            
            // Sign out button
            Button(action: signOut) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.9)
                    }
                    Text(isLoading ? "Signing out..." : "Sign Out")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.red)
            .disabled(isLoading)
        }
    }
    
    @ViewBuilder
    private var secureLoginForm: some View {
        VStack(spacing: 24) {
            // Bluesky branding
            VStack(spacing: 12) {
                Image(systemName: "cloud.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.blue)
                
                Text("Sign in with Bluesky")
                    .font(.title3)
                    .fontWeight(.medium)
                
                Text("You'll enter your handle and password on Bluesky's secure servers or your personal PDS server")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 8)
            
            // Sign in button
            Button(action: startDirectOAuthFlow) {
                HStack(spacing: 12) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.title3)
                    }
                    Text(isLoading ? "Connecting..." : "Login with Bluesky")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .disabled(isLoading)
            
            // Privacy note
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "lock.shield")
                        .foregroundStyle(.green)
                    Text("Secure Authentication")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Text("Your credentials are handled securely through Bluesky's official OAuth. Anchor never sees your password.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: - Actions
    
    private func signOut() {
        guard !isLoading else { return }
        
        isLoading = true
        
        Task {
            await authStore.signOut()
            
            // Provide haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            isLoading = false
        }
    }
    
    private func startDirectOAuthFlow() {
        guard !isLoading else { return }
        
        isLoading = true
        
        Task {
            do {
                let oauthURL = try await authStore.startDirectOAuthFlow()
                
                print("✅ Direct OAuth authentication started")
                print("🔗 Opening authentication session")
                
                await MainActor.run {
                    startWebAuthenticationSession(with: oauthURL)
                }
                
            } catch {
                lastError = "Failed to connect: \(error.localizedDescription)"
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
                        print("🔐 Authentication was cancelled by user")
                    } else {
                        print("❌ Authentication failed: \(error.localizedDescription)")
                        self.lastError = "Authentication failed: \(error.localizedDescription)"
                    }
                    return
                }
                
                guard let callbackURL = callbackURL else {
                    print("❌ Authentication callback URL is nil")
                    self.lastError = "Authentication failed: No callback URL received"
                    return
                }
                
                print("🔐 Received authentication callback")
                
                // Handle the OAuth callback
                do {
                    let success = try await self.authStore.handleSecureOAuthCallback(callbackURL)
                    
                    if success {
                        print("🎉 Authentication completed successfully")
                    } else {
                        self.lastError = "Authentication failed: Invalid response"
                    }
                } catch {
                    print("❌ Authentication failed: \(error.localizedDescription)")
                    self.lastError = "Authentication failed: \(error.localizedDescription)"
                }
            }
        }
        
        // Configure session for better UX
        authSession?.presentationContextProvider = presentationContextProvider
        authSession?.prefersEphemeralWebBrowserSession = false
        
        // Start the authentication session
        authSession?.start()
    }
    
}

// MARK: - ASWebAuthenticationSession Support

/// Presentation context provider for ASWebAuthenticationSession
private class WebAuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Return the current window scene's key window
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}

// MARK: - Preview

#Preview {
    SecureAuthenticationView()
        .environment(AuthStore(storage: InMemoryCredentialsStorage()))
}
