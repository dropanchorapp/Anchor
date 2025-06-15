import Testing
import SwiftData
@testable import AnchorKit

/// Tests for both storage implementations following Swift Testing patterns
/// Demonstrates the Hacking with Swift approach adapted for Swift Testing
@Suite("Credentials Storage", .tags(.auth))
@MainActor
struct CredentialsStorageTests {
    
    // MARK: - InMemoryCredentialsStorage Tests
    
    @Test("InMemory storage starts empty")
    func inMemoryStorageStartsEmpty() async {
        let storage = InMemoryCredentialsStorage()
        
        let credentials = await storage.load()
        
        #expect(credentials == nil)
    }
    
    @Test("InMemory storage saves and loads credentials")
    func inMemoryStorageSavesAndLoads() async throws {
        let storage = InMemoryCredentialsStorage()
        let testCredentials = TestUtilities.createSampleCredentials()
        
        try await storage.save(testCredentials)
        let loadedCredentials = await storage.load()
        
        #expect(loadedCredentials?.handle == testCredentials.handle)
        #expect(loadedCredentials?.accessToken == testCredentials.accessToken)
        #expect(loadedCredentials?.did == testCredentials.did)
    }
    
    @Test("InMemory storage clears credentials")
    func inMemoryStorageClears() async throws {
        let storage = InMemoryCredentialsStorage()
        let testCredentials = TestUtilities.createSampleCredentials()
        
        try await storage.save(testCredentials)
        try await storage.clear()
        let loadedCredentials = await storage.load()
        
        #expect(loadedCredentials == nil)
    }
    
    // MARK: - SwiftData In-Memory Container Test
    // Following the Hacking with Swift pattern for Swift Testing
    // Reference: https://www.hackingwithswift.com/quick-start/swiftdata/how-to-write-unit-tests-for-your-swiftdata-code
    
    @Test("SwiftData storage works with in-memory container")
    func swiftDataStorageWorksWithInMemoryContainer() async throws {
        // Create in-memory container following Hacking with Swift pattern
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: AuthCredentials.self, configurations: config)
        let storage = SwiftDataCredentialsStorage(context: container.mainContext)
        
        // Test starts empty
        let initialCredentials = await storage.load()
        #expect(initialCredentials == nil)
        
        // Test save and load
        let testCredentials = TestUtilities.createSampleCredentials()
        try await storage.save(testCredentials)
        let loadedCredentials = await storage.load()
        
        #expect(loadedCredentials?.handle == testCredentials.handle)
        #expect(loadedCredentials?.accessToken == testCredentials.accessToken)
        #expect(loadedCredentials?.did == testCredentials.did)
        
        // Test clear
        try await storage.clear()
        let clearedCredentials = await storage.load()
        #expect(clearedCredentials == nil)
    }
} 