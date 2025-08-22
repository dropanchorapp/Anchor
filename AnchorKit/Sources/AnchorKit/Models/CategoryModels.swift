import Foundation

// MARK: - API Response Models

/// Response from /api/places/categories endpoint
public struct CategoriesAPIResponse: Codable, Sendable {
    public let categories: [CategoryAPI]
    public let defaultSearch: [String]
    public let sociallyRelevant: [String]
    public let metadata: CategoryMetadata
    
    public init(categories: [CategoryAPI], defaultSearch: [String], sociallyRelevant: [String], metadata: CategoryMetadata) {
        self.categories = categories
        self.defaultSearch = defaultSearch
        self.sociallyRelevant = sociallyRelevant
        self.metadata = metadata
    }
}

/// Category data from API
public struct CategoryAPI: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let icon: String
    public let group: String
    public let osmTag: String
    
    public init(id: String, name: String, icon: String, group: String, osmTag: String) {
        self.id = id
        self.name = name
        self.icon = icon
        self.group = group
        self.osmTag = osmTag
    }
}

/// Metadata about categories from API
public struct CategoryMetadata: Codable, Sendable {
    public let totalCategories: Int
    public let defaultSearchCount: Int
    public let sociallyRelevantCount: Int
    
    public init(totalCategories: Int, defaultSearchCount: Int, sociallyRelevantCount: Int) {
        self.totalCategories = totalCategories
        self.defaultSearchCount = defaultSearchCount
        self.sociallyRelevantCount = sociallyRelevantCount
    }
}

// MARK: - Local Category Models

/// Local category representation for caching and lookup
public struct CachedCategory: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let icon: String
    public let group: PlaceCategorization.CategoryGroup
    public let osmTag: String
    public let tag: String
    public let value: String
    
    public init(id: String, name: String, icon: String, group: PlaceCategorization.CategoryGroup, osmTag: String, tag: String, value: String) {
        self.id = id
        self.name = name
        self.icon = icon
        self.group = group
        self.osmTag = osmTag
        self.tag = tag
        self.value = value
    }
    
    /// Convert from API category to cached category
    public init?(from apiCategory: CategoryAPI) {
        // Parse OSM tag (e.g., "amenity=restaurant" -> tag="amenity", value="restaurant")
        let components = apiCategory.osmTag.split(separator: "=")
        guard components.count == 2 else { 
            return nil 
        }
        
        let tag = String(components[0])
        let value = String(components[1])
        
        // Convert group string to enum
        guard let group = PlaceCategorization.CategoryGroup.fromAPIString(apiCategory.group) else {
            return nil
        }
        
        self.id = apiCategory.id
        self.name = apiCategory.name
        self.icon = apiCategory.icon
        self.group = group
        self.osmTag = apiCategory.osmTag
        self.tag = tag
        self.value = value
    }
}

// MARK: - CategoryGroup Extensions

extension PlaceCategorization.CategoryGroup {
    /// Convert API group string to CategoryGroup enum
    static func fromAPIString(_ apiGroup: String) -> PlaceCategorization.CategoryGroup? {
        // Handle both lowercase_underscore and UPPERCASE_UNDERSCORE formats
        let normalizedGroup = apiGroup.uppercased()
        
        switch normalizedGroup {
        case "FOOD_AND_DRINK":
            return .foodAndDrink
        case "ENTERTAINMENT":
            return .entertainment
        case "SPORTS":
            return .sports
        case "SHOPPING":
            return .shopping
        case "ACCOMMODATION":
            return .accommodation
        case "TRANSPORTATION":
            return .transportation
        case "SERVICES":
            return .services
        case "NATURE":
            return .nature
        case "CULTURE":
            return .culture
        case "HEALTH":
            return .health
        case "EDUCATION":
            return .education
        default:
            return nil
        }
    }
    
    /// Convert CategoryGroup enum to API string format (lowercase_underscore format)
    var apiString: String {
        switch self {
        case .foodAndDrink:
            return "food_and_drink"
        case .entertainment:
            return "entertainment"
        case .sports:
            return "sports"
        case .shopping:
            return "shopping"
        case .accommodation:
            return "accommodation"
        case .transportation:
            return "transportation"
        case .services:
            return "services"
        case .nature:
            return "nature"
        case .culture:
            return "culture"
        case .health:
            return "health"
        case .education:
            return "education"
        }
    }
}

// MARK: - Cached Categories Container

/// Container for all cached category data
public struct CachedCategories: Codable, Sendable {
    public let categories: [CachedCategory]
    public let defaultSearch: [String]
    public let sociallyRelevant: [String]
    public let metadata: CategoryMetadata
    public let lastUpdated: Date
    
    public init(categories: [CachedCategory], defaultSearch: [String], sociallyRelevant: [String], metadata: CategoryMetadata, lastUpdated: Date = Date()) {
        self.categories = categories
        self.defaultSearch = defaultSearch
        self.sociallyRelevant = sociallyRelevant
        self.metadata = metadata
        self.lastUpdated = lastUpdated
    }
    
    /// Convert from API response to cached categories
    public init?(from apiResponse: CategoriesAPIResponse) {
        let cachedCategories = apiResponse.categories.compactMap { CachedCategory(from: $0) }
        
        // Ensure we got all categories successfully
        guard cachedCategories.count == apiResponse.categories.count else {
            return nil
        }
        
        self.categories = cachedCategories
        self.defaultSearch = apiResponse.defaultSearch
        self.sociallyRelevant = apiResponse.sociallyRelevant
        self.metadata = apiResponse.metadata
        self.lastUpdated = Date()
    }
    
    // MARK: - Lookup Methods
    
    /// Get category group for tag/value pair
    public func getCategoryGroup(for tag: String, value: String) -> PlaceCategorization.CategoryGroup? {
        return categories.first { $0.tag == tag && $0.value == value }?.group
    }
    
    /// Get icon for tag/value pair
    public func getIcon(for tag: String, value: String) -> String {
        return categories.first { $0.tag == tag && $0.value == value }?.icon ?? "📍"
    }
    
    /// Get all categories as OSM tag strings
    public func getAllCategories() -> [String] {
        return categories.map { $0.osmTag }.sorted()
    }
    
    /// Get prioritized categories (maps to defaultSearch)
    public func getPrioritizedCategories() -> [String] {
        return defaultSearch
    }
    
    /// Get categories for a specific group
    public func getCategoriesForGroup(_ group: PlaceCategorization.CategoryGroup) -> [String] {
        return categories
            .filter { $0.group == group }
            .map { $0.osmTag }
            .sorted()
    }
}
