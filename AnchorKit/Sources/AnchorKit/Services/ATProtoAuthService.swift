import Foundation

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
                expiresAt: Date().addingTimeInterval(expirationInterval),
                appPassword: appPassword // Store app password for automatic re-authentication
            )

            // Store credentials in memory and persistent storage
            _credentials = newCredentials
            try await storage.save(newCredentials)

            print("✅ Successfully authenticated as @\(newCredentials.handle) on \(targetPDS) " +
                  "(expires in \(expirationInterval / 60) minutes)")
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
                expiresAt: Date().addingTimeInterval(expirationInterval),
                appPassword: credentials.appPassword // Preserve stored app password
            )

            // Update stored credentials in memory and persistent storage
            _credentials = newCredentials
            try await storage.save(newCredentials)

            print("✅ Successfully refreshed credentials for @\(newCredentials.handle) on \(credentials.pdsURL) " +
                  "(expires in \(expirationInterval / 60) minutes)")
            return newCredentials

        } catch {
            print("❌ Failed to refresh credentials on \(credentials.pdsURL): \(error)")

            // If refresh failed and we have the app password, try full re-authentication
            if let appPassword = credentials.appPassword {
                print("🔄 Refresh failed, attempting full re-authentication with stored app password...")
                do {
                    let newCredentials = try await authenticate(
                        handle: credentials.handle,
                        appPassword: appPassword,
                        pdsURL: credentials.pdsURL
                    )
                    print("✅ Successfully re-authenticated after refresh failure")
                    return newCredentials
                } catch {
                    print("❌ Full re-authentication also failed: \(error)")
                    // Fall through to original error handling
                }
            }

            if let atProtoError = error as? ATProtoError {
                throw atProtoError
            } else {
                throw ATProtoError.authenticationFailed(error.localizedDescription)
            }
        }
    }

    public func loadStoredCredentials() async -> AuthCredentials? {
        print("🔑 ATProtoAuthService: Loading stored credentials...")
        let loadedCredentials = await storage.load()

        guard let credentials = loadedCredentials else {
            print("🔑 ATProtoAuthService: No stored credentials found")
            _credentials = nil
            return nil
        }

        print("🔑 ATProtoAuthService: Loaded stored credentials for @\(credentials.handle) (PDS: \(credentials.pdsURL))")
        print("🔑 ATProtoAuthService: Loaded credentials DID: \(credentials.did)")
        print("🔑 ATProtoAuthService: Loaded credentials session ID present: \(credentials.sessionId != nil)")
        if let sessionId = credentials.sessionId {
            print("🔑 ATProtoAuthService: Loaded session ID: \(sessionId.prefix(8))...")
        } else {
            print("🔑 ATProtoAuthService: No session ID in loaded credentials")
        }

        // If credentials are expired, try to refresh them automatically
        if credentials.isExpired {
            print("🔄 Credentials are expired, attempting automatic refresh...")
            do {
                let refreshedCredentials = try await refreshCredentials(credentials)
                _credentials = refreshedCredentials
                print("✅ Successfully refreshed expired credentials for @\(refreshedCredentials.handle)")
                return refreshedCredentials
            } catch {
                print("❌ Failed to refresh expired credentials: \(error)")
                // Clear the expired credentials that can't be refreshed
                try? await storage.clear()
                _credentials = nil
                return nil
            }
        } else {
            // Credentials are still valid
            _credentials = credentials
            return credentials
        }
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
                expiresAt: Date().addingTimeInterval(expirationInterval),
                appPassword: appPassword // Store app password for automatic re-authentication
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
