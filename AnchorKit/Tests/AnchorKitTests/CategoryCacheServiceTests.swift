import XCTest
import Foundation
@testable import AnchorKit

final class CategoryCacheServiceTests: XCTestCase {
    
    var mockUserDefaults: UserDefaults!
    var mockSession: MockURLSession!
    var categoryService: CategoryCacheService!
    
    override func setUp() {
        super.setUp()
        
        // Create a mock UserDefaults for testing
        mockUserDefaults = UserDefaults(suiteName: "CategoryCacheServiceTests")!
        
        // Clear any existing data
        mockUserDefaults.removePersistentDomain(forName: "CategoryCacheServiceTests")
        
        // Create mock URL session
        mockSession = MockURLSession()
        
        // Create service with mocked dependencies
        categoryService = CategoryCacheService(
            session: mockSession,
            baseURL: URL(string: "https://test.example.com/api")!,
            userDefaults: mockUserDefaults
        )
    }
    
    override func tearDown() {
        // Clean up
        mockUserDefaults.removePersistentDomain(forName: "CategoryCacheServiceTests")
        mockUserDefaults = nil
        mockSession = nil
        categoryService = nil
        super.tearDown()
    }
    
    // MARK: - Cache Management Tests
    
    func testEmptyCache() {
        // When cache is empty
        let cached = categoryService.getCachedCategories()
        
        // Then no cached data should be returned
        XCTAssertNil(cached)
        XCTAssertTrue(categoryService.isCacheExpired())
    }
    
    func testSetAndGetCachedCategories() {
        // Given some test categories
        let testCategories = createTestCachedCategories()
        
        // When we cache them
        categoryService.setCachedCategories(testCategories)
        
        // Then we should be able to retrieve them
        let retrieved = categoryService.getCachedCategories()
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.categories.count, testCategories.categories.count)
        XCTAssertEqual(retrieved?.defaultSearch.count, testCategories.defaultSearch.count)
        XCTAssertFalse(categoryService.isCacheExpired())
    }
    
    func testCacheExpiry() {
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
        XCTAssertTrue(categoryService.isCacheExpired())
    }
    
    func testClearCache() {
        // Given cached categories
        let testCategories = createTestCachedCategories()
        categoryService.setCachedCategories(testCategories)
        XCTAssertNotNil(categoryService.getCachedCategories())
        
        // When we clear the cache
        categoryService.clearCache()
        
        // Then cache should be empty
        XCTAssertNil(categoryService.getCachedCategories())
        XCTAssertTrue(categoryService.isCacheExpired())
    }
    
    // MARK: - API Fetch Tests
    
    func testSuccessfulAPIFetch() async throws {
        // Given a successful API response
        let apiResponse = createTestAPIResponse()
        let responseData = try JSONEncoder().encode(apiResponse)
        let httpResponse = HTTPURLResponse(
            url: URL(string: "https://test.example.com/api/places/categories")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        mockSession = MockURLSession(data: responseData, response: httpResponse)
        
        // Recreate service with updated mock
        categoryService = CategoryCacheService(
            session: mockSession,
            baseURL: URL(string: "https://test.example.com/api")!,
            userDefaults: mockUserDefaults
        )
        
        // When we fetch categories
        let result = try await categoryService.fetchAndCacheCategories()
        
        // Then we should get cached categories
        XCTAssertEqual(result.categories.count, 2)
        XCTAssertEqual(result.defaultSearch.count, 1)
        XCTAssertEqual(result.sociallyRelevant.count, 2)
        
        // And they should be cached
        let cached = categoryService.getCachedCategories()
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.categories.count, 2)
    }
    
    func testAPIFetchFailure() async {
        // Given a failed API response
        mockSession = MockURLSession(error: URLError(.notConnectedToInternet))
        
        // Recreate service with updated mock
        categoryService = CategoryCacheService(
            session: mockSession,
            baseURL: URL(string: "https://test.example.com/api")!,
            userDefaults: mockUserDefaults
        )
        
        // When we fetch categories
        do {
            _ = try await categoryService.fetchAndCacheCategories()
            XCTFail("Should have thrown an error")
        } catch {
            // Then we should get a network error
            XCTAssertTrue(error is CategoryCacheError)
            if case .networkError(let underlyingError) = error as? CategoryCacheError {
                XCTAssertTrue(underlyingError is URLError)
            } else {
                XCTFail("Expected network error")
            }
        }
    }
    
    func testAPIFetchHTTPError() async {
        // Given an HTTP error response
        let errorData = "Not Found".data(using: .utf8)!
        let httpErrorResponse = HTTPURLResponse(
            url: URL(string: "https://test.example.com/api/places/categories")!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        )!
        
        mockSession = MockURLSession(data: errorData, response: httpErrorResponse)
        
        // Recreate service with updated mock
        categoryService = CategoryCacheService(
            session: mockSession,
            baseURL: URL(string: "https://test.example.com/api")!,
            userDefaults: mockUserDefaults
        )
        
        // When we fetch categories
        do {
            _ = try await categoryService.fetchAndCacheCategories()
            XCTFail("Should have thrown an error")
        } catch {
            // Then we should get a network error containing HTTP error
            XCTAssertTrue(error is CategoryCacheError)
            if case .networkError(let underlyingError) = error as? CategoryCacheError,
               case .httpError(let statusCode) = underlyingError as? CategoryCacheError {
                XCTAssertEqual(statusCode, 404)
            } else {
                XCTFail("Expected network error containing HTTP error, got: \(error)")
            }
        }
    }
    
    // MARK: - Fallback Tests
    
    func testNoCachedCategoriesReturnsEmpty() {
        // Given no cached categories
        XCTAssertNil(categoryService.getCachedCategories())
        
        // When we request categories
        let categories = categoryService.getAllCategories()
        
        // Then we should get empty array (no hardcoded fallback)
        XCTAssertTrue(categories.isEmpty)
    }
    
    func testNoCachedPrioritizedCategoriesReturnsEmpty() {
        // Given no cached categories
        XCTAssertNil(categoryService.getCachedCategories())
        
        // When we request prioritized categories
        let prioritized = categoryService.getPrioritizedCategories()
        
        // Then we should get empty array (no hardcoded fallback)
        XCTAssertTrue(prioritized.isEmpty)
    }
    
    func testNoCachedCategoryGroupReturnsNil() {
        // Given no cached categories
        XCTAssertNil(categoryService.getCachedCategories())
        
        // When we request category group
        let group = categoryService.getCategoryGroup(for: "amenity", value: "restaurant")
        
        // Then we should get nil (no hardcoded fallback)
        XCTAssertNil(group)
    }
    
    func testNoCachedIconReturnsDefault() {
        // Given no cached categories
        XCTAssertNil(categoryService.getCachedCategories())
        
        // When we request icon
        let icon = categoryService.getIcon(for: "amenity", value: "restaurant")
        
        // Then we should get default icon (no hardcoded fallback)
        XCTAssertEqual(icon, "📍")
    }
    
    // MARK: - Cached Category Lookup Tests
    
    func testCachedCategoryLookup() {
        // Given cached categories
        let testCategories = createTestCachedCategories()
        categoryService.setCachedCategories(testCategories)
        
        // When we lookup categories
        let group = categoryService.getCategoryGroup(for: "amenity", value: "restaurant")
        let icon = categoryService.getIcon(for: "amenity", value: "restaurant")
        let allCategories = categoryService.getAllCategories()
        
        // Then we should get cached data
        XCTAssertEqual(group, .foodAndDrink)
        XCTAssertEqual(icon, "🍽️")
        XCTAssertTrue(allCategories.contains("amenity=restaurant"))
        XCTAssertTrue(allCategories.contains("leisure=climbing"))
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

