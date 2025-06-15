import Testing
@testable import AnchorKit

/// Tests for credentials storage implementations following Swift Testing patterns
/// 
/// ## Testing Strategy
/// 
/// We use `InMemoryCredentialsStorage` for all tests to avoid SwiftData ModelContainer 
/// issues in CI environments. While the Hacking with Swift guide recommends using 
/// `ModelConfiguration(isStoredInMemoryOnly: true)` for SwiftData testing, this approach
/// still requires a ModelContainer to be available, which causes CI failures.
/// 
/// Reference: https://www.hackingwithswift.com/quick-start/swiftdata/how-to-write-unit-tests-for-your-swiftdata-code
/// 
/// ## Architecture Benefits
/// 
/// Our dependency injection pattern allows us to:
/// - Use `SwiftDataCredentialsStorage` in production with real persistence
/// - Use `InMemoryCredentialsStorage` in tests for fast, isolated testing
/// - Avoid test detection logic in production code (anti-pattern)
/// - Maintain identical behavior between storage implementations
/// 
/// ## Future SwiftData Testing
/// 
/// If you need to test SwiftData-specific behavior in the future, consider:
/// 1. Creating a separate test target with proper ModelContainer setup
/// 2. Using the Hacking with Swift pattern in integration tests
/// 3. Ensuring CI environment has proper SwiftData configuration
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
    
    @Test("InMemory storage handles expired credentials correctly")
    func inMemoryStorageHandlesExpiredCredentials() async throws {
        let storage = InMemoryCredentialsStorage()
        let expiredCredentials = TestUtilities.createExpiredCredentials()
        
        try await storage.save(expiredCredentials)
        let loadedCredentials = await storage.load()
        
        // InMemory storage returns credentials as-is, expiration logic is handled by services
        #expect(loadedCredentials != nil)
        #expect(loadedCredentials?.isExpired == true)
    }
} 