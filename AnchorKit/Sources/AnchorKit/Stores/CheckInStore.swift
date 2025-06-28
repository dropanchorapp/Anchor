import Foundation

// MARK: - Check-In Store Protocol

@MainActor
public protocol CheckInStoreProtocol {
    func createCheckinWithPost(place: Place, customMessage: String?) async throws -> Bool
    func createCheckinWithOptionalPost(place: Place, customMessage: String?, shouldCreatePost: Bool) async throws -> Bool
    func buildCheckInTextWithFacets(place: Place, customMessage: String?) -> (text: String, facets: [RichTextFacet])
}

// MARK: - Check-In Store

/// Check-in creation and management store that handles dual posting architecture
///
/// **DUAL POSTING ARCHITECTURE:**
/// When creating a check-in, this store creates TWO different records:
///
/// 1. **Check-in Record (AnchorPDS)**: Clean user message only
///    - Stores exactly what the user typed, no additional formatting
///    - Location data stored in structured fields, not mixed into text
///    - Used for displaying in app feeds and personal history
///
/// 2. **Social Post (Bluesky)**: Enhanced marketing-friendly version
///    - Includes user message + location tagline + hashtags
///    - Optimized for social media engagement and discovery
///    - Uses rich text formatting and emojis
///
/// This separation allows clean data storage while enabling effective social sharing.
///
/// **Note:** Authentication is handled by AuthStore, not this store.
@MainActor
@Observable
public final class CheckInStore: CheckInStoreProtocol {
    // MARK: - Properties

    private let authStore: AuthStoreProtocol
    private let postService: BlueskyPostServiceProtocol
    private let richTextProcessor: RichTextProcessorProtocol
    private let anchorPDSService: AnchorPDSServiceProtocol

    // MARK: - Initialization

    /// Convenience initializer for production use with AuthStore
    public convenience init(authStore: AuthStoreProtocol, session: URLSessionProtocol = URLSession.shared) {
        let client = ATProtoClient(session: session)
        let richTextProcessor = RichTextProcessor()
        let postService = BlueskyPostService(client: client, richTextProcessor: richTextProcessor)
        let anchorPDSService = AnchorPDSService(session: session)

        self.init(
            authStore: authStore,
            postService: postService,
            richTextProcessor: richTextProcessor,
            anchorPDSService: anchorPDSService
        )
    }

    public init(
        authStore: AuthStoreProtocol,
        postService: BlueskyPostServiceProtocol,
        richTextProcessor: RichTextProcessorProtocol,
        anchorPDSService: AnchorPDSServiceProtocol
    ) {
        self.authStore = authStore
        self.postService = postService
        self.richTextProcessor = richTextProcessor
        self.anchorPDSService = anchorPDSService
    }

    // MARK: - Check-ins & Posts

    public func createCheckinWithPost(place: Place, customMessage: String?) async throws -> Bool {
        // Maintain backward compatibility - always create both check-in and post
        try await createCheckinWithOptionalPost(place: place, customMessage: customMessage, shouldCreatePost: true)
    }

    public func createCheckinWithOptionalPost(place: Place, customMessage: String?, shouldCreatePost: Bool) async throws -> Bool {
        // Get valid credentials from AuthStore (handles refresh automatically)
        let activeCredentials = try await authStore.getValidCredentials()

        // Step 1: Always create check-in record on AnchorPDS
        // This stores ONLY the user's original message (clean, no formatting)
        _ = try await anchorPDSService.createCheckin(
            place: place,
            customMessage: customMessage,
            credentials: activeCredentials
        )

        // Step 2: Optionally create enhanced post on user's home PDS (Bluesky)
        // This includes marketing tagline, location info, and hashtags for social engagement
        if shouldCreatePost {
            let (postText, _) = richTextProcessor.buildCheckinText(place: place, customMessage: customMessage)
            _ = try await postService.createPost(
                text: postText,
                credentials: activeCredentials,
                embedRecord: nil // No embed since check-in is on different PDS
            )
        }

        return true
    }

    // MARK: - Rich Text Processing

    public func buildCheckInTextWithFacets(place: Place, customMessage: String?) -> (text: String, facets: [RichTextFacet]) {
        richTextProcessor.buildCheckinText(place: place, customMessage: customMessage)
    }
}
