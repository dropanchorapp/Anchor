import Foundation
import SwiftData

// MARK: - AT Protocol Authentication Service Protocol

@MainActor
public protocol ATProtoAuthServiceProtocol {
    var isAuthenticated: Bool { get async }
    var credentials: AuthCredentials? { get }
    func authenticate(handle: String, appPassword: String, context: ModelContext) async throws -> AuthCredentials
    func refreshCredentials(_ credentials: AuthCredentials, context: ModelContext) async throws -> AuthCredentials  
    func loadStoredCredentials(from context: ModelContext) async -> AuthCredentials?
    func clearCredentials(from context: ModelContext) async
}

// MARK: - AT Protocol Authentication Service

@Observable
public final class ATProtoAuthService: ATProtoAuthServiceProtocol {
    
    // MARK: - Properties
    
    private let client: ATProtoClientProtocol
    
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
        return _credentials
    }
    
    // MARK: - Initialization
    
    public init(client: ATProtoClientProtocol) {
        self.client = client
    }
    
    // MARK: - Authentication Methods
    
    public func authenticate(handle: String, appPassword: String, context: ModelContext) async throws -> AuthCredentials {
        let request = ATProtoLoginRequest(identifier: handle, password: appPassword)
        
        do {
            let response = try await client.login(request: request)
            
            let newCredentials = AuthCredentials(
                handle: response.handle,
                accessToken: response.accessJwt,
                refreshToken: response.refreshJwt,
                did: response.did,
                expiresAt: Date().addingTimeInterval(24 * 60 * 60) // 24 hours
            )
            
            // Store credentials
            await MainActor.run {
                self._credentials = newCredentials
            }
            
            try AuthCredentials.save(newCredentials, to: context)
            
            print("✅ Successfully authenticated as @\(newCredentials.handle)")
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
    
    public func refreshCredentials(_ credentials: AuthCredentials, context: ModelContext) async throws -> AuthCredentials {
        let request = ATProtoRefreshRequest(refreshJwt: credentials.refreshToken)
        
        do {
            let response = try await client.refresh(request: request)
            
            let newCredentials = AuthCredentials(
                handle: credentials.handle,
                accessToken: response.accessJwt,
                refreshToken: response.refreshJwt,
                did: credentials.did,
                expiresAt: Date().addingTimeInterval(24 * 60 * 60) // 24 hours
            )
            
            // Update stored credentials
            await MainActor.run {
                self._credentials = newCredentials
            }
            
            try AuthCredentials.save(newCredentials, to: context)
            
            print("✅ Successfully refreshed credentials for @\(newCredentials.handle)")
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
    
    public func loadStoredCredentials(from context: ModelContext) async -> AuthCredentials? {
        let loadedCredentials = AuthCredentials.current(from: context)
        await MainActor.run {
            self._credentials = loadedCredentials
        }
        
        if let credentials = loadedCredentials {
            print("🔑 Loaded stored credentials for @\(credentials.handle)")
        } else {
            print("🔑 No stored credentials found")
        }
        
        return loadedCredentials
    }
    
    public func clearCredentials(from context: ModelContext) async {
        let hasCredentials = await MainActor.run { _credentials != nil }
        if hasCredentials {
            try? AuthCredentials.clearAll(from: context)
        }
        await MainActor.run {
            _credentials = nil
        }
        print("🗑️ Cleared stored credentials")
    }
}