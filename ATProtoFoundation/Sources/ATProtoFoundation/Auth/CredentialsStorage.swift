import Foundation
import Security

//
// MARK: - Credentials Storage
//
// This module provides storage implementations for authentication credentials:
//
// 1. **KeychainCredentialsStorage** (RECOMMENDED)
//    - Uses iOS/macOS Keychain for secure, persistent storage
//    - Survives app rebuilds and updates
//    - Platform standard for authentication tokens
//    - Simple single source of truth
//
// 2. **InMemoryCredentialsStorage** (Testing)
//    - Memory-only storage for unit tests
//    - No persistence across app restarts
//
// For production use, KeychainCredentialsStorage is the recommended approach.
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
            appPassword: credentials.appPassword,
            sessionId: credentials.sessionId,
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

        debugPrint("🔐 Saved credentials to keychain for @\(credentials.handle)")
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
            debugPrint("🔐 No credentials found in keychain")
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
                expiresAt: credentialsData.expiresAt,
                appPassword: credentialsData.appPassword,
                sessionId: credentialsData.sessionId
            )

            debugPrint("🔐 Loaded credentials from keychain for @\(credentials.handle), " +
                  "expires: \(credentials.expiresAt), valid: \(credentials.isValid)")

            // Return credentials regardless of expiration status
            // Let higher-level services (AuthService) decide whether to refresh or clear
            return credentials
        } catch {
            debugPrint("🔐 Error decoding keychain credentials: \(error)")
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
            debugPrint("🔐 Cleared credentials from keychain")
        }
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
            expiresAt: credentials.expiresAt,
            appPassword: credentials.appPassword,
            sessionId: credentials.sessionId
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
    let appPassword: String?
    let sessionId: String?
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
