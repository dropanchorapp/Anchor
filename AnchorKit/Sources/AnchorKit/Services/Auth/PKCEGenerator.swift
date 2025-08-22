//
//  PKCEGenerator.swift
//  AnchorKit
//
//  Created by Tijs Teulings on 22/08/2025.
//

import Foundation
import CryptoKit

/// PKCE (Proof Key for Code Exchange) generator for OAuth 2.1 security
/// 
/// Implements RFC 7636 PKCE specification to protect against authorization code
/// interception attacks in mobile OAuth flows.
public struct PKCEGenerator {
    
    // MARK: - PKCE Parameters
    
    /// PKCE parameters for OAuth 2.1 secure authentication
    public struct PKCEParams {
        /// Code verifier - random string stored securely on device
        public let codeVerifier: String
        /// Code challenge - SHA256 hash of code verifier, sent to server
        public let codeChallenge: String
        /// Code challenge method - always "S256" for SHA256
        public let codeChallengeMethod: String = "S256"
        
        public init(codeVerifier: String, codeChallenge: String) {
            self.codeVerifier = codeVerifier
            self.codeChallenge = codeChallenge
        }
    }
    
    // MARK: - PKCE Generation
    
    /// Generate PKCE parameters for secure OAuth flow
    /// 
    /// Creates a cryptographically secure code verifier and corresponding
    /// SHA256-based code challenge according to RFC 7636 specification.
    ///
    /// - Returns: PKCEParams containing code_verifier and code_challenge
    public static func generatePKCE() -> PKCEParams {
        let codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(from: codeVerifier)
        
        return PKCEParams(
            codeVerifier: codeVerifier,
            codeChallenge: codeChallenge
        )
    }
    
    // MARK: - Private Implementation
    
    /// Generate cryptographically secure code verifier
    /// 
    /// RFC 7636 requires code verifier to be:
    /// - 43-128 characters long
    /// - Use characters [A-Z] / [a-z] / [0-9] / "-" / "." / "_" / "~"
    /// - Cryptographically random
    private static func generateCodeVerifier() -> String {
        let allowedCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
        let length = 128 // Use maximum length for security
        
        var codeVerifier = ""
        for _ in 0..<length {
            let randomIndex = Int.random(in: 0..<allowedCharacters.count)
            let character = allowedCharacters[allowedCharacters.index(allowedCharacters.startIndex, offsetBy: randomIndex)]
            codeVerifier.append(character)
        }
        
        return codeVerifier
    }
    
    /// Generate code challenge from code verifier using SHA256
    /// 
    /// RFC 7636 specifies SHA256 hashing with base64url encoding:
    /// code_challenge = BASE64URL-ENCODE(SHA256(ASCII(code_verifier)))
    private static func generateCodeChallenge(from codeVerifier: String) -> String {
        let data = codeVerifier.data(using: .ascii)!
        let hash = SHA256.hash(data: data)
        
        // Convert to base64url encoding (RFC 4648 Section 5)
        let base64 = Data(hash).base64EncodedString()
        return base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

// MARK: - PKCE Storage Protocol

/// Protocol for securely storing PKCE code verifier during OAuth flow
public protocol PKCEStorageProtocol: Sendable {
    /// Store code verifier securely for OAuth session
    func storePKCEVerifier(_ verifier: String, for sessionId: String) async throws
    
    /// Retrieve code verifier for OAuth token exchange
    func retrievePKCEVerifier(for sessionId: String) async throws -> String?
    
    /// Clear stored code verifier after OAuth completion
    func clearPKCEVerifier(for sessionId: String) async throws
}

// MARK: - In-Memory PKCE Storage

/// In-memory PKCE storage for development and testing
/// 
/// **Security Warning**: In production apps, use Keychain storage
/// for PKCE code verifiers to prevent unauthorized access.
public final class InMemoryPKCEStorage: PKCEStorageProtocol, @unchecked Sendable {
    private var storage: [String: String] = [:]
    private let queue = DispatchQueue(label: "pkce.storage", attributes: .concurrent)
    
    public init() {}
    
    public func storePKCEVerifier(_ verifier: String, for sessionId: String) async throws {
        await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                self.storage[sessionId] = verifier
                continuation.resume()
            }
        }
    }
    
    public func retrievePKCEVerifier(for sessionId: String) async throws -> String? {
        await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.storage[sessionId])
            }
        }
    }
    
    public func clearPKCEVerifier(for sessionId: String) async throws {
        await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                self.storage.removeValue(forKey: sessionId)
                continuation.resume()
            }
        }
    }
}

// MARK: - Keychain PKCE Storage

/// Secure Keychain-based PKCE storage for production use
/// 
/// Stores PKCE code verifiers in iOS Keychain with appropriate
/// security attributes for OAuth temporary credentials.
public final class KeychainPKCEStorage: PKCEStorageProtocol, @unchecked Sendable {
    private let service = "app.dropanchor.pkce"
    
    public init() {}
    
    public func storePKCEVerifier(_ verifier: String, for sessionId: String) async throws {
        let data = verifier.data(using: .utf8)!
        let account = "pkce_\(sessionId)"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item if present
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            throw PKCEStorageError.keychainError(status)
        }
    }
    
    public func retrievePKCEVerifier(for sessionId: String) async throws -> String? {
        let account = "pkce_\(sessionId)"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        if status != errSecSuccess {
            throw PKCEStorageError.keychainError(status)
        }
        
        guard let data = item as? Data,
              let verifier = String(data: data, encoding: .utf8) else {
            throw PKCEStorageError.corruptedData
        }
        
        return verifier
    }
    
    public func clearPKCEVerifier(for sessionId: String) async throws {
        let account = "pkce_\(sessionId)"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        // Don't throw error if item doesn't exist
        if status != errSecSuccess && status != errSecItemNotFound {
            throw PKCEStorageError.keychainError(status)
        }
    }
}

// MARK: - PKCE Storage Errors

/// Errors that can occur during PKCE storage operations
public enum PKCEStorageError: Error, LocalizedError {
    case keychainError(OSStatus)
    case corruptedData
    
    public var errorDescription: String? {
        switch self {
        case .keychainError(let status):
            return "Keychain error: \(status)"
        case .corruptedData:
            return "PKCE data corrupted in storage"
        }
    }
}
