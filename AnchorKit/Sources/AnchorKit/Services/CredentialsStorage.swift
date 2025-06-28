import Foundation
import SwiftData
import Security

//
// MARK: - Credentials Storage
//
// This module provides multiple storage implementations for authentication credentials:
//
// 1. **KeychainCredentialsStorage** (RECOMMENDED)
//    - Uses iOS/macOS Keychain for secure, persistent storage
//    - Survives app rebuilds and updates
//    - Platform standard for authentication tokens
//    - Simple single source of truth
//
// 2. **SwiftDataCredentialsStorage** (Legacy)
//    - Hybrid approach using SwiftData + Keychain fallback
//    - More complex but provides fast access via SwiftData
//    - Maintained for backward compatibility
//
// 3. **InMemoryCredentialsStorage** (Testing)
//    - Memory-only storage for unit tests
//    - No persistence across app restarts
//
// For new implementations, use KeychainCredentialsStorage directly.
//

// MARK: - Credentials Storage Protocol

/// Protocol for abstracting credential storage, enabling dependency injection and testing
@MainActor
public protocol CredentialsStorageProtocol {
    func save(_ credentials: AuthCredentialsProtocol) async throws
    func load() async -> AuthCredentials?
    func clear() async throws
}

// MARK: - Keychain Implementation

/// Keychain-based implementation that persists across app rebuilds
@MainActor
public final class KeychainCredentialsStorage: CredentialsStorageProtocol {
    private let service: String
    private let account: String

    public init(service: String = "com.anchor.app.credentials", account: String = "bluesky-auth") {
        self.service = service
        self.account = account
    }

    public func save(_ credentials: AuthCredentialsProtocol) async throws {
        // Encode credentials to JSON
        let credentialsData = CredentialsData(
            handle: credentials.handle,
            accessToken: credentials.accessToken,
            refreshToken: credentials.refreshToken,
            did: credentials.did,
            pdsURL: credentials.pdsURL,
            expiresAt: credentials.expiresAt,
            createdAt: Date() // Use current time for created timestamp
        )

        let data = try JSONEncoder().encode(credentialsData)

        // Delete any existing keychain item
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new keychain item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw CredentialsStorageError.keychainError(status)
        }

        print("🔐 Saved credentials to keychain for @\(credentials.handle)")
    }

    public func load() async -> AuthCredentials? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data else {
            print("🔐 No credentials found in keychain")
            return nil
        }

        do {
            let credentialsData = try JSONDecoder().decode(CredentialsData.self, from: data)
            let credentials = AuthCredentials(
                handle: credentialsData.handle,
                accessToken: credentialsData.accessToken,
                refreshToken: credentialsData.refreshToken,
                did: credentialsData.did,
                pdsURL: credentialsData.pdsURL,
                expiresAt: credentialsData.expiresAt
            )

            print("🔐 Loaded credentials from keychain for @\(credentials.handle), expires: \(credentials.expiresAt), valid: \(credentials.isValid)")

            // Check if credentials are still valid
            if credentials.isValid {
                return credentials
            } else {
                print("🔐 Keychain credentials expired, cleaning up")
                try? await clear()
                return nil
            }
        } catch {
            print("🔐 Error decoding keychain credentials: \(error)")
            try? await clear()
            return nil
        }
    }

    public func clear() async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess {
            print("🔐 Cleared credentials from keychain")
        }
    }
}

// MARK: - SwiftData Implementation (Legacy)

/// Legacy implementation using SwiftData only - kept for backward compatibility
/// Note: Data will be lost on app rebuilds. Use KeychainCredentialsStorage for persistent storage.
@MainActor
public final class SwiftDataCredentialsStorage: CredentialsStorageProtocol {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func save(_ credentials: AuthCredentialsProtocol) async throws {
        // Clear any existing credentials first
        try await clear()

        // Convert protocol to concrete SwiftData model for persistence
        let authCredentials = AuthCredentials(
            handle: credentials.handle,
            accessToken: credentials.accessToken,
            refreshToken: credentials.refreshToken,
            did: credentials.did,
            pdsURL: credentials.pdsURL,
            expiresAt: credentials.expiresAt
        )

        // Insert into SwiftData
        context.insert(authCredentials)
        try context.save()

        print("💾 Saved credentials to SwiftData (warning: will be lost on rebuild)")
    }

    public func load() async -> AuthCredentials? {
        let descriptor = FetchDescriptor<AuthCredentials>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            let allCredentials = try context.fetch(descriptor)
            print("🔍 Found \(allCredentials.count) stored credentials in SwiftData")

            guard let credentials = allCredentials.first else {
                print("🔍 No credentials found in SwiftData")
                return nil
            }

            print("🔍 Checking SwiftData credentials for @\(credentials.handle), expires: \(credentials.expiresAt), valid: \(credentials.isValid)")

            // Check if credentials are still valid
            if credentials.isValid {
                return credentials
            } else {
                print("🔍 SwiftData credentials expired, cleaning up")
                // Clean up invalid credentials
                try? await clear()
                return nil
            }
        } catch {
            print("🔍 Error fetching credentials from SwiftData: \(error)")
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
        print("💾 Cleared credentials from SwiftData")
    }
}

// MARK: - In-Memory Implementation

/// Test implementation using in-memory storage
@MainActor
public final class InMemoryCredentialsStorage: CredentialsStorageProtocol {
    private var credentials: AuthCredentials?

    public init() {}

    public func save(_ credentials: AuthCredentialsProtocol) async throws {
        // Store as concrete AuthCredentials for simplicity in tests
        self.credentials = AuthCredentials(
            handle: credentials.handle,
            accessToken: credentials.accessToken,
            refreshToken: credentials.refreshToken,
            did: credentials.did,
            pdsURL: credentials.pdsURL,
            expiresAt: credentials.expiresAt
        )
    }

    public func load() async -> AuthCredentials? {
        credentials
    }

    public func clear() async throws {
        credentials = nil
    }
}

// MARK: - Supporting Types

/// Codable representation of credentials for JSON encoding/decoding
private struct CredentialsData: Codable {
    let handle: String
    let accessToken: String
    let refreshToken: String
    let did: String
    let pdsURL: String
    let expiresAt: Date
    let createdAt: Date
}

/// Errors that can occur during credentials storage operations
public enum CredentialsStorageError: Error, LocalizedError {
    case keychainError(OSStatus)

    public var errorDescription: String? {
        switch self {
        case .keychainError(let status):
            return "Keychain error: \(status)"
        }
    }
}
