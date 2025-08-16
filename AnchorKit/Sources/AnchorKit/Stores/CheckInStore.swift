import Foundation

// MARK: - Check-In Store Protocol

@MainActor
public protocol CheckInStoreProtocol {
    func createCheckin(place: Place, customMessage: String?) async throws -> CheckinResult
}

// MARK: - Check-In Store

/// Check-in creation and management store using Anchor checkins service
///
/// **BACKEND ARCHITECTURE:**
/// This store creates check-ins by calling the Anchor backend API, which handles:
///
/// 1. **Authentication**: Uses OAuth session cookies for secure API access
/// 2. **StrongRef Creation**: Backend creates address + checkin records on user's PDS
/// 3. **Content Integrity**: Backend handles CID verification and atomic operations
///
/// **Note:** Authentication is handled by AuthStore, checkin creation by AnchorCheckinsService.
@MainActor
@Observable
public final class CheckInStore: CheckInStoreProtocol {
    // MARK: - Properties

    private let authStore: AuthStoreProtocol
    private let checkinsService: AnchorCheckinsServiceProtocol

    // MARK: - Initialization

    /// Convenience initializer for production use with AuthStore
    public convenience init(authStore: AuthStoreProtocol, session: URLSessionProtocol = URLSession.shared) {
        let checkinsService = AnchorCheckinsService(session: session, authStore: authStore)
        self.init(authStore: authStore, checkinsService: checkinsService)
    }

    public init(authStore: AuthStoreProtocol, checkinsService: AnchorCheckinsServiceProtocol) {
        self.authStore = authStore
        self.checkinsService = checkinsService
    }

    // MARK: - Check-ins

    public func createCheckin(place: Place, customMessage: String?) async throws -> CheckinResult {
        print("🔰 CheckInStore: Starting checkin creation for place: \(place.name)")

        // Get valid credentials from AuthStore (handles refresh automatically)
        print("🔰 CheckInStore: Getting valid credentials from AuthStore")
        let activeCredentials = try await authStore.getValidCredentials()

        print("🔰 CheckInStore: Got credentials for handle: \(activeCredentials.handle)")
        print("🔰 CheckInStore: DID: \(activeCredentials.did)")
        print("🔰 CheckInStore: Access token present: \(!activeCredentials.accessToken.isEmpty)")

        // Use OAuth access token for Bearer authentication (OAuth 2.1 standard)
        let accessToken = activeCredentials.accessToken
        print("🔰 CheckInStore: Using OAuth Bearer token: \(accessToken.prefix(8))...")

        // Create checkin using OAuth Bearer token authentication
        print("🔰 CheckInStore: Calling checkins service to create checkin")
        let result = try await checkinsService.createCheckin(
            place: place,
            message: customMessage,
            accessToken: accessToken
        )

        print("✅ CheckInStore: Checkin creation successful: \(result.success)")
        if let checkinId = result.checkinId {
            print("✅ CheckInStore: Checkin ID: \(checkinId)")
        }
        return result
    }
}

// MARK: - Check-In Errors

/// Errors that can occur during check-in creation
public enum CheckInError: Error, LocalizedError {
    case missingAccessToken
    case authenticationFailed

    public var errorDescription: String? {
        switch self {
        case .missingAccessToken:
            return "OAuth access token required for authentication"
        case .authenticationFailed:
            return "Authentication failed"
        }
    }
}
