import Testing
import Foundation
@testable import AnchorKit

@Suite("Credentials Storage Tests")
struct CredentialsStorageTests {
    
    @Test("In-memory storage saves and loads credentials correctly")
    @MainActor
    func testInMemoryStorageSaveAndLoad() async throws {
        let storage = InMemoryCredentialsStorage()
        
        // Clear any existing credentials
        try await storage.clear()
        
        // Create test credentials
        let testCredentials = AuthCredentials(
            handle: "test.bsky.social",
            accessToken: "test-access-token",
            refreshToken: "test-refresh-token",
            did: "did:plc:test123",
            expiresAt: Date().addingTimeInterval(3600) // 1 hour from now
        )
        
        // Save credentials
        try await storage.save(testCredentials)
        
        // Load credentials
        let loadedCredentials = await storage.load()
        
        // Verify credentials were loaded correctly
        #expect(loadedCredentials != nil)
        #expect(loadedCredentials?.handle == "test.bsky.social")
        #expect(loadedCredentials?.accessToken == "test-access-token")
        #expect(loadedCredentials?.refreshToken == "test-refresh-token")
        #expect(loadedCredentials?.did == "did:plc:test123")
        #expect(loadedCredentials?.isValid == true)
        
        // Clean up
        try await storage.clear()
        
        // Verify credentials were cleared
        let clearedCredentials = await storage.load()
        #expect(clearedCredentials == nil)
    }
    
    @Test("In-memory storage handles expired credentials correctly")
    @MainActor
    func testInMemoryStorageExpiredCredentials() async throws {
        let storage = InMemoryCredentialsStorage()
        
        // Clear any existing credentials
        try await storage.clear()
        
        // Create expired credentials
        let expiredCredentials = AuthCredentials(
            handle: "expired.bsky.social",
            accessToken: "expired-token",
            refreshToken: "expired-refresh",
            did: "did:plc:expired",
            expiresAt: Date().addingTimeInterval(-3600) // 1 hour ago
        )
        
        // Save expired credentials
        try await storage.save(expiredCredentials)
        
        // Load credentials - InMemoryCredentialsStorage returns them as-is
        let loadedCredentials = await storage.load()
        
        // Verify expired credentials are returned (InMemoryCredentialsStorage doesn't auto-clear)
        #expect(loadedCredentials != nil)
        #expect(loadedCredentials?.handle == "expired.bsky.social")
        #expect(loadedCredentials?.isValid == false) // But they should be marked as invalid
        
        // Clear manually 
        try await storage.clear()
        let clearedCredentials = await storage.load()
        #expect(clearedCredentials == nil)
    }
    
    @Test("In-memory storage handles multiple save operations correctly")
    @MainActor
    func testInMemoryStorageMultipleSaves() async throws {
        let storage = InMemoryCredentialsStorage()
        
        // Clear any existing credentials
        try await storage.clear()
        
        // Save first credentials
        let firstCredentials = AuthCredentials(
            handle: "first.bsky.social",
            accessToken: "first-token",
            refreshToken: "first-refresh",
            did: "did:plc:first",
            expiresAt: Date().addingTimeInterval(3600)
        )
        try await storage.save(firstCredentials)
        
        // Save second credentials (should replace first)
        let secondCredentials = AuthCredentials(
            handle: "second.bsky.social",
            accessToken: "second-token",
            refreshToken: "second-refresh",
            did: "did:plc:second",
            expiresAt: Date().addingTimeInterval(3600)
        )
        try await storage.save(secondCredentials)
        
        // Load credentials - should get the second one
        let loadedCredentials = await storage.load()
        
        #expect(loadedCredentials?.handle == "second.bsky.social")
        #expect(loadedCredentials?.accessToken == "second-token")
        
        // Clean up
        try await storage.clear()
    }
} 