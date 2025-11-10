import Foundation

// MARK: - Authentication Store Protocol

@MainActor
public protocol AuthStoreProtocol {
    var isAuthenticated: Bool { get }
    var credentials: AuthCredentials? { get }
    var handle: String? { get }
    func loadStoredCredentials() async -> AuthCredentials?
    func startDirectOAuthFlow() async throws -> URL
    func handleSecureOAuthCallback(_ callbackURL: URL) async throws -> Bool
    func signOut() async
    func getValidCredentials() async throws -> AuthCredentialsProtocol
    func validateSessionOnAppLaunch() async
    func validateSessionOnAppResume() async
}

// MARK: - Authentication Store

/// Observable authentication store for Anchor app
///
/// Manages authentication state and coordinates with Anchor auth service.
/// Provides observable authentication state for UI binding.
///
/// Responsibilities:
/// - Observable authentication state for UI
/// - Secure OAuth authentication flow coordination (PKCE-protected)
/// - Session management and credential refresh
/// - Simplified app-facing authentication interface
@Observable
public final class AuthStore: AuthStoreProtocol {
    // MARK: - Properties

    private let authService: AnchorAuthServiceProtocol
    private let storage: CredentialsStorageProtocol
    private let ironSessionCoordinator: IronSessionMobileOAuthCoordinator

    /// Current authentication state (observable for UI)
    public private(set) var authenticationState: AuthenticationState = .unauthenticated

    /// Whether the user is currently authenticated (convenience property)
    public var isAuthenticated: Bool {
        authenticationState.isAuthenticated
    }

    /// Current authentication credentials
    public var credentials: AuthCredentials? {
        authenticationState.credentials
    }

    /// Current user handle (convenience property)
    public var handle: String? {
        credentials?.handle
    }

    // MARK: - Initialization

    /// Convenience initializer for production use with Keychain storage
    public convenience init() {
        let storage = KeychainCredentialsStorage()
        let authService = AnchorAuthService(storage: storage)
        let ironSessionCoordinator = IronSessionMobileOAuthCoordinator(credentialsStorage: storage)
        self.init(storage: storage, authService: authService, ironSessionCoordinator: ironSessionCoordinator)
    }

    /// Convenience initializer for testing with custom storage
    public convenience init(storage: CredentialsStorageProtocol) {
        let authService = AnchorAuthService(storage: storage)
        let ironSessionCoordinator = IronSessionMobileOAuthCoordinator(credentialsStorage: storage)
        self.init(storage: storage, authService: authService, ironSessionCoordinator: ironSessionCoordinator)
    }

    /// Dependency injection initializer  
    public init(
        storage: CredentialsStorageProtocol,
        authService: AnchorAuthServiceProtocol,
        ironSessionCoordinator: IronSessionMobileOAuthCoordinator
    ) {
        self.storage = storage
        self.authService = authService
        self.ironSessionCoordinator = ironSessionCoordinator
    }

    // MARK: - Secure Authentication Methods

    public func loadStoredCredentials() async -> AuthCredentials? {
        print("🔑 AuthStore: Loading stored credentials...")
        let loadedCredentials = await storage.load()

        guard let credentials = loadedCredentials else {
            print("🔑 AuthStore: No stored credentials found")
            updateAuthenticationState(with: nil)
            return nil
        }

        print("🔑 AuthStore: Loaded stored credentials for @\(credentials.handle)")
        print("🔑 AuthStore: Loaded credentials DID: \(credentials.did)")
        print("🔑 AuthStore: Loaded credentials session ID present: \(credentials.sessionId != nil)")

        updateAuthenticationState(with: credentials)
        return credentials
    }

    /// Start direct OAuth flow without handle input
    /// 
    /// Opens OAuth flow directly on Bluesky where user enters their handle and password.
    /// Uses Iron Session backend for simplified mobile authentication.
    ///
    /// - Returns: OAuth URL for WebView navigation
    /// - Throws: OAuth errors if flow initialization fails
    public func startDirectOAuthFlow() async throws -> URL {
        print("🔐 AuthStore: Starting direct OAuth flow")

        do {
            // Start OAuth without requiring handle upfront - backend will handle OAuth discovery
            let oauthURL = try await ironSessionCoordinator.startDirectOAuthFlow()
            print("✅ AuthStore: Direct OAuth flow started successfully")
            return oauthURL

        } catch {
            print("❌ AuthStore: Failed to start direct authentication: \(error.localizedDescription)")
            throw error
        }
    }

    /// Handle secure OAuth callback with Iron Session
    /// 
    /// - Parameter callbackURL: OAuth callback URL from WebView
    /// - Returns: True if authentication successful
    /// - Throws: OAuth errors if token exchange fails
    public func handleSecureOAuthCallback(_ callbackURL: URL) async throws -> Bool {
        print("🔐 AuthStore: Handling Iron Session OAuth callback")
        setAuthenticating()

        do {
            let credentials = try await ironSessionCoordinator.completeIronSessionOAuthFlow(callbackURL: callbackURL)
            print("🔐 AuthStore: Iron Session OAuth flow completed successfully")

            // Cast to AuthCredentials for storage
            guard let authCredentials = credentials as? AuthCredentials else {
                print("❌ AuthStore: Failed to cast credentials to AuthCredentials")
                setError(.invalidCredentials("Failed to process authentication response"))
                throw AuthStoreError.authenticationFailed
            }

            updateAuthenticationState(with: authCredentials)

            print("✅ AuthStore: Iron Session authentication completed successfully")
            print("✅ AuthStore: Authentication state updated - isAuthenticated: \(isAuthenticated)")

            return true

        } catch {
            print("❌ AuthStore: Iron Session OAuth callback failed: \(error)")
            setError(.networkError(error.localizedDescription))
            throw error
        }
    }

    // MARK: - Session Management

    public func signOut() async {
        print("🔓 AuthStore: Signing out...")

        updateAuthenticationState(with: nil)

        do {
            try await storage.clear()
            print("✅ AuthStore: Sign out completed successfully")
        } catch {
            print("⚠️ AuthStore: Failed to clear stored credentials during sign out: \(error)")
        }
    }

    public func getValidCredentials() async throws -> AuthCredentialsProtocol {
        print("🔑 AuthStore: Getting valid credentials...")

        // Check if we have loaded credentials
        guard let credentials = authenticationState.credentials else {
            print("❌ AuthStore: No credentials loaded")
            throw AuthStoreError.notAuthenticated
        }

        // Check if credentials are still valid
        guard credentials.isValid else {
            print("🔄 AuthStore: Credentials expired, attempting refresh...")
            return try await refreshExpiredCredentials(credentials)
        }

        print("✅ AuthStore: Returning valid credentials for @\(credentials.handle)")
        return credentials
    }

    public func validateSessionOnAppLaunch() async {
        print("🔍 AuthStore: Validating session on app launch...")

        guard let credentials = authenticationState.credentials else {
            print("🔍 AuthStore: No credentials to validate on launch")
            return
        }

        await validateSessionInternal(credentials, reason: "app launch")
    }

    public func validateSessionOnAppResume() async {
        print("🔍 AuthStore: Validating session on app resume...")

        guard let credentials = authenticationState.credentials else {
            print("🔍 AuthStore: No credentials to validate on resume")
            return
        }

        await validateSessionInternal(credentials, reason: "app resume")
    }

    // MARK: - Private Methods

    private func refreshExpiredCredentials(_ credentials: AuthCredentials) async throws -> AuthCredentials {
        print("🔄 AuthStore: Refreshing expired credentials...")
        setRefreshing()

        do {
            let refreshedCredentials = try await authService.refreshTokens(credentials)
            updateAuthenticationState(with: refreshedCredentials)
            print("✅ AuthStore: Credentials refreshed successfully")
            return refreshedCredentials
        } catch {
            print("❌ AuthStore: Failed to refresh credentials: \(error)")
            setError(.sessionExpiredUnrecoverable)
            await signOut()
            throw AuthStoreError.sessionExpired
        }
    }

    private func validateSessionInternal(_ credentials: AuthCredentials, reason: String) async {
        do {
            print("🔍 AuthStore: Validating session for \(reason)...")
            let validatedCredentials = try await authService.validateSession(credentials)
            updateAuthenticationState(with: validatedCredentials)
            print("✅ AuthStore: Session validation successful for \(reason)")
        } catch {
            print("❌ AuthStore: Session validation failed for \(reason): \(error)")
            await attemptTokenRefresh(credentials, reason: reason)
        }
    }

    private func attemptTokenRefresh(_ credentials: AuthCredentials, reason: String) async {
        print("🔄 AuthStore: Attempting token refresh as fallback for \(reason)...")
        setRefreshing()

        do {
            let refreshedCredentials = try await authService.refreshTokens(credentials)
            updateAuthenticationState(with: refreshedCredentials)
            print("✅ AuthStore: Token refresh successful as fallback for \(reason)")
        } catch {
            print("❌ AuthStore: Token refresh failed for \(reason): \(error)")
            setError(.sessionExpiredUnrecoverable)
            await signOut()
        }
    }

    private func shouldValidateSession(_ credentials: AuthCredentials) -> Bool {
        // In a real app, you'd track the last validation time
        // For now, validate if tokens are close to expiring
        return authService.shouldRefreshTokens(credentials)
    }

    /// Update authentication state based on current credentials
    private func updateAuthenticationState(with credentials: AuthCredentials?) {
        if let creds = credentials {
            if creds.isValid {
                authenticationState = .authenticated(credentials: creds)

                // Save valid credentials
                Task {
                    do {
                        try await storage.save(creds)
                    } catch {
                        print("⚠️ AuthStore: Failed to save credentials: \(error)")
                    }
                }
            } else if creds.isExpired {
                authenticationState = .sessionExpired(credentials: creds)
            }
        } else {
            authenticationState = .unauthenticated
        }
    }

    /// Set state to authenticating
    private func setAuthenticating() {
        authenticationState = .authenticating
    }

    /// Set state to refreshing with current credentials
    private func setRefreshing() {
        if let creds = authenticationState.credentials {
            authenticationState = .refreshing(credentials: creds)
        }
    }

    /// Set error state
    private func setError(_ error: AuthenticationError) {
        authenticationState = .error(error)
    }
}

// MARK: - Authentication Store Errors

public enum AuthStoreError: Error, LocalizedError {
    case notAuthenticated
    case authenticationFailed
    case sessionExpired

    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .authenticationFailed:
            return "Authentication failed"
        case .sessionExpired:
            return "Session has expired"
        }
    }
}
