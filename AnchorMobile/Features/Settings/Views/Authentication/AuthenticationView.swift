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
    @State private var customPDS = ""
    @State private var useCustomPDS = false
    @State private var showingAppPasswordInfo = false
    @State private var showingError = false
    @State private var isLoading = false
    @State private var lastError: String?
    @State private var showAdvancedOptions = false
    
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
            Text("App passwords are secure tokens that let Anchor post to your Bluesky account. " +
                 "You can create and manage them in your Bluesky settings.")
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
            
            // Advanced Options (collapsible)
            DisclosureGroup("Advanced Options", isExpanded: $showAdvancedOptions) {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(spacing: 8) {
                        // Auto-detect option (default)
                        Button(action: { useCustomPDS = false }) {
                            HStack {
                                Image(systemName: useCustomPDS ? "circle" : "checkmark.circle.fill")
                                    .foregroundStyle(useCustomPDS ? .secondary : Color.blue)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Auto-detect server")
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    Text("Discover your home server automatically")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        // Custom PDS option
                        Button(action: { useCustomPDS = true }) {
                            HStack {
                                Image(systemName: useCustomPDS ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(useCustomPDS ? .blue : .secondary)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Custom server")
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    Text("Specify your PDS server manually")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        // Custom PDS URL field (shown when custom is selected)
                        if useCustomPDS {
                            TextField("https://your-pds.example.com", text: $customPDS)
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.URL)
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .font(.headline)
            .foregroundStyle(.primary)
            .onChange(of: useCustomPDS) { _, newValue in
                if newValue {
                    showAdvancedOptions = true
                }
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
            .disabled(isLoading || handle.isEmpty || appPassword.isEmpty || 
                     (useCustomPDS && customPDS.isEmpty))
            
            // Info text
            VStack(spacing: 8) {
                Text("Anchor uses the AT Protocol to securely connect to your account. " +
                     "Your credentials are stored locally on your device.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                if useCustomPDS {
                    Text("💡 Custom servers are advanced AT Protocol hosting providers. " +
                         "Most users should use auto-detect.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                }
            }
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
                // Determine PDS URL to use
                let pdsURL = useCustomPDS ? customPDS.trimmingCharacters(in: .whitespacesAndNewlines) : nil
                
                let success = try await authStore.authenticate(
                    handle: handle.trimmingCharacters(in: .whitespacesAndNewlines),
                    appPassword: appPassword,
                    pdsURL: pdsURL
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
