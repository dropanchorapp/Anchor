import Foundation
import SwiftData

// MARK: - Bluesky Service Protocol

@MainActor
public protocol BlueskyServiceProtocol {
    var isAuthenticated: Bool { get }
    func loadStoredCredentials(from context: ModelContext) async -> AuthCredentials?
    func authenticate(handle: String, appPassword: String, context: ModelContext) async throws -> Bool
    func signOut(context: ModelContext) async
    func createCheckinWithPost(place: Place, customMessage: String?, context: ModelContext) async throws -> Bool
    func createCheckinWithOptionalPost(place: Place, customMessage: String?, shouldCreatePost: Bool, context: ModelContext) async throws -> Bool
    func buildCheckInTextWithFacets(place: Place, customMessage: String?) -> (text: String, facets: [RichTextFacet])
    func getAppPasswordURL() -> URL
}

// MARK: - Bluesky Service

/// Main Bluesky service that coordinates AT Protocol authentication, posting, and check-ins
@Observable
public final class BlueskyService: BlueskyServiceProtocol {

    // MARK: - Properties

    private let authService: ATProtoAuthServiceProtocol
    private let postService: BlueskyPostServiceProtocol
    private let checkinService: BlueskyCheckinServiceProtocol
    private let richTextProcessor: RichTextProcessorProtocol
    private let anchorPDSService: AnchorPDSServiceProtocol

    /// Whether the user is currently authenticated (observable for UI)
    public var isAuthenticated: Bool = false

    /// Current authentication credentials (synchronous for UI)
    public var credentials: AuthCredentials? {
        authService.credentials
    }

    // MARK: - Initialization

    public convenience init(session: URLSessionProtocol = URLSession.shared) {
        let client = ATProtoClient(session: session)
        let richTextProcessor = RichTextProcessor()
        let authService = ATProtoAuthService(client: client)
        let postService = BlueskyPostService(client: client, richTextProcessor: richTextProcessor)
        let checkinService = BlueskyCheckinService(
            client: client,
            richTextProcessor: richTextProcessor,
            postService: postService
        )
        let anchorPDSService = AnchorPDSService(session: session)

        self.init(
            authService: authService,
            postService: postService,
            checkinService: checkinService,
            richTextProcessor: richTextProcessor,
            anchorPDSService: anchorPDSService
        )
    }

    public init(
        authService: ATProtoAuthServiceProtocol,
        postService: BlueskyPostServiceProtocol,
        checkinService: BlueskyCheckinServiceProtocol,
        richTextProcessor: RichTextProcessorProtocol,
        anchorPDSService: AnchorPDSServiceProtocol
    ) {
        self.authService = authService
        self.postService = postService
        self.checkinService = checkinService
        self.richTextProcessor = richTextProcessor
        self.anchorPDSService = anchorPDSService
    }

    // MARK: - Authentication

    public func loadStoredCredentials(from context: ModelContext) async -> AuthCredentials? {
        let result = await authService.loadStoredCredentials(from: context)
        await updateAuthenticationState()
        return result
    }

    public func authenticate(handle: String, appPassword: String, context: ModelContext) async throws -> Bool {
        _ = try await authService.authenticate(handle: handle, appPassword: appPassword, context: context)
        await updateAuthenticationState()
        return true
    }

    public func signOut(context: ModelContext) async {
        await authService.clearCredentials(from: context)
        await updateAuthenticationState()
    }

    public func getAppPasswordURL() -> URL {
        return URL(string: "https://bsky.app/settings/app-passwords")!
    }

    // MARK: - Check-ins & Posts

    public func createCheckinWithPost(place: Place, customMessage: String?, context: ModelContext) async throws -> Bool {
        // Maintain backward compatibility - always create both check-in and post
        return try await createCheckinWithOptionalPost(place: place, customMessage: customMessage, shouldCreatePost: true, context: context)
    }
    
    public func createCheckinWithOptionalPost(place: Place, customMessage: String?, shouldCreatePost: Bool, context: ModelContext) async throws -> Bool {
        guard let credentials = authService.credentials else {
            throw ATProtoError.missingCredentials
        }

        // Refresh credentials if needed
        var activeCredentials = credentials
        if activeCredentials.isExpired {
            activeCredentials = try await authService.refreshCredentials(activeCredentials, context: context)
        }

        // Step 1: Always create check-in on AnchorPDS
        _ = try await anchorPDSService.createCheckin(
            place: place,
            customMessage: customMessage,
            credentials: activeCredentials
        )
        
        // Step 2: Optionally create post on user's home PDS (Bluesky)
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
        return richTextProcessor.buildCheckinText(place: place, customMessage: customMessage)
    }

    // MARK: - Private Methods

    private func refreshCredentialsIfNeeded(context: ModelContext) async throws -> AuthCredentials {
        guard let credentials = authService.credentials else {
            throw ATProtoError.missingCredentials
        }

        if credentials.isExpired {
            return try await authService.refreshCredentials(credentials, context: context)
        }

        return credentials
    }

    // MARK: - Private Methods

    /// Updates the observable authentication state for UI binding
    @MainActor
    private func updateAuthenticationState() async {
        isAuthenticated = await authService.isAuthenticated
    }
}
