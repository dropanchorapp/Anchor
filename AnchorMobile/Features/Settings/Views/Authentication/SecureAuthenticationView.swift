//
//  SecureAuthenticationView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 22/08/2025.
//

import SwiftUI
import WebKit
import AnchorKit

/// Secure authentication view with PKCE OAuth protection
/// 
/// Replaces the insecure OAuth flow with PKCE-protected authentication
/// that prevents protocol handler interception attacks.
struct SecureAuthenticationView: View {
    @Environment(AuthStore.self) private var authStore
    @State private var handle: String = ""
    @State private var showingError = false
    @State private var isLoading = false
    @State private var lastError: String?
    @State private var showingSecureOAuthWebView = false
    @State private var oauthURL: URL?
    
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
            .sheet(isPresented: $showingSecureOAuthWebView) {
                oauthWebViewSheet
            }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    authenticationHeader
                    
                    // Content based on authentication state
                    if authStore.isAuthenticated {
                        authenticatedContent
                    } else {
                        secureLoginForm
                    }
                }
                .padding()
            }
            .navigationTitle("Secure Account")
            .navigationBarTitleDisplayMode(.large)
            .contentShape(Rectangle())
        }
    }
    
    @ViewBuilder
    private var oauthWebViewSheet: some View {
        NavigationView {
            if let oauthURL = oauthURL {
                SecureOAuthWebView(
                    url: oauthURL,
                    onAuthComplete: handleSecureOAuthResult,
                    onCancel: {
                        self.showingSecureOAuthWebView = false
                        self.isLoading = false
                        self.oauthURL = nil
                    }
                )
                .navigationTitle("Secure Sign in to Bluesky")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            self.showingSecureOAuthWebView = false
                            self.isLoading = false
                            self.oauthURL = nil
                        }
                    }
                }
            } else {
                ProgressView("Initializing secure authentication...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var authenticationHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: authStore.isAuthenticated ? "checkmark.shield.fill" : "shield")
                .font(.system(size: 60))
                .foregroundStyle(authStore.isAuthenticated ? .green : .blue)
            
            Text(authStore.isAuthenticated ? "Secure Connection" : "Secure Sign In")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                Text(authStore.isAuthenticated 
                     ? "Your Bluesky account is securely connected with PKCE protection"
                     : "Sign in securely with PKCE protection against token theft")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                if !authStore.isAuthenticated {
                    HStack(spacing: 4) {
                        Image(systemName: "shield.checkered")
                            .font(.caption)
                        Text("Protected by PKCE OAuth 2.1")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.blue)
                }
            }
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
                    
                    // Security features
                    HStack(spacing: 16) {
                        SecurityFeature(icon: "key.fill", text: "PKCE Protected")
                        SecurityFeature(icon: "lock.shield.fill", text: "Token Secure")
                        SecurityFeature(icon: "checkmark.seal.fill", text: "OAuth 2.1")
                    }
                    .font(.caption)
                    .foregroundStyle(.green)
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
    private var secureLoginForm: some View {
        VStack(spacing: 24) {
            // Handle input field
            VStack(alignment: .leading, spacing: 8) {
                Text("Bluesky Handle")
                    .font(.headline)
                
                TextField("your-handle.bsky.social", text: $handle)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                
                Text("Enter your full Bluesky handle (e.g., alice.bsky.social)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Secure OAuth sign in button
            Button(action: startSecureOAuthFlow) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "shield.checkered")
                    }
                    Text(isLoading ? "Initializing secure flow..." : "Sign in securely with PKCE")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isLoading || handle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            
            // Security info
            VStack(spacing: 12) {
                Text("🔐 Enhanced Security Features")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading, spacing: 8) {
                    SecurityInfo(
                        icon: "shield.checkered",
                        title: "PKCE Protection",
                        description: "Prevents token theft via protocol handler interception"
                    )
                    
                    SecurityInfo(
                        icon: "key.fill",
                        title: "Secure Code Exchange",
                        description: "Uses cryptographic verification for token exchange"
                    )
                    
                    SecurityInfo(
                        icon: "lock.shield",
                        title: "OAuth 2.1 Compliant",
                        description: "Follows latest OAuth security recommendations"
                    )
                }
                
                Text("Your credentials are never stored by Anchor. " +
                     "All authentication is handled securely through Bluesky's OAuth servers.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
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
    
    private func startSecureOAuthFlow() {
        guard !isLoading else { return }
        guard !handle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isLoading = true
        let trimmedHandle = handle.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            do {
                let oauthURL = try await authStore.startSecureOAuthFlow(handle: trimmedHandle)
                self.oauthURL = oauthURL
                showingSecureOAuthWebView = true
                
                print("✅ Secure OAuth flow started for @\(trimmedHandle)")
                
            } catch {
                lastError = "Failed to start secure authentication: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    private func handleSecureOAuthResult(_ result: Result<URL, Error>) {
        showingSecureOAuthWebView = false
        oauthURL = nil
        
        switch result {
        case .success(let callbackURL):
            Task {
                do {
                    let success = try await authStore.handleSecureOAuthCallback(callbackURL)
                    
                    if success {
                        // Clear handle field on successful auth
                        handle = ""
                        
                        // Provide haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        print("✅ Secure OAuth authentication completed successfully")
                    } else {
                        lastError = "Secure OAuth authentication failed"
                    }
                } catch {
                    lastError = "Secure OAuth authentication failed: \(error.localizedDescription)"
                }
                
                isLoading = false
            }
            
        case .failure(let error):
            lastError = "Secure OAuth authentication failed: \(error.localizedDescription)"
            isLoading = false
        }
    }
}

// MARK: - Supporting Views

private struct SecurityFeature: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
            Text(text)
                .fontWeight(.medium)
        }
    }
}

private struct SecurityInfo: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Secure OAuth WebView

private struct SecureOAuthWebView: UIViewRepresentable {
    let url: URL
    let onAuthComplete: (Result<URL, Error>) -> Void
    let onCancel: () -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        
        // Set custom user agent to identify as mobile app
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = "AnchorApp/1.0 (iOS; PKCE-Protected)"
        webView.navigationDelegate = context.coordinator
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url != url {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: SecureOAuthWebView
        
        init(_ parent: SecureOAuthWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            
            // Check if this is our custom URL scheme callback
            if url.scheme == "anchor-app" && url.host == "auth-callback" {
                handleSecureAuthCallback(url: url)
                decisionHandler(.cancel)
                return
            }
            
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.onAuthComplete(.failure(error))
        }
        
        private func handleSecureAuthCallback(url: URL) {
            print("🔐 SecureOAuthWebView: Handling secure OAuth callback with PKCE protection")
            parent.onAuthComplete(.success(url))
        }
    }
}

// MARK: - Preview

#Preview {
    SecureAuthenticationView()
        .environment(AuthStore(storage: InMemoryCredentialsStorage()))
}
