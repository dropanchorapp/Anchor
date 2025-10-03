import Foundation

public struct PlaceCategorization {

    // MARK: - Category Cache Integration

    /// Shared category cache for backend categories
    private static let categoryCache: CategoryCacheServiceProtocol = CategoryCacheService.shared

    // MARK: - Categories now provided by backend API
    // All category data is fetched from /api/places/categories and cached locally

    // MARK: - Category Grouping for UI

    public enum CategoryGroup: String, CaseIterable, Codable, Sendable {
        case foodAndDrink = "Food & Drink"
        case entertainment = "Entertainment"
        case sports = "Sports & Fitness"
        case shopping = "Shopping"
        case accommodation = "Accommodation"
        case transportation = "Transportation"
        case services = "Services"
        case nature = "Nature & Parks"
        case culture = "Culture"
        case health = "Health"
        case education = "Education"

        public var icon: String {
            switch self {
            case .foodAndDrink: return "🍽️"
            case .entertainment: return "🎭"
            case .sports: return "🏃‍♂️"
            case .shopping: return "🛍️"
            case .accommodation: return "🏨"
            case .transportation: return "🚌"
            case .services: return "🏛️"
            case .nature: return "🌳"
            case .culture: return "🎨"
            case .health: return "🏥"
            case .education: return "📚"
            }
        }
    }

    // MARK: - Public API (All data comes from backend)

    /// Get category group for tag/value pair
    public static func getCategoryGroup(for tag: String, value: String) -> CategoryGroup? {
        return categoryCache.getCategoryGroup(for: tag, value: value)
    }

    /// Get icon for tag/value pair
    public static func getIcon(for tag: String, value: String) -> String {
        return categoryCache.getIcon(for: tag, value: value)
    }

    /// Get all categories as OSM tag strings
    public static func getAllCategories() -> [String] {
        return categoryCache.getAllCategories()
    }

    /// Get prioritized categories for default searches
    public static func getPrioritizedCategories() -> [String] {
        return categoryCache.getPrioritizedCategories()
    }

    /// Get categories for specific group (String version)
    public static func getCategoriesForGroup(_ group: String) -> [String] {
        let categoryGroup = CategoryGroup(rawValue: group)
        return getCategoriesForGroup(categoryGroup)
    }

    /// Get categories for specific group (CategoryGroup version)
    public static func getCategoriesForGroup(_ group: CategoryGroup?) -> [String] {
        guard let group = group else {
            return getPrioritizedCategories()
        }

        return categoryCache.getCategoriesForGroup(group)
    }
}
