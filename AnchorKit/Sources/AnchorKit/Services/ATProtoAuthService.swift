import Foundation
import SwiftData

// MARK: - AT Protocol Authentication Service Protocol

@MainActor
public protocol ATProtoAuthServiceProtocol {
    var isAuthenticated: Bool { get async }
    var credentials: AuthCredentials? { get }
    func authenticate(handle: String, appPassword: String) async throws -> AuthCredentials
    func authenticate(handle: String, appPassword: String, pdsURL: String?) async throws -> AuthCredentials
    func refreshCredentials(_ credentials: AuthCredentialsProtocol) async throws -> AuthCredentials
    func loadStoredCredentials() async -> AuthCredentials?
    func clearCredentials() async
}

// MARK: - AT Protocol Authentication Service

public final class ATProtoAuthService: ATProtoAuthServiceProtocol {
    // MARK: - Properties

    private let client: ATProtoClientProtocol
    private let storage: CredentialsStorageProtocol

    /// Current authentication credentials (backing storage)
    @MainActor
    private var _credentials: AuthCredentials?

    /// Whether the user is currently authenticated
    public var isAuthenticated: Bool {
        get async {
            await MainActor.run { _credentials?.isValid ?? false }
        }
    }

    /// Current authentication credentials (MainActor-bound)
    @MainActor
    public var credentials: AuthCredentials? {
        _credentials
    }

    // MARK: - Initialization

    public init(client: ATProtoClientProtocol, storage: CredentialsStorageProtocol) {
        self.client = client
        self.storage = storage
    }

    // MARK: - Authentication Methods

    /// Authenticate with automatic PDS discovery
    public func authenticate(handle: String, appPassword: String) async throws -> AuthCredentials {
        return try await authenticate(handle: handle, appPassword: appPassword, pdsURL: nil)
    }

    /// Authenticate with specific PDS or auto-discovery
    /// - Parameters:
    ///   - handle: User handle (e.g., "user.bsky.social")
    ///   - appPassword: Application password
    ///   - pdsURL: Optional specific PDS URL. If nil, will auto-discover from handle
    public func authenticate(handle: String, appPassword: String, pdsURL: String?) async throws -> AuthCredentials {
        // Determine PDS URL: use provided, discover from handle, or fallback to Bluesky
        let targetPDS = await determinePDS(for: handle, preferredPDS: pdsURL)
        
        print("🔐 Attempting authentication on PDS: \(targetPDS)")
        
        // Create a client for the target PDS
        let pdsClient = ATProtoClient(baseURL: targetPDS)
        
        let request = ATProtoLoginRequest(identifier: handle, password: appPassword)

        do {
            let response = try await pdsClient.login(request: request)

            // Use actual token expiration time from AT Protocol response
            // Default to 1 hour (3600 seconds) if not provided
            let expirationInterval = TimeInterval(response.expiresIn ?? 3600)

            let newCredentials = AuthCredentials(
                handle: response.handle,
                accessToken: response.accessJwt,
                refreshToken: response.refreshJwt,
                did: response.did,
                pdsURL: targetPDS, // Store the PDS that was used for authentication
                expiresAt: Date().addingTimeInterval(expirationInterval)
            )

            // Store credentials in memory and persistent storage
            _credentials = newCredentials
            try await storage.save(newCredentials)

            print("✅ Successfully authenticated as @\(newCredentials.handle) on \(targetPDS) (expires in \(expirationInterval / 60) minutes)")
            return newCredentials

        } catch {
            print("❌ Authentication failed on \(targetPDS): \(error)")
            
            // If we tried a custom PDS and it failed, try Bluesky as fallback
            if targetPDS != AnchorConfig.shared.blueskyPDSURL {
                print("🔄 Attempting fallback authentication on Bluesky PDS...")
                return try await authenticateWithFallback(handle: handle, appPassword: appPassword)
            }
            
            if let atProtoError = error as? ATProtoError {
                throw atProtoError
            } else {
                throw ATProtoError.authenticationFailed(error.localizedDescription)
            }
        }
    }

    public func refreshCredentials(_ credentials: AuthCredentialsProtocol) async throws -> AuthCredentials {
        // Use the same PDS that was used for original authentication
        let pdsClient = ATProtoClient(baseURL: credentials.pdsURL)
        let request = ATProtoRefreshRequest(refreshJwt: credentials.refreshToken)

        do {
            let response = try await pdsClient.refresh(request: request)

            // Use actual token expiration time from AT Protocol response
            // Default to 1 hour (3600 seconds) if not provided
            let expirationInterval = TimeInterval(response.expiresIn ?? 3600)

            let newCredentials = AuthCredentials(
                handle: credentials.handle,
                accessToken: response.accessJwt,
                refreshToken: response.refreshJwt,
                did: credentials.did,
                pdsURL: credentials.pdsURL, // Keep the same PDS
                expiresAt: Date().addingTimeInterval(expirationInterval)
            )

            // Update stored credentials in memory and persistent storage
            _credentials = newCredentials
            try await storage.save(newCredentials)

            print("✅ Successfully refreshed credentials for @\(newCredentials.handle) on \(credentials.pdsURL) (expires in \(expirationInterval / 60) minutes)")
            return newCredentials

        } catch {
            print("❌ Failed to refresh credentials on \(credentials.pdsURL): \(error)")
            if let atProtoError = error as? ATProtoError {
                throw atProtoError
            } else {
                throw ATProtoError.authenticationFailed(error.localizedDescription)
            }
        }
    }

    public func loadStoredCredentials() async -> AuthCredentials? {
        let loadedCredentials = await storage.load()
        _credentials = loadedCredentials

        if let credentials = loadedCredentials {
            print("🔑 Loaded stored credentials for @\(credentials.handle) (PDS: \(credentials.pdsURL))")
        } else {
            print("🔑 No stored credentials found")
        }

        return loadedCredentials
    }

    public func clearCredentials() async {
        if _credentials != nil {
            try? await storage.clear()
        }
        _credentials = nil
        print("🗑️ Cleared stored credentials")
    }
    
    // MARK: - Private Methods
    
    /// Determine which PDS to use for authentication
    private func determinePDS(for handle: String, preferredPDS: String?) async -> String {
        // 1. Use provided PDS if specified
        if let pds = preferredPDS, !pds.isEmpty {
            return pds
        }
        
        // 2. Try to discover from handle
        if let discoveredPDS = await PDSDiscovery.discoverPDS(for: handle) {
            return discoveredPDS
        }
        
        // 3. Guess from handle domain
        if let guessedPDS = PDSDiscovery.guessPDSFromHandle(handle) {
            return guessedPDS
        }
        
        // 4. Fallback to Bluesky
        return AnchorConfig.shared.blueskyPDSURL
    }
    
    /// Fallback authentication using Bluesky PDS
    private func authenticateWithFallback(handle: String, appPassword: String) async throws -> AuthCredentials {
        let blueskyClient = ATProtoClient(baseURL: AnchorConfig.shared.blueskyPDSURL)
        let request = ATProtoLoginRequest(identifier: handle, password: appPassword)

        do {
            let response = try await blueskyClient.login(request: request)
            let expirationInterval = TimeInterval(response.expiresIn ?? 3600)

            let newCredentials = AuthCredentials(
                handle: response.handle,
                accessToken: response.accessJwt,
                refreshToken: response.refreshJwt,
                did: response.did,
                pdsURL: AnchorConfig.shared.blueskyPDSURL,
                expiresAt: Date().addingTimeInterval(expirationInterval)
            )

            _credentials = newCredentials
            try await storage.save(newCredentials)

            print("✅ Fallback authentication successful on Bluesky PDS")
            return newCredentials

        } catch {
            print("❌ Fallback authentication also failed: \(error)")
            if let atProtoError = error as? ATProtoError {
                throw atProtoError
            } else {
                throw ATProtoError.authenticationFailed(error.localizedDescription)
            }
        }
    }
}
