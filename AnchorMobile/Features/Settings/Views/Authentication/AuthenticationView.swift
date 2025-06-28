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
    @State private var handle = ""
    @State private var appPassword = ""
    @State private var showingAppPasswordInfo = false
    @State private var showingError = false
    @State private var isLoading = false
    @State private var lastError: String?
    
    var body: some View {
        NavigationView {
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
        }
        .alert("App Password Info", isPresented: $showingAppPasswordInfo) {
            Button("Open Bluesky Settings") {
                UIApplication.shared.open(authStore.getAppPasswordURL())
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("App passwords are secure tokens that let Anchor post to your Bluesky account. You can create and manage them in your Bluesky settings.")
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
        VStack(spacing: 20) {
            // Handle input
            VStack(alignment: .leading, spacing: 8) {
                Text("Handle")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                TextField("your-handle.bsky.social", text: $handle)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
            }
            
            // App password input
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("App Password")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Button("What's this?") {
                        showingAppPasswordInfo = true
                    }
                    .font(.callout)
                    .foregroundStyle(.blue)
                }
                
                SecureField("App password", text: $appPassword)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Sign in button
            Button(action: signIn) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.9)
                    }
                    Text(isLoading ? "Signing in..." : "Sign In")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isLoading || handle.isEmpty || appPassword.isEmpty)
            
            // Info text
            Text("Anchor uses the AT Protocol to securely connect to your Bluesky account. Your credentials are stored locally on your device.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top)
        }
    }
    
    // MARK: - Actions
    
    private func signIn() {
        guard !isLoading else { return }
        
        isLoading = true
        lastError = nil
        
        Task {
            do {
                let success = try await authStore.authenticate(
                    handle: handle.trimmingCharacters(in: .whitespacesAndNewlines),
                    appPassword: appPassword
                )
                
                if success {
                    // Clear form on successful login
                    handle = ""
                    appPassword = ""
                    
                    // Provide haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
                
            } catch {
                lastError = "Authentication failed: \(error.localizedDescription)"
                
            }
            
            isLoading = false
        }
    }
    
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
}

#Preview {
    AuthenticationView()
        .environment(AuthStore(storage: InMemoryCredentialsStorage()))
} 
