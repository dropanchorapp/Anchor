import Foundation

// MARK: - Authentication Store Protocol

@MainActor
public protocol AuthStoreProtocol {
    var isAuthenticated: Bool { get }
    var credentials: AuthCredentials? { get }
    var handle: String? { get }
    func loadStoredCredentials() async -> AuthCredentials?
    func authenticate(handle: String, appPassword: String) async throws -> Bool
    func authenticate(handle: String, appPassword: String, pdsURL: String?) async throws -> Bool
    func signOut() async
    func getAppPasswordURL() -> URL
    func getValidCredentials() async throws -> AuthCredentialsProtocol
}

// MARK: - Authentication Store

/// Observable authentication store for Anchor app
///
/// Manages authentication state and coordinates with AT Protocol services.
/// Provides observable authentication state for UI binding.
///
/// Responsibilities:
/// - Observable authentication state for UI
/// - Coordinate login/logout operations
/// - Session management and credential refresh
/// - Simplified app-facing authentication interface
@Observable
public final class AuthStore: AuthStoreProtocol {
    // MARK: - Properties

    private let authService: ATProtoAuthServiceProtocol

    /// Whether the user is currently authenticated (observable for UI)
    public private(set) var isAuthenticated: Bool = false

    /// Current authentication credentials
    public var credentials: AuthCredentials? {
        authService.credentials
    }

    /// Current user handle (convenience property)
    public var handle: String? {
        credentials?.handle
    }

    // MARK: - Initialization

    /// Convenience initializer for production use with Keychain storage
    public convenience init(session: URLSessionProtocol = URLSession.shared) {
        let client = ATProtoClient(session: session)
        let storage = KeychainCredentialsStorage()
        let authService = ATProtoAuthService(client: client, storage: storage)
        self.init(authService: authService)
    }

    /// Convenience initializer for testing with custom storage
    public convenience init(session: URLSessionProtocol = URLSession.shared, storage: CredentialsStorageProtocol) {
        let client = ATProtoClient(session: session)
        let authService = ATProtoAuthService(client: client, storage: storage)
        self.init(authService: authService)
    }

    /// Dependency injection initializer
    public init(authService: ATProtoAuthServiceProtocol) {
        self.authService = authService
        // Load credentials immediately on initialization
        Task { @MainActor in
            await loadStoredCredentials()
        }
    }

    // MARK: - Authentication Methods

    public func loadStoredCredentials() async -> AuthCredentials? {
        let result = await authService.loadStoredCredentials()
        updateAuthenticationState()
        return result
    }

    public func authenticate(handle: String, appPassword: String) async throws -> Bool {
        return try await authenticate(handle: handle, appPassword: appPassword, pdsURL: nil)
    }

    public func authenticate(handle: String, appPassword: String, pdsURL: String?) async throws -> Bool {
        _ = try await authService.authenticate(handle: handle, appPassword: appPassword, pdsURL: pdsURL)
        updateAuthenticationState()
        return true
    }

    public func signOut() async {
        await authService.clearCredentials()
        updateAuthenticationState()
    }

    public func getAppPasswordURL() -> URL {
        URL(string: "https://bsky.app/settings/app-passwords")!
    }

    // MARK: - Internal Methods

    /// Get current credentials, refreshing if expired (for other services to use)
    public func getValidCredentials() async throws -> AuthCredentialsProtocol {
        guard let credentials = authService.credentials else {
            throw ATProtoError.missingCredentials
        }

        if credentials.isExpired {
            return try await authService.refreshCredentials(credentials)
        }

        return credentials
    }

    // MARK: - Private Methods

    /// Updates the observable authentication state for UI binding
    @MainActor
    private func updateAuthenticationState() {
        isAuthenticated = authService.credentials?.isValid ?? false
        print("🔄 AuthStore: Updated authentication state - isAuthenticated: \(isAuthenticated)")
    }
}
