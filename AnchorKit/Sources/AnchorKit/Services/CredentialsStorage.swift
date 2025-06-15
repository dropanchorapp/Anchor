import Foundation
import SwiftData

// MARK: - Credentials Storage Protocol

/// Protocol for abstracting credential storage, enabling dependency injection and testing
@MainActor
public protocol CredentialsStorageProtocol {
    func save(_ credentials: AuthCredentials) async throws
    func load() async -> AuthCredentials?
    func clear() async throws
}

// MARK: - SwiftData Implementation

/// Production implementation using SwiftData for persistent storage
@MainActor
public final class SwiftDataCredentialsStorage: CredentialsStorageProtocol {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func save(_ credentials: AuthCredentials) async throws {
        try AuthCredentials.save(credentials, to: context)
    }

    public func load() async -> AuthCredentials? {
        AuthCredentials.current(from: context)
    }

    public func clear() async throws {
        try AuthCredentials.clearAll(from: context)
    }
}

// MARK: - In-Memory Implementation

/// Test implementation using in-memory storage
@MainActor
public final class InMemoryCredentialsStorage: CredentialsStorageProtocol {
    private var credentials: AuthCredentials?

    public init() {}

    public func save(_ credentials: AuthCredentials) async throws {
        self.credentials = credentials
    }

    public func load() async -> AuthCredentials? {
        credentials
    }

    public func clear() async throws {
        credentials = nil
    }
}
