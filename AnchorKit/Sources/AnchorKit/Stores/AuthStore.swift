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
    private let sessionValidator: SessionValidator
    private let logger: Logger

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
        let logger = DebugLogger()
        let authService = AnchorAuthService(storage: storage)
        let ironSessionCoordinator = IronSessionMobileOAuthCoordinator(credentialsStorage: storage, logger: logger)
        let sessionValidator = SessionValidator(authService: authService, logger: logger)
        self.init(storage: storage, authService: authService, ironSessionCoordinator: ironSessionCoordinator, sessionValidator: sessionValidator, logger: logger)
    }

    /// Convenience initializer for testing with custom storage
    public convenience init(storage: CredentialsStorageProtocol) {
        let logger = DebugLogger()
        let authService = AnchorAuthService(storage: storage)
        let ironSessionCoordinator = IronSessionMobileOAuthCoordinator(credentialsStorage: storage, logger: logger)
        let sessionValidator = SessionValidator(authService: authService, logger: logger)
        self.init(storage: storage, authService: authService, ironSessionCoordinator: ironSessionCoordinator, sessionValidator: sessionValidator, logger: logger)
    }

    /// Dependency injection initializer
    public init(
        storage: CredentialsStorageProtocol,
        authService: AnchorAuthServiceProtocol,
        ironSessionCoordinator: IronSessionMobileOAuthCoordinator,
        sessionValidator: SessionValidator,
        logger: Logger = DebugLogger()
    ) {
        self.storage = storage
        self.authService = authService
        self.ironSessionCoordinator = ironSessionCoordinator
        self.sessionValidator = sessionValidator
        self.logger = logger
    }

    // MARK: - Secure Authentication Methods

    public func loadStoredCredentials() async -> AuthCredentials? {
        logger.log("🔑 Loading stored credentials...", level: .debug, category: .auth)
        let loadedCredentials = await storage.load()

        guard let credentials = loadedCredentials else {
            logger.log("🔑 No stored credentials found", level: .info, category: .auth)
            updateAuthenticationState(with: nil)
            return nil
        }

        logger.log("🔑 Loaded stored credentials for @\(credentials.handle)", level: .info, category: .auth)
        logger.log("🔑 Loaded credentials DID: \(credentials.did)", level: .debug, category: .auth)
        logger.log("🔑 Loaded credentials session ID present: \(credentials.sessionId != nil)", level: .debug, category: .auth)

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
        logger.log("🔐 Starting direct OAuth flow", level: .info, category: .oauth)

        // Clear any existing error state and old session for fresh authentication
        if case .error = authenticationState {
            logger.log("🧹 Clearing error state before new OAuth flow", level: .info, category: .oauth)
            await signOut()
        }

        do {
            // Start OAuth without requiring handle upfront - backend will handle OAuth discovery
            let oauthURL = try await ironSessionCoordinator.startDirectOAuthFlow()
            logger.log("✅ Direct OAuth flow started successfully", level: .info, category: .oauth)
            return oauthURL

        } catch {
            logger.log("❌ Failed to start direct authentication: \(error.localizedDescription)", level: .error, category: .oauth)
            throw error
        }
    }

    /// Handle secure OAuth callback with Iron Session
    /// 
    /// - Parameter callbackURL: OAuth callback URL from WebView
    /// - Returns: True if authentication successful
    /// - Throws: OAuth errors if token exchange fails
    public func handleSecureOAuthCallback(_ callbackURL: URL) async throws -> Bool {
        logger.log("🔐 Handling Iron Session OAuth callback", level: .info, category: .oauth)
        setAuthenticating()

        do {
            let credentials = try await ironSessionCoordinator.completeIronSessionOAuthFlow(callbackURL: callbackURL)
            logger.log("🔐 Iron Session OAuth flow completed successfully", level: .info, category: .oauth)

            // Cast to AuthCredentials for storage
            guard let authCredentials = credentials as? AuthCredentials else {
                logger.log("❌ Failed to cast credentials to AuthCredentials", level: .error, category: .oauth)
                let error = AuthenticationError.invalidCredentials("Failed to process authentication response")
                setError(error)
                throw error
            }

            updateAuthenticationState(with: authCredentials)

            logger.log("✅ Iron Session authentication completed successfully", level: .info, category: .oauth)
            logger.log("✅ Authentication state updated - isAuthenticated: \(isAuthenticated)", level: .debug, category: .oauth)

            return true

        } catch {
            logger.log("❌ Iron Session OAuth callback failed: \(error)", level: .error, category: .oauth)
            setError(.networkError(error.localizedDescription))
            throw error
        }
    }

    // MARK: - Session Management

    public func signOut() async {
        logger.log("🔓 Signing out...", level: .info, category: .auth)

        updateAuthenticationState(with: nil)

        do {
            try await storage.clear()
            logger.log("✅ Sign out completed successfully", level: .info, category: .auth)
        } catch {
            logger.log("⚠️ Failed to clear stored credentials during sign out: \(error)", level: .warning, category: .auth)
        }
    }

    public func getValidCredentials() async throws -> AuthCredentialsProtocol {
        logger.log("🔑 Getting valid credentials...", level: .debug, category: .auth)

        // Check if we have loaded credentials
        guard let credentials = authenticationState.credentials else {
            logger.log("❌ No credentials loaded", level: .error, category: .auth)
            throw AuthenticationError.invalidCredentials("No credentials loaded")
        }

        // Check if credentials are still valid
        guard credentials.isValid else {
            logger.log("🔄 Credentials expired, attempting refresh...", level: .info, category: .auth)
            return try await refreshExpiredCredentials(credentials)
        }

        logger.log("✅ Returning valid credentials for @\(credentials.handle)", level: .debug, category: .auth)
        return credentials
    }

    public func validateSessionOnAppLaunch() async {
        logger.log("🔍 Validating session on app launch...", level: .info, category: .session)

        guard let credentials = authenticationState.credentials else {
            logger.log("🔍 No credentials to validate on launch", level: .debug, category: .session)
            return
        }

        await validateSession(credentials, reason: "app launch")
    }

    public func validateSessionOnAppResume() async {
        logger.log("🔍 Validating session on app resume...", level: .info, category: .session)

        guard let credentials = authenticationState.credentials else {
            logger.log("🔍 No credentials to validate on resume", level: .debug, category: .session)
            return
        }

        await validateSession(credentials, reason: "app resume")
    }

    // MARK: - Private Methods

    /// Refresh expired credentials using SessionValidator
    private func refreshExpiredCredentials(_ credentials: AuthCredentials) async throws -> AuthCredentials {
        logger.log("🔄 Refreshing expired credentials...", level: .info, category: .session)

        do {
            let refreshedCredentials = try await sessionValidator.refreshCredentials(credentials) { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .refreshing:
                    self.setRefreshing()
                case .refreshFailed:
                    self.setError(.sessionExpiredUnrecoverable)
                }
            }
            updateAuthenticationState(with: refreshedCredentials)
            logger.log("✅ Credentials refreshed successfully", level: .info, category: .session)
            return refreshedCredentials
        } catch {
            logger.log("❌ Failed to refresh credentials: \(error)", level: .error, category: .session)

            // Map error and set error state - don't auto sign-out
            // Let UI decide appropriate recovery action based on error.isRecoverable
            let authError = mapToAuthenticationError(error)
            setError(authError)
            throw authError
        }
    }

    /// Validate session using SessionValidator
    private func validateSession(_ credentials: AuthCredentials, reason: String) async {
        let validatedCredentials = await sessionValidator.validateSession(credentials, reason: reason) { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .refreshing:
                self.setRefreshing()
            case .refreshFailed:
                self.setError(.sessionExpiredUnrecoverable)
            }
        }

        if let validatedCredentials = validatedCredentials {
            updateAuthenticationState(with: validatedCredentials)
        } else {
            // Validation and refresh both failed - set error state
            // Don't auto sign-out - let UI provide appropriate recovery actions
            setError(.sessionExpiredUnrecoverable)
        }
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
                        logger.log("⚠️ Failed to save credentials: \(error)", level: .warning, category: .auth)
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

    /// Map generic errors to appropriate AuthenticationError types
    private func mapToAuthenticationError(_ error: Error) -> AuthenticationError {
        // If it's already an AuthenticationError, return it
        if let authError = error as? AuthenticationError {
            return authError
        }

        // Check for network errors
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return .networkError(error.localizedDescription)
        }

        // Default to unrecoverable session error if we don't know the type
        return .sessionExpiredUnrecoverable
    }
}
