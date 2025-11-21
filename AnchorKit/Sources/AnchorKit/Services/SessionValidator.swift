import Foundation
import ATProtoFoundation

/// Handles session validation and token refresh logic
///
/// Extracted from AuthStore to follow Single Responsibility Principle.
/// Coordinates session validation and refresh operations with the auth service.
public final class SessionValidator: @unchecked Sendable {

    // MARK: - Properties

    private let authService: AnchorAuthServiceProtocol
    private let logger: Logger

    // MARK: - Initialization

    public init(authService: AnchorAuthServiceProtocol, logger: Logger = DebugLogger()) {
        self.authService = authService
        self.logger = logger
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
            logger.log("🔍 Validating session for \(reason)...", level: .debug, category: .session)
            let validatedCredentials = try await authService.validateSession(credentials)
            logger.log("✅ Session validation successful for \(reason)", level: .info, category: .session)
            return validatedCredentials
        } catch {
            logger.log("❌ Session validation failed for \(reason): \(error)", level: .warning, category: .session)
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
        logger.log("🔄 Refreshing expired credentials...", level: .info, category: .session)
        await onStateChange(.refreshing)

        do {
            let refreshedCredentials = try await authService.refreshTokens(credentials)
            logger.log("✅ Credentials refreshed successfully", level: .info, category: .session)
            return refreshedCredentials
        } catch {
            logger.log("❌ Failed to refresh credentials: \(error)", level: .error, category: .session)
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
        logger.log("🔄 Attempting token refresh as fallback for \(reason)...", level: .info, category: .session)
        await onStateChange(.refreshing)

        do {
            let refreshedCredentials = try await authService.refreshTokens(credentials)
            logger.log("✅ Token refresh successful as fallback for \(reason)", level: .info, category: .session)
            return refreshedCredentials
        } catch {
            logger.log("❌ Token refresh failed for \(reason): \(error)", level: .error, category: .session)
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
