import Foundation

/// Manages session cookies for authentication
///
/// Centralizes cookie creation, storage, and retrieval logic that was previously
/// duplicated across multiple components. Provides both protocol abstraction for
/// testing and a production implementation using HTTPCookieStorage.
public protocol CookieManagerProtocol: Sendable {
    /// Save a session cookie with the given session token and expiration
    /// - Parameters:
    ///   - sessionToken: The session ID token value
    ///   - expiresAt: When the session expires
    ///   - domain: The cookie domain (e.g., "dropanchor.app")
    func saveSessionCookie(sessionToken: String, expiresAt: Date, domain: String)

    /// Clear the session cookie from storage
    /// - Parameter domain: The cookie domain to clear
    func clearSessionCookie(domain: String)

    /// Check if a valid session cookie exists
    /// - Parameter domain: The cookie domain to check
    /// - Returns: True if a valid session cookie is present
    func hasValidSessionCookie(domain: String) -> Bool
}

/// Production implementation of CookieManagerProtocol using HTTPCookieStorage
public final class HTTPCookieManager: CookieManagerProtocol, @unchecked Sendable {
    private let cookieStorage: HTTPCookieStorage
    private let cookieName: String

    public init(
        cookieStorage: HTTPCookieStorage = .shared,
        cookieName: String = "sid"
    ) {
        self.cookieStorage = cookieStorage
        self.cookieName = cookieName
    }

    public func saveSessionCookie(sessionToken: String, expiresAt: Date, domain: String) {
        let cookie = HTTPCookie(properties: [
            .name: cookieName,
            .value: sessionToken,
            .domain: domain,
            .path: "/",
            .secure: true,
            .expires: expiresAt
        ])

        if let cookie = cookie {
            cookieStorage.setCookie(cookie)
            debugPrint("🍪 Set '\(cookieName)' cookie for \(domain)")
        } else {
            debugPrint("⚠️ Failed to create session cookie")
        }
    }

    public func clearSessionCookie(domain: String) {
        if let cookies = cookieStorage.cookies(for: URL(string: "https://\(domain)")!) {
            for cookie in cookies where cookie.name == cookieName {
                cookieStorage.deleteCookie(cookie)
                debugPrint("🍪 Cleared '\(cookieName)' cookie for \(domain)")
            }
        }
    }

    public func hasValidSessionCookie(domain: String) -> Bool {
        guard let cookies = cookieStorage.cookies(for: URL(string: "https://\(domain)")!) else {
            return false
        }

        return cookies.contains { cookie in
            cookie.name == cookieName &&
            (cookie.expiresDate == nil || cookie.expiresDate! > Date())
        }
    }
}

/// Mock implementation for testing
public final class MockCookieManager: CookieManagerProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var _savedCookies: [(token: String, expiresAt: Date, domain: String)] = []
    private var _clearedDomains: [String] = []
    private var _mockHasValidCookie = false

    public var savedCookies: [(token: String, expiresAt: Date, domain: String)] {
        lock.lock()
        defer { lock.unlock() }
        return _savedCookies
    }

    public var clearedDomains: [String] {
        lock.lock()
        defer { lock.unlock() }
        return _clearedDomains
    }

    public var mockHasValidCookie: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _mockHasValidCookie
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _mockHasValidCookie = newValue
        }
    }

    public init() {}

    public func saveSessionCookie(sessionToken: String, expiresAt: Date, domain: String) {
        lock.lock()
        defer { lock.unlock() }
        _savedCookies.append((sessionToken, expiresAt, domain))
    }

    public func clearSessionCookie(domain: String) {
        lock.lock()
        defer { lock.unlock() }
        _clearedDomains.append(domain)
    }

    public func hasValidSessionCookie(domain: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return _mockHasValidCookie
    }
}
