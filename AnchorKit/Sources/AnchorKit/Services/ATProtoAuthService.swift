import Foundation
import SwiftData

// MARK: - AT Protocol Authentication Service Protocol

@MainActor
public protocol ATProtoAuthServiceProtocol {
    var isAuthenticated: Bool { get async }
    var credentials: AuthCredentials? { get }
    func authenticate(handle: String, appPassword: String) async throws -> AuthCredentials
    func refreshCredentials(_ credentials: AuthCredentials) async throws -> AuthCredentials
    func loadStoredCredentials() async -> AuthCredentials?
    func clearCredentials() async
}

// MARK: - AT Protocol Authentication Service

@Observable
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

    public func authenticate(handle: String, appPassword: String) async throws -> AuthCredentials {
        let request = ATProtoLoginRequest(identifier: handle, password: appPassword)

        do {
            let response = try await client.login(request: request)

            // Use actual token expiration time from AT Protocol response
            // Default to 1 hour (3600 seconds) if not provided
            let expirationInterval = TimeInterval(response.expiresIn ?? 3600)
            
            let newCredentials = AuthCredentials(
                handle: response.handle,
                accessToken: response.accessJwt,
                refreshToken: response.refreshJwt,
                did: response.did,
                expiresAt: Date().addingTimeInterval(expirationInterval)
            )

            // Store credentials in memory and persistent storage
            _credentials = newCredentials
            try await storage.save(newCredentials)

            print("✅ Successfully authenticated as @\(newCredentials.handle) (expires in \(expirationInterval / 60) minutes)")
            return newCredentials

        } catch {
            print("❌ Authentication failed: \(error)")
            if let atProtoError = error as? ATProtoError {
                throw atProtoError
            } else {
                throw ATProtoError.authenticationFailed(error.localizedDescription)
            }
        }
    }

    public func refreshCredentials(_ credentials: AuthCredentials) async throws -> AuthCredentials {
        let request = ATProtoRefreshRequest(refreshJwt: credentials.refreshToken)

        do {
            let response = try await client.refresh(request: request)

            // Use actual token expiration time from AT Protocol response
            // Default to 1 hour (3600 seconds) if not provided
            let expirationInterval = TimeInterval(response.expiresIn ?? 3600)

            let newCredentials = AuthCredentials(
                handle: credentials.handle,
                accessToken: response.accessJwt,
                refreshToken: response.refreshJwt,
                did: credentials.did,
                expiresAt: Date().addingTimeInterval(expirationInterval)
            )

            // Update stored credentials in memory and persistent storage
            _credentials = newCredentials
            try await storage.save(newCredentials)

            print("✅ Successfully refreshed credentials for @\(newCredentials.handle) (expires in \(expirationInterval / 60) minutes)")
            return newCredentials

        } catch {
            print("❌ Failed to refresh credentials: \(error)")
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
            print("🔑 Loaded stored credentials for @\(credentials.handle)")
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
}
