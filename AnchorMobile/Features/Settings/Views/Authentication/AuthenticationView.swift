//
//  AuthenticationView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 27/06/2025.
//

import SwiftUI
import AnchorKit

struct AuthenticationView: View {
    @Environment(AuthStore.self) private var authStore
    @State private var showingError = false
    @State private var isLoading = false
    @State private var lastError: String?
    @State private var showingOAuthWebView = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    authenticationHeader
                    
                    // Content based on authentication state
                    if authStore.isAuthenticated {
                        authenticatedContent
                    } else {
                        loginForm
                    }
                }
                .padding()
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.large)
            .contentShape(Rectangle())
        }
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
        .sheet(isPresented: $showingOAuthWebView) {
            NavigationView {
                OAuthWebView(
                    url: URL(string: "https://dropanchor.app/mobile-auth")!,
                    onAuthComplete: handleOAuthResult,
                    onCancel: {
                        showingOAuthWebView = false
                        isLoading = false
                    }
                )
                .navigationTitle("Sign in to Bluesky")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingOAuthWebView = false
                            isLoading = false
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var authenticationHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: authStore.isAuthenticated ? "checkmark.circle.fill" : "person.circle")
                .font(.system(size: 60))
                .foregroundStyle(authStore.isAuthenticated ? .green : .secondary)
            
            Text(authStore.isAuthenticated ? "Connected" : "Sign In")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(authStore.isAuthenticated 
                 ? "Your Bluesky account is connected"
                 : "Sign in to post check-ins to your Bluesky timeline")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    private var authenticatedContent: some View {
        VStack(spacing: 16) {
            // Account info card
            if let handle = authStore.handle {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Signed in as")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("@\(handle)")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title3)
                }
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
    private var loginForm: some View {
        VStack(spacing: 24) {
            // OAuth sign in button
            Button(action: startOAuthFlow) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.9)
                    }
                    Text(isLoading ? "Opening..." : "Sign in with Bluesky")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isLoading)
            
            // Info text
            Text("You'll be redirected to Bluesky's secure authentication page. " +
                 "Your credentials are never stored by Anchor.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
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
    
    private func startOAuthFlow() {
        guard !isLoading else { return }
        
        isLoading = true
        showingOAuthWebView = true
    }
    
    private func handleOAuthResult(_ result: OAuthResult) {
        showingOAuthWebView = false
        
        switch result {
        case .success(let authData):
            Task {
                do {
                    let oauthAuthData = AnchorKit.OAuthAuthenticationData(
                        accessToken: authData.accessToken,
                        refreshToken: authData.refreshToken,
                        did: authData.did,
                        handle: authData.handle,
                        sessionId: authData.sessionId,
                        avatar: authData.avatar,
                        displayName: authData.displayName
                    )
                    
                    let success = try await authStore.authenticateWithOAuth(oauthAuthData)
                    
                    if success {
                        // Provide haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        print("✅ OAuth authentication completed for handle: \(authData.handle)")
                    }
                } catch {
                    lastError = "OAuth authentication failed: \(error.localizedDescription)"
                }
                
                isLoading = false
            }
            
        case .failure(let error):
            lastError = "OAuth authentication failed: \(error.localizedDescription)"
            isLoading = false
        }
    }
}

#Preview {
    AuthenticationView()
        .environment(AuthStore(storage: InMemoryCredentialsStorage()))
} 
