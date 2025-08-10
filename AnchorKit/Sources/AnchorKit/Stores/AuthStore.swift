import Foundation

// MARK: - Authentication Store Protocol

@MainActor
public protocol AuthStoreProtocol {
    var isAuthenticated: Bool { get }
    var credentials: AuthCredentials? { get }
    var handle: String? { get }
    func loadStoredCredentials() async -> AuthCredentials?
    func authenticateWithOAuth(_ authData: OAuthAuthenticationData) async throws -> Bool
    func signOut() async
    func getValidCredentials() async throws -> AuthCredentialsProtocol
}

// MARK: - Authentication Store

/// Observable authentication store for Anchor app
///
/// Manages authentication state and coordinates with OAuth authentication service.
/// Provides observable authentication state for UI binding.
///
/// Responsibilities:
/// - Observable authentication state for UI
/// - OAuth authentication flow coordination
/// - Session management and credential refresh
/// - Simplified app-facing authentication interface
@Observable
public final class AuthStore: AuthStoreProtocol {
    // MARK: - Properties

    private let oauthService: OAuthServiceProtocol
    private let storage: CredentialsStorageProtocol

    /// Whether the user is currently authenticated (observable for UI)
    public private(set) var isAuthenticated: Bool = false

    /// Current authentication credentials (backing storage)
    @MainActor
    private var _credentials: AuthCredentials?

    /// Current authentication credentials
    public var credentials: AuthCredentials? {
        _credentials
    }

    /// Current user handle (convenience property)
    public var handle: String? {
        credentials?.handle
    }

    // MARK: - Initialization

    /// Convenience initializer for production use with Keychain storage
    public convenience init() {
        let storage = KeychainCredentialsStorage()
        let oauthService = OAuthService(storage: storage)
        self.init(storage: storage, oauthService: oauthService)
    }

    /// Convenience initializer for testing with custom storage
    public convenience init(storage: CredentialsStorageProtocol) {
        let oauthService = OAuthService(storage: storage)
        self.init(storage: storage, oauthService: oauthService)
    }

    /// Dependency injection initializer
    public init(storage: CredentialsStorageProtocol, oauthService: OAuthServiceProtocol) {
        self.storage = storage
        self.oauthService = oauthService
    }

    // MARK: - Authentication Methods

    public func loadStoredCredentials() async -> AuthCredentials? {
        print("🔑 AuthStore: Loading stored credentials...")
        let loadedCredentials = await storage.load()
        
        guard let credentials = loadedCredentials else {
            print("🔑 AuthStore: No stored credentials found")
            _credentials = nil
            updateAuthenticationState()
            return nil
        }
        
        print("🔑 AuthStore: Loaded stored credentials for @\(credentials.handle)")
        print("🔑 AuthStore: Loaded credentials DID: \(credentials.did)")
        print("🔑 AuthStore: Loaded credentials session ID present: \(credentials.sessionId != nil)")
        
        _credentials = credentials
        updateAuthenticationState()
        return credentials
    }
    
    public func authenticateWithOAuth(_ authData: OAuthAuthenticationData) async throws -> Bool {
        let credentials = try await oauthService.processOAuthAuthentication(authData)
        _credentials = credentials as? AuthCredentials
        updateAuthenticationState()
        return true
    }

    public func signOut() async {
        print("🗑️ AuthStore: Signing out...")
        try? await storage.clear()
        _credentials = nil
        updateAuthenticationState()
        print("✅ AuthStore: Signed out successfully")
    }

    // MARK: - Internal Methods

    /// Get current credentials (for other services to use)
    /// Note: OAuth tokens are handled by the backend, so no client-side refresh needed
    public func getValidCredentials() async throws -> AuthCredentialsProtocol {
        print("🔑 AuthStore: Getting valid credentials...")
        
        guard let credentials = _credentials else {
            print("❌ AuthStore: No credentials found")
            throw AuthStoreError.missingCredentials
        }
        
        print("🔑 AuthStore: Found credentials for handle: \(credentials.handle)")
        print("🔑 AuthStore: DID: \(credentials.did)")
        print("🔑 AuthStore: Session ID present: \(credentials.sessionId != nil)")
        if let sessionId = credentials.sessionId {
            print("🔑 AuthStore: Session ID: \(sessionId.prefix(8))...")
        }
        
        print("✅ AuthStore: Returning valid credentials")
        return credentials
    }

    // MARK: - Private Methods

    /// Updates the observable authentication state for UI binding
    @MainActor
    private func updateAuthenticationState() {
        isAuthenticated = _credentials?.isValid ?? false
        print("🔄 AuthStore: Updated authentication state - isAuthenticated: \(isAuthenticated)")
    }
}

// MARK: - Auth Store Errors

/// Errors that can occur in AuthStore operations
public enum AuthStoreError: Error, LocalizedError {
    case missingCredentials
    case authenticationFailed
    
    public var errorDescription: String? {
        switch self {
        case .missingCredentials:
            return "No authentication credentials found"
        case .authenticationFailed:
            return "Authentication failed"
        }
    }
}
