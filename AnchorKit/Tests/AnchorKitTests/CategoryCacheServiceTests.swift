import Foundation
import Testing
@testable import AnchorKit

@Suite("Category Cache Service", .tags(.services))
struct CategoryCacheServiceTests {
    let mockUserDefaults: UserDefaults
    let mockSession: MockURLSession
    let categoryService: CategoryCacheService
    let suiteName: String

    init() {
        // Create a unique suite name for each test instance to avoid conflicts in parallel execution
        suiteName = "CategoryCacheServiceTests-\(UUID().uuidString)"

        // Create a mock UserDefaults for testing
        mockUserDefaults = UserDefaults(suiteName: suiteName)!

        // Clear any existing data before each test
        mockUserDefaults.removePersistentDomain(forName: suiteName)

        // Create mock URL session
        mockSession = MockURLSession()

        // Create service with mocked dependencies
        categoryService = CategoryCacheService(
            session: mockSession,
            baseURL: URL(string: "https://test.example.com/api")!,
            userDefaults: mockUserDefaults
        )
    }

    // MARK: - Cache Management Tests

    @Test("Empty cache returns nil and is expired")
    func emptyCache() {
        // When cache is empty
        let cached = categoryService.getCachedCategories()

        // Then no cached data should be returned
        #expect(cached == nil)
        #expect(categoryService.isCacheExpired())
    }

    @Test("Set and get cached categories")
    func setAndGetCachedCategories() {
        // Given some test categories
        let testCategories = createTestCachedCategories()

        // When we cache them
        categoryService.setCachedCategories(testCategories)

        // Then we should be able to retrieve them
        let retrieved = categoryService.getCachedCategories()
        #expect(retrieved != nil)
        #expect(retrieved?.categories.count == testCategories.categories.count)
        #expect(retrieved?.defaultSearch.count == testCategories.defaultSearch.count)
        #expect(!categoryService.isCacheExpired())
    }

    @Test("Cache expiry after 25 hours")
    func cacheExpiry() {
        // Given categories cached 25 hours ago (expired)
        let expiredDate = Date().addingTimeInterval(-25 * 3600) // 25 hours ago
        let testCategories = CachedCategories(
            categories: [createTestCategory()],
            defaultSearch: ["amenity=restaurant"],
            sociallyRelevant: ["amenity=restaurant"],
            metadata: CategoryMetadata(totalCategories: 1, defaultSearchCount: 1, sociallyRelevantCount: 1),
            lastUpdated: expiredDate
        )

        // When we cache them
        categoryService.setCachedCategories(testCategories)

        // Then cache should be considered expired
        #expect(categoryService.isCacheExpired())
    }

    @Test("Clear cache removes all data")
    func clearCache() {
        // Given cached categories
        let testCategories = createTestCachedCategories()
        categoryService.setCachedCategories(testCategories)
        #expect(categoryService.getCachedCategories() != nil)

        // When we clear the cache
        categoryService.clearCache()

        // Then cache should be empty
        #expect(categoryService.getCachedCategories() == nil)
        #expect(categoryService.isCacheExpired())
    }

    // MARK: - API Fetch Tests

    @Test("Successful API fetch caches categories")
    func successfulAPIFetch() async throws {
        // Given a successful API response
        let apiResponse = createTestAPIResponse()
        let responseData = try JSONEncoder().encode(apiResponse)
        let httpResponse = HTTPURLResponse(
            url: URL(string: "https://test.example.com/api/places/categories")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        let mockSession = MockURLSession(data: responseData, response: httpResponse)

        // Recreate service with updated mock
        let categoryService = CategoryCacheService(
            session: mockSession,
            baseURL: URL(string: "https://test.example.com/api")!,
            userDefaults: mockUserDefaults
        )

        // When we fetch categories
        let result = try await categoryService.fetchAndCacheCategories()

        // Then we should get cached categories
        #expect(result.categories.count == 2)
        #expect(result.defaultSearch.count == 1)
        #expect(result.sociallyRelevant.count == 2)

        // And they should be cached
        let cached = categoryService.getCachedCategories()
        #expect(cached != nil)
        #expect(cached?.categories.count == 2)
    }

    @Test("API fetch failure throws network error")
    func apiFetchFailure() async {
        // Given a failed API response
        let mockSession = MockURLSession(error: URLError(.notConnectedToInternet))

        // Recreate service with updated mock
        let categoryService = CategoryCacheService(
            session: mockSession,
            baseURL: URL(string: "https://test.example.com/api")!,
            userDefaults: mockUserDefaults
        )

        // When/Then we fetch categories, should throw network error
        await #expect(throws: CategoryCacheError.self) {
            try await categoryService.fetchAndCacheCategories()
        }
    }

    @Test("API fetch HTTP error throws with status code")
    func apiFetchHTTPError() async throws {
        // Given an HTTP error response
        let errorData = "Not Found".data(using: .utf8)!
        let httpErrorResponse = HTTPURLResponse(
            url: URL(string: "https://test.example.com/api/places/categories")!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        )!

        let mockSession = MockURLSession(data: errorData, response: httpErrorResponse)

        // Recreate service with updated mock
        let categoryService = CategoryCacheService(
            session: mockSession,
            baseURL: URL(string: "https://test.example.com/api")!,
            userDefaults: mockUserDefaults
        )

        // When/Then we fetch categories, should throw HTTP error with status code
        do {
            _ = try await categoryService.fetchAndCacheCategories()
            Issue.record("Should have thrown an error")
        } catch let error as CategoryCacheError {
            if case .networkError(let underlyingError) = error,
               case .httpError(let statusCode) = underlyingError as? CategoryCacheError {
                #expect(statusCode == 404)
            } else {
                Issue.record("Expected network error containing HTTP error, got: \(error)")
            }
        }
    }

    // MARK: - Fallback Tests

    @Test("No cached categories returns empty array")
    func noCachedCategoriesReturnsEmpty() {
        // Given no cached categories
        #expect(categoryService.getCachedCategories() == nil)

        // When we request categories
        let categories = categoryService.getAllCategories()

        // Then we should get empty array (no hardcoded fallback)
        #expect(categories.isEmpty)
    }

    @Test("No cached prioritized categories returns empty array")
    func noCachedPrioritizedCategoriesReturnsEmpty() {
        // Given no cached categories
        #expect(categoryService.getCachedCategories() == nil)

        // When we request prioritized categories
        let prioritized = categoryService.getPrioritizedCategories()

        // Then we should get empty array (no hardcoded fallback)
        #expect(prioritized.isEmpty)
    }

    @Test("No cached category group returns nil")
    func noCachedCategoryGroupReturnsNil() {
        // Given no cached categories
        #expect(categoryService.getCachedCategories() == nil)

        // When we request category group
        let group = categoryService.getCategoryGroup(for: "amenity", value: "restaurant")

        // Then we should get nil (no hardcoded fallback)
        #expect(group == nil)
    }

    @Test("No cached icon returns default icon")
    func noCachedIconReturnsDefault() {
        // Given no cached categories
        #expect(categoryService.getCachedCategories() == nil)

        // When we request icon
        let icon = categoryService.getIcon(for: "amenity", value: "restaurant")

        // Then we should get default icon (no hardcoded fallback)
        #expect(icon == "📍")
    }

    // MARK: - Cached Category Lookup Tests

    @Test("Cached category lookup returns correct data")
    func cachedCategoryLookup() {
        // Given cached categories
        let testCategories = createTestCachedCategories()
        categoryService.setCachedCategories(testCategories)

        // When we lookup categories
        let group = categoryService.getCategoryGroup(for: "amenity", value: "restaurant")
        let icon = categoryService.getIcon(for: "amenity", value: "restaurant")
        let allCategories = categoryService.getAllCategories()

        // Then we should get cached data
        #expect(group == .foodAndDrink)
        #expect(icon == "🍽️")
        #expect(allCategories.contains("amenity=restaurant"))
        #expect(allCategories.contains("leisure=climbing"))
    }

    // MARK: - Helper Methods

    private func createTestCategory() -> CachedCategory {
        return CachedCategory(
            id: "amenity_restaurant",
            name: "Restaurant",
            icon: "🍽️",
            group: .foodAndDrink,
            osmTag: "amenity=restaurant",
            tag: "amenity",
            value: "restaurant"
        )
    }

    private func createTestCachedCategories() -> CachedCategories {
        let categories = [
            CachedCategory(
                id: "amenity_restaurant",
                name: "Restaurant",
                icon: "🍽️",
                group: .foodAndDrink,
                osmTag: "amenity=restaurant",
                tag: "amenity",
                value: "restaurant"
            ),
            CachedCategory(
                id: "leisure_climbing",
                name: "Climbing",
                icon: "🧗‍♂️",
                group: .sports,
                osmTag: "leisure=climbing",
                tag: "leisure",
                value: "climbing"
            )
        ]

        return CachedCategories(
            categories: categories,
            defaultSearch: ["amenity=restaurant"],
            sociallyRelevant: ["amenity=restaurant", "leisure=climbing"],
            metadata: CategoryMetadata(totalCategories: 2, defaultSearchCount: 1, sociallyRelevantCount: 2)
        )
    }

    private func createTestAPIResponse() -> CategoriesAPIResponse {
        let categories = [
            CategoryAPI(
                id: "amenity_restaurant",
                name: "Restaurant",
                icon: "🍽️",
                group: "FOOD_AND_DRINK",
                osmTag: "amenity=restaurant"
            ),
            CategoryAPI(
                id: "leisure_climbing",
                name: "Climbing",
                icon: "🧗‍♂️",
                group: "SPORTS",
                osmTag: "leisure=climbing"
            )
        ]

        return CategoriesAPIResponse(
            categories: categories,
            defaultSearch: ["amenity=restaurant"],
            sociallyRelevant: ["amenity=restaurant", "leisure=climbing"],
            metadata: CategoryMetadata(totalCategories: 2, defaultSearchCount: 1, sociallyRelevantCount: 2)
        )
    }
}
