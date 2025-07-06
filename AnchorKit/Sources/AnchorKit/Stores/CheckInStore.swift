import Foundation

// MARK: - Check-In Store Protocol

@MainActor
public protocol CheckInStoreProtocol {
    func createCheckinWithPost(place: Place, customMessage: String?) async throws -> Bool
    func createCheckinWithOptionalPost(place: Place, customMessage: String?, shouldCreatePost: Bool) async throws -> Bool
    func buildCheckInTextWithFacets(place: Place, customMessage: String?) -> (text: String, facets: [RichTextFacet])
}

// MARK: - Check-In Store

/// Check-in creation and management store using StrongRef architecture
///
/// **STRONGREF ARCHITECTURE:**
/// When creating a check-in, this store creates TWO separate records on the user's PDS:
///
/// 1. **Address Record (community.lexicon.location.address)**: Reusable venue information
///    - Contains structured address data that can be referenced by multiple checkins
///    - Follows community lexicon standards for interoperability
///
/// 2. **Check-in Record (app.dropanchor.checkin)**: User message with StrongRef to address
///    - References the address record via StrongRef (URI + CID)
///    - Contains user's message, coordinates, and metadata
///    - Enables content integrity verification through CID matching
///
/// Additionally creates an enhanced social post on Bluesky for social engagement.
///
/// **Note:** Authentication is handled by AuthStore, not this store.
@MainActor
@Observable
public final class CheckInStore: CheckInStoreProtocol {
    // MARK: - Properties

    private let authStore: AuthStoreProtocol
    private let postService: BlueskyPostServiceProtocol
    private let richTextProcessor: RichTextProcessorProtocol
    private let atprotoClient: ATProtoClientProtocol

    // MARK: - Initialization

    /// Convenience initializer for production use with AuthStore
    public convenience init(authStore: AuthStoreProtocol, session: URLSessionProtocol = URLSession.shared) {
        let atprotoClient = ATProtoClient(session: session)
        let richTextProcessor = RichTextProcessor()
        let postService = BlueskyPostService(client: atprotoClient, richTextProcessor: richTextProcessor)

        self.init(
            authStore: authStore,
            postService: postService,
            richTextProcessor: richTextProcessor,
            atprotoClient: atprotoClient
        )
    }

    public init(
        authStore: AuthStoreProtocol,
        postService: BlueskyPostServiceProtocol,
        richTextProcessor: RichTextProcessorProtocol,
        atprotoClient: ATProtoClientProtocol
    ) {
        self.authStore = authStore
        self.postService = postService
        self.richTextProcessor = richTextProcessor
        self.atprotoClient = atprotoClient
    }

    // MARK: - Check-ins & Posts

    public func createCheckinWithPost(place: Place, customMessage: String?) async throws -> Bool {
        // Maintain backward compatibility - always create both check-in and post
        try await createCheckinWithOptionalPost(place: place, customMessage: customMessage, shouldCreatePost: true)
    }

    public func createCheckinWithOptionalPost(place: Place, customMessage: String?, shouldCreatePost: Bool) async throws -> Bool {
        // Get valid credentials from AuthStore (handles refresh automatically)
        let activeCredentials = try await authStore.getValidCredentials()

        // Build address record from place data
        let addressRecord = CommunityAddressRecord(
            name: place.name,
            street: nil, // OSM places don't always have structured street data
            locality: place.tags["addr:city"] ?? place.tags["place"] ?? place.tags["name"],
            region: place.tags["addr:state"] ?? place.tags["addr:region"],
            country: place.tags["addr:country"],
            postalCode: place.tags["addr:postcode"]
        )

        // Build coordinates
        let coordinates = GeoCoordinates(latitude: place.latitude, longitude: place.longitude)

        // Extract place category information
        let category = extractCategory(from: place.tags)
        let categoryGroup = extractCategoryGroup(from: place.tags)
        let categoryIcon = extractCategoryIcon(from: place.tags)

        // Step 1: Create check-in with address using strongref (atomic operation)
        _ = try await atprotoClient.createCheckinWithAddress(
            text: customMessage ?? "",
            address: addressRecord,
            coordinates: coordinates,
            category: category,
            categoryGroup: categoryGroup,
            categoryIcon: categoryIcon,
            credentials: activeCredentials
        )

        // Step 2: Optionally create enhanced post on Bluesky
        if shouldCreatePost {
            let (postText, _) = richTextProcessor.buildCheckinText(place: place, customMessage: customMessage)
            _ = try await postService.createPost(
                text: postText,
                credentials: activeCredentials,
                embedRecord: nil // Could embed the checkin record in the future
            )
        }

        return true
    }

    // MARK: - Rich Text Processing

    public func buildCheckInTextWithFacets(place: Place, customMessage: String?) -> (text: String, facets: [RichTextFacet]) {
        richTextProcessor.buildCheckinText(place: place, customMessage: customMessage)
    }

    // MARK: - Private Helpers

    private func extractCategory(from tags: [String: String]) -> String? {
        // Extract OSM category (amenity, shop, etc.)
        return tags["amenity"] ?? tags["shop"] ?? tags["leisure"] ?? tags["tourism"]
    }

    private func extractCategoryGroup(from tags: [String: String]) -> String? {
        if let group = extractAmenityCategoryGroup(from: tags) {
            return group
        }
        if let group = extractShopCategoryGroup(from: tags) {
            return group
        }
        if let group = extractLeisureCategoryGroup(from: tags) {
            return group
        }
        return nil
    }

    private func extractAmenityCategoryGroup(from tags: [String: String]) -> String? {
        guard let amenity = tags["amenity"] else { return nil }
        switch amenity {
        case "restaurant", "cafe", "bar", "pub", "fast_food":
            return "Food & Drink"
        case "climbing_gym", "fitness_centre", "gym":
            return "Sports & Fitness"
        case "hotel", "hostel", "guest_house":
            return "Accommodation"
        default:
            return "Services"
        }
    }

    private func extractShopCategoryGroup(from tags: [String: String]) -> String? {
        return tags["shop"] != nil ? "Shopping" : nil
    }

    private func extractLeisureCategoryGroup(from tags: [String: String]) -> String? {
        guard let leisure = tags["leisure"] else { return nil }
        switch leisure {
        case "climbing", "fitness_centre", "sports_centre":
            return "Sports & Fitness"
        case "park", "garden":
            return "Outdoors"
        default:
            return "Recreation"
        }
    }

    private func extractCategoryIcon(from tags: [String: String]) -> String? {
        if let icon = extractAmenityCategoryIcon(from: tags) {
            return icon
        }
        if let icon = extractShopCategoryIcon(from: tags) {
            return icon
        }
        if let icon = extractLeisureCategoryIcon(from: tags) {
            return icon
        }
        return nil
    }

    private func extractAmenityCategoryIcon(from tags: [String: String]) -> String? {
        guard let amenity = tags["amenity"] else { return nil }
        switch amenity {
        case "restaurant": return "🍽️"
        case "cafe": return "☕"
        case "bar", "pub": return "🍺"
        case "fast_food": return "🍔"
        case "climbing_gym": return "🧗‍♂️"
        case "fitness_centre", "gym": return "💪"
        case "hotel", "hostel", "guest_house": return "🏨"
        default: return nil
        }
    }

    private func extractShopCategoryIcon(from tags: [String: String]) -> String? {
        return tags["shop"] != nil ? "🏪" : nil
    }

    private func extractLeisureCategoryIcon(from tags: [String: String]) -> String? {
        guard let leisure = tags["leisure"] else { return nil }
        switch leisure {
        case "climbing": return "🧗‍♂️"
        case "fitness_centre", "sports_centre": return "💪"
        case "park", "garden": return "🌳"
        default: return "🎯"
        }
    }
}
