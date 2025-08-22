import Foundation

// MARK: - Category Cache Service Protocol

/// Service protocol for category caching and retrieval
public protocol CategoryCacheServiceProtocol: Sendable {
    func getCachedCategories() -> CachedCategories?
    func setCachedCategories(_ categories: CachedCategories)
    func fetchAndCacheCategories() async throws -> CachedCategories
    func getCategoryGroup(for tag: String, value: String) -> PlaceCategorization.CategoryGroup?
    func getIcon(for tag: String, value: String) -> String
    func getAllCategories() -> [String]
    func getPrioritizedCategories() -> [String]
    func getCategoriesForGroup(_ group: PlaceCategorization.CategoryGroup) -> [String]
    func clearCache()
    func isCacheExpired() -> Bool
}

// MARK: - Category Cache Service

/// Service for caching and retrieving POI categories from backend API
/// Provides local caching with fallback to hardcoded categories
public final class CategoryCacheService: CategoryCacheServiceProtocol, @unchecked Sendable {
    
    // MARK: - Properties
    
    private let session: URLSessionProtocol
    private let baseURL: URL
    private let userDefaults: UserDefaults
    private let cacheKey = "AnchorCachedCategories"
    private let cacheExpiryHours: TimeInterval = 24 // 24 hours
    
    private var memoryCache: CachedCategories?
    private let cacheQueue = DispatchQueue(label: "com.anchor.category-cache", qos: .utility)
    
    // MARK: - Initialization
    
    public init(
        session: URLSessionProtocol = URLSession.shared,
        baseURL: URL = URL(string: "https://dropanchor.app/api")!,
        userDefaults: UserDefaults = .standard
    ) {
        self.session = session
        self.baseURL = baseURL
        self.userDefaults = userDefaults
        
        // Load cache from disk on init
        loadCacheFromDisk()
    }
    
    // MARK: - Cache Management
    
    /// Get cached categories (memory first, then disk, then fallback)
    public func getCachedCategories() -> CachedCategories? {
        return cacheQueue.sync {
            if let memoryCache = memoryCache {
                if !isCacheExpired(memoryCache) {
                    return memoryCache
                }
            }
            
            // Try to load from disk
            loadCacheFromDisk()
            
            if let memoryCache = memoryCache {
                if !isCacheExpired(memoryCache) {
                    return memoryCache
                }
            }
            
            return nil
        }
    }
    
    /// Set cached categories (saves to both memory and disk)
    public func setCachedCategories(_ categories: CachedCategories) {
        cacheQueue.async {
            self.memoryCache = categories
            self.saveCacheToDisk(categories)
        }
    }
    
    /// Fetch categories from API and cache them
    public func fetchAndCacheCategories() async throws -> CachedCategories {
        print("🗂️ DEBUG: fetchAndCacheCategories() method started")
        print("🗂️ CategoryCacheService: Fetching categories from API...")
        
        let request = try buildCategoriesRequest()
        print("🗂️ DEBUG: Built request for URL: \(request.url?.absoluteString ?? "nil")")
        
        do {
            print("🗂️ DEBUG: About to make network request")
            let (data, response) = try await session.data(for: request)
            print("🗂️ DEBUG: Received response, data size: \(data.count) bytes")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ DEBUG: Response is not HTTPURLResponse: \(response)")
                throw CategoryCacheError.invalidResponse
            }
            
            print("🗂️ CategoryCacheService: Response status: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ CategoryCacheService: Error response: \(errorString)")
                throw CategoryCacheError.httpError(httpResponse.statusCode)
            }
            
            let apiResponse = try JSONDecoder().decode(CategoriesAPIResponse.self, from: data)
            
            guard let cachedCategories = CachedCategories(from: apiResponse) else {
                throw CategoryCacheError.conversionFailed
            }
            
            print("✅ CategoryCacheService: Successfully fetched \(cachedCategories.categories.count) categories")
            
            // Cache the results
            setCachedCategories(cachedCategories)
            
            return cachedCategories
            
        } catch {
            print("❌ CategoryCacheService: Network error: \(error)")
            throw CategoryCacheError.networkError(error)
        }
    }
    
    /// Check if cache is expired
    public func isCacheExpired() -> Bool {
        guard let cached = getCachedCategories() else { return true }
        return isCacheExpired(cached)
    }
    
    /// Clear all cached data
    public func clearCache() {
        cacheQueue.async {
            self.memoryCache = nil
            self.userDefaults.removeObject(forKey: self.cacheKey)
        }
    }
    
    // MARK: - Category Lookup Methods
    
    /// Get category group for tag/value pair
    public func getCategoryGroup(for tag: String, value: String) -> PlaceCategorization.CategoryGroup? {
        return getCachedCategories()?.getCategoryGroup(for: tag, value: value)
    }
    
    /// Get icon for tag/value pair
    public func getIcon(for tag: String, value: String) -> String {
        return getCachedCategories()?.getIcon(for: tag, value: value) ?? "📍"
    }
    
    /// Get all categories as OSM tag strings
    public func getAllCategories() -> [String] {
        return getCachedCategories()?.getAllCategories() ?? []
    }
    
    /// Get prioritized categories
    public func getPrioritizedCategories() -> [String] {
        return getCachedCategories()?.getPrioritizedCategories() ?? []
    }
    
    /// Get categories for specific group
    public func getCategoriesForGroup(_ group: PlaceCategorization.CategoryGroup) -> [String] {
        return getCachedCategories()?.getCategoriesForGroup(group) ?? []
    }
    
    // MARK: - Private Methods
    
    /// Build HTTP request for categories API
    private func buildCategoriesRequest() throws -> URLRequest {
        let url = baseURL.appendingPathComponent("places/categories")
        return URLRequest(url: url)
    }
    
    /// Check if specific cached categories are expired
    private func isCacheExpired(_ cached: CachedCategories) -> Bool {
        let expiryDate = cached.lastUpdated.addingTimeInterval(cacheExpiryHours * 3600)
        return Date() > expiryDate
    }
    
    /// Load cache from disk storage
    private func loadCacheFromDisk() {
        guard let data = userDefaults.data(forKey: cacheKey) else {
            print("🗂️ CategoryCacheService: No cached data found on disk")
            return
        }
        
        do {
            let cached = try JSONDecoder().decode(CachedCategories.self, from: data)
            memoryCache = cached
            print("🗂️ CategoryCacheService: Loaded \(cached.categories.count) categories from disk cache")
        } catch {
            print("❌ CategoryCacheService: Failed to decode cached data: \(error)")
            userDefaults.removeObject(forKey: cacheKey)
        }
    }
    
    /// Save cache to disk storage
    private func saveCacheToDisk(_ categories: CachedCategories) {
        do {
            let data = try JSONEncoder().encode(categories)
            userDefaults.set(data, forKey: cacheKey)
            print("🗂️ CategoryCacheService: Saved \(categories.categories.count) categories to disk cache")
        } catch {
            print("❌ CategoryCacheService: Failed to encode categories for caching: \(error)")
        }
    }
}

// MARK: - Error Types

public enum CategoryCacheError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case networkError(Error)
    case conversionFailed
    case decodingError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from categories API"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .conversionFailed:
            return "Failed to convert API response to cached format"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Shared Instance

extension CategoryCacheService {
    /// Shared instance for convenient access
    public static let shared = CategoryCacheService()
}
