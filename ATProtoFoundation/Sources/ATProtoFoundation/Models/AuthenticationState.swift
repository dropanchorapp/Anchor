import Foundation

/// Represents the explicit state of the authentication flow
///
/// Replaces implicit boolean `isAuthenticated` state with a proper state machine
/// that makes the OAuth flow clear, debuggable, and easier to reason about.
///
/// State Transitions:
/// - unauthenticated → authenticating (user starts OAuth)
/// - authenticating → authenticated (OAuth succeeds)
/// - authenticating → error (OAuth fails)
/// - authenticated → refreshing (proactive token refresh)
/// - authenticated → sessionExpired (token expired)
/// - sessionExpired → refreshing (attempting refresh)
/// - refreshing → authenticated (refresh succeeds)
/// - refreshing → error (refresh fails)
/// - any state → unauthenticated (sign out)
public enum AuthenticationState: Sendable {
    /// User is not authenticated, needs to sign in
    case unauthenticated

    /// OAuth flow is in progress
    case authenticating

    /// User is successfully authenticated with valid credentials
    case authenticated(credentials: AuthCredentials)

    /// Session has expired but can be refreshed
    case sessionExpired(credentials: AuthCredentials)

    /// Attempting to refresh expired session
    case refreshing(credentials: AuthCredentials)

    /// Authentication error occurred
    case error(AuthenticationError)

    // MARK: - Convenience Properties

    /// Whether the user has valid authentication
    public var isAuthenticated: Bool {
        if case .authenticated = self {
            return true
        }
        return false
    }

    /// Whether authentication is in progress
    public var isLoading: Bool {
        switch self {
        case .authenticating, .refreshing:
            return true
        default:
            return false
        }
    }

    /// Current credentials if available
    public var credentials: AuthCredentials? {
        switch self {
        case .authenticated(let creds),
             .sessionExpired(let creds),
             .refreshing(let creds):
            return creds
        case .unauthenticated, .authenticating, .error:
            return nil
        }
    }

    /// Current error if in error state
    public var error: AuthenticationError? {
        if case .error(let err) = self {
            return err
        }
        return nil
    }

    /// Whether the current state can attempt sign in
    public var canSignIn: Bool {
        switch self {
        case .unauthenticated, .error:
            return true
        default:
            return false
        }
    }
}

/// Errors that can occur during authentication
///
/// Unified error type for all authentication-related failures including OAuth,
/// session management, and credential storage.
public enum AuthenticationError: Error, Equatable, Sendable {
    /// Network request failed
    case networkError(String)

    /// Invalid or malformed authentication data
    case invalidCredentials(String)

    /// Session has expired and refresh failed
    case sessionExpiredUnrecoverable

    /// OAuth flow was cancelled by user
    case userCancelled

    /// Credential storage operation failed
    case storageError(String)

    /// API returned an error status
    case apiError(Int, String)

    /// Unknown or unexpected error
    case unknown(String)

    // MARK: - User-Facing Messages

    /// User-friendly error message
    public var localizedDescription: String {
        switch self {
        case .networkError:
            return "Network error occurred. Please check your connection and try again."
        case .invalidCredentials:
            return "Invalid authentication credentials. Please sign in again."
        case .sessionExpiredUnrecoverable:
            return "Your session has expired. Please sign in again."
        case .userCancelled:
            return "Sign in was cancelled."
        case .storageError:
            return "Failed to save authentication data. Please try again."
        case .apiError(let code, _):
            return "Server error (HTTP \(code)). Please try again."
        case .unknown:
            return "An unexpected error occurred. Please try again."
        }
    }

    /// Whether this error is recoverable (user can retry)
    public var isRecoverable: Bool {
        switch self {
        case .networkError, .userCancelled, .unknown, .storageError, .apiError:
            return true
        case .invalidCredentials, .sessionExpiredUnrecoverable:
            return false
        }
    }
}
