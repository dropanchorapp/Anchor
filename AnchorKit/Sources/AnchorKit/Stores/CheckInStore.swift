import Foundation

// MARK: - Check-In Store Protocol

@MainActor
public protocol CheckInStoreProtocol {
    func createCheckin(
        place: Place,
        customMessage: String?,
        imageData: Data?,
        imageAlt: String?
    ) async throws -> CheckinResult
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
        let checkinsService = AnchorCheckinsService(session: session)
        self.init(authStore: authStore, checkinsService: checkinsService)
    }

    public init(authStore: AuthStoreProtocol, checkinsService: AnchorCheckinsServiceProtocol) {
        self.authStore = authStore
        self.checkinsService = checkinsService
    }

    // MARK: - Check-ins

    public func createCheckin(
        place: Place,
        customMessage: String?,
        imageData: Data? = nil,
        imageAlt: String? = nil
    ) async throws -> CheckinResult {
        debugPrint("🔰 CheckInStore: Starting checkin creation for place: \(place.name)")

        // Verify user is authenticated (Iron Session handles token management internally)
        guard authStore.isAuthenticated else {
            debugPrint("❌ CheckInStore: User not authenticated")
            throw CheckInError.notAuthenticated
        }

        debugPrint("🔰 CheckInStore: User authenticated with handle: \(authStore.handle ?? "unknown")")

        if imageData != nil {
            debugPrint("🔰 CheckInStore: Including image attachment")
        }

        // Create checkin using Iron Session authentication (handles tokens automatically)
        debugPrint("🔰 CheckInStore: Calling checkins service to create checkin")
        let result = try await checkinsService.createCheckin(
            place: place,
            message: customMessage,
            imageData: imageData,
            imageAlt: imageAlt
        )

        debugPrint("✅ CheckInStore: Checkin creation successful: \(result.success)")
        if let checkinId = result.checkinId {
            debugPrint("✅ CheckInStore: Checkin ID: \(checkinId)")
        }
        return result
    }
}

// MARK: - Check-In Errors

/// Errors that can occur during check-in creation
public enum CheckInError: Error, LocalizedError {
    case notAuthenticated
    case authenticationFailed

    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .authenticationFailed:
            return "Authentication failed"
        }
    }
}
