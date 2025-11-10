import Foundation

/// Handles session validation and token refresh logic
///
/// Extracted from AuthStore to follow Single Responsibility Principle.
/// Coordinates session validation and refresh operations with the auth service.
public final class SessionValidator: @unchecked Sendable {

    // MARK: - Properties

    private let authService: AnchorAuthServiceProtocol

    // MARK: - Initialization

    public init(authService: AnchorAuthServiceProtocol) {
        self.authService = authService
    }

    // MARK: - Session Validation

    /// Validate session and attempt refresh if validation fails
    /// - Parameters:
    ///   - credentials: Current credentials to validate
    ///   - reason: Reason for validation (for logging)
    ///   - onStateChange: Callback for state changes (refreshing, error)
    /// - Returns: Validated or refreshed credentials, or nil if validation/refresh failed
    public func validateSession(
        _ credentials: AuthCredentials,
        reason: String,
        onStateChange: @escaping @MainActor (SessionValidationState) -> Void
    ) async -> AuthCredentials? {
        do {
            debugPrint("🔍 SessionValidator: Validating session for \(reason)...")
            let validatedCredentials = try await authService.validateSession(credentials)
            debugPrint("✅ SessionValidator: Session validation successful for \(reason)")
            return validatedCredentials
        } catch {
            debugPrint("❌ SessionValidator: Session validation failed for \(reason): \(error)")
            return await attemptTokenRefresh(credentials, reason: reason, onStateChange: onStateChange)
        }
    }

    /// Refresh expired credentials
    /// - Parameters:
    ///   - credentials: Expired credentials to refresh
    ///   - onStateChange: Callback for state changes (refreshing, error)
    /// - Returns: Refreshed credentials
    /// - Throws: Error if refresh fails
    public func refreshCredentials(
        _ credentials: AuthCredentials,
        onStateChange: @escaping @MainActor (SessionValidationState) -> Void
    ) async throws -> AuthCredentials {
        debugPrint("🔄 SessionValidator: Refreshing expired credentials...")
        await onStateChange(.refreshing)

        do {
            let refreshedCredentials = try await authService.refreshTokens(credentials)
            debugPrint("✅ SessionValidator: Credentials refreshed successfully")
            return refreshedCredentials
        } catch {
            debugPrint("❌ SessionValidator: Failed to refresh credentials: \(error)")
            await onStateChange(.refreshFailed(error))
            throw error
        }
    }

    // MARK: - Private Methods

    private func attemptTokenRefresh(
        _ credentials: AuthCredentials,
        reason: String,
        onStateChange: @escaping @MainActor (SessionValidationState) -> Void
    ) async -> AuthCredentials? {
        debugPrint("🔄 SessionValidator: Attempting token refresh as fallback for \(reason)...")
        await onStateChange(.refreshing)

        do {
            let refreshedCredentials = try await authService.refreshTokens(credentials)
            debugPrint("✅ SessionValidator: Token refresh successful as fallback for \(reason)")
            return refreshedCredentials
        } catch {
            debugPrint("❌ SessionValidator: Token refresh failed for \(reason): \(error)")
            await onStateChange(.refreshFailed(error))
            return nil
        }
    }
}

// MARK: - Session Validation State

/// Represents the state during session validation
public enum SessionValidationState: Sendable {
    /// Session is being refreshed
    case refreshing

    /// Session refresh failed
    case refreshFailed(Error)
}
