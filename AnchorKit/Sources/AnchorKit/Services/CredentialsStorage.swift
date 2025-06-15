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
        // Clear any existing credentials first
        try await clear()
        
        // Insert the new credentials
        context.insert(credentials)
        try context.save()
    }

    public func load() async -> AuthCredentials? {
        let descriptor = FetchDescriptor<AuthCredentials>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            let allCredentials = try context.fetch(descriptor)
            print("🔍 Found \(allCredentials.count) stored credentials")

            guard let credentials = allCredentials.first else {
                print("🔍 No credentials found in database")
                return nil
            }

            print("🔍 Checking credentials for @\(credentials.handle), expires: \(credentials.expiresAt), valid: \(credentials.isValid)")

            // Check if credentials are still valid
            if credentials.isValid {
                return credentials
            } else {
                print("🔍 Credentials expired, cleaning up")
                // Clean up invalid credentials
                try? await clear()
                return nil
            }
        } catch {
            print("🔍 Error fetching credentials: \(error)")
            return nil
        }
    }

    public func clear() async throws {
        let descriptor = FetchDescriptor<AuthCredentials>()
        let credentials = try context.fetch(descriptor)

        for credential in credentials {
            context.delete(credential)
        }

        try context.save()
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
