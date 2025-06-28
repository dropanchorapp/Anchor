import Foundation

/// Utilities for discovering and managing multiple PDS servers
public final class PDSDiscovery: @unchecked Sendable {
    
    // MARK: - PDS Discovery
    
    /// Discover the PDS URL for a given handle or DID
    /// - Parameter identifier: Handle (user.bsky.social) or DID (did:plc:...)
    /// - Returns: PDS URL or nil if discovery fails
    public static func discoverPDS(for identifier: String) async -> String? {
        print("🔍 [PDSDiscovery] Discovering PDS for: \(identifier)")
        
        // If it's a DID, resolve it directly
        if identifier.hasPrefix("did:") {
            let pdsURL = await resolveDIDToPDS(identifier)
            if let pdsURL = pdsURL {
                print("✅ [PDSDiscovery] Resolved DID to PDS: \(pdsURL)")
            } else {
                print("❌ [PDSDiscovery] Failed to resolve DID to PDS: \(identifier)")
            }
            return pdsURL
        }
        
        // If it's a handle, resolve it to DID first, then to PDS
        if let did = await resolveHandleToDID(identifier) {
            print("✅ [PDSDiscovery] Resolved handle to DID: \(did)")
            let pdsURL = await resolveDIDToPDS(did)
            if let pdsURL = pdsURL {
                print("✅ [PDSDiscovery] Resolved DID to PDS: \(pdsURL)")
            } else {
                print("❌ [PDSDiscovery] Failed to resolve DID to PDS: \(did)")
            }
            return pdsURL
        }
        
        print("❌ [PDSDiscovery] Failed to resolve handle to DID: \(identifier)")
        return nil
    }
    
    /// Extract the PDS URL from user's handle domain
    /// - Parameter handle: User handle (e.g., "user.bsky.social")
    /// - Returns: Potential PDS URL based on handle domain
    public static func guessPDSFromHandle(_ handle: String) -> String? {
        let components = handle.split(separator: ".")
        guard components.count >= 2 else { return nil }
        
        // If it's a bsky.social handle, use Bluesky PDS
        if handle.hasSuffix(".bsky.social") {
            return AnchorConfig.shared.blueskyPDSURL
        }
        
        // For other domains, try constructing PDS URL
        let domain = components.dropFirst().joined(separator: ".")
        return "https://\(domain)"
    }
    
    // MARK: - Private Resolution Methods
    
    private static func resolveHandleToDID(_ handle: String) async -> String? {
        // Try DNS-based resolution first
        if let did = await resolveDIDViaDNS(handle) {
            return did
        }
        
        // Fallback to HTTP well-known resolution
        return await resolveDIDViaHTTP(handle)
    }
    
    private static func resolveDIDViaDNS(_ handle: String) async -> String? {
        // DNS TXT record resolution for _atproto.{handle}
        // This would require DNS resolution capabilities
        // For now, return nil to fallback to HTTP
        return nil
    }
    
    private static func resolveDIDViaHTTP(_ handle: String) async -> String? {
        let components = handle.split(separator: ".")
        guard components.count >= 2 else { return nil }
        
        let domain = components.dropFirst().joined(separator: ".")
        let url = "https://\(domain)/.well-known/atproto-did"
        
        do {
            guard let requestURL = URL(string: url) else { return nil }
            let (data, _) = try await URLSession.shared.data(from: requestURL)
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }
    
    private static func resolveDIDToPDS(_ did: String) async -> String? {
        // Resolve DID document to get PDS service endpoint
        let url = "https://plc.directory/\(did)"
        
        do {
            guard let requestURL = URL(string: url) else { 
                print("❌ [PDSDiscovery] Invalid DID directory URL: \(url)")
                return nil 
            }
            
            print("🌐 [PDSDiscovery] Fetching DID document from: \(url)")
            let (data, response) = try await URLSession.shared.data(from: requestURL)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 [PDSDiscovery] DID directory response status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    if let errorData = String(data: data, encoding: .utf8) {
                        print("❌ [PDSDiscovery] DID directory error: \(errorData)")
                    }
                    return nil
                }
            }
            
            // Parse DID document JSON
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("❌ [PDSDiscovery] Failed to parse DID document JSON")
                return nil
            }
            
            guard let services = json["service"] as? [[String: Any]] else {
                print("❌ [PDSDiscovery] No services found in DID document")
                return nil
            }
            
            print("🔍 [PDSDiscovery] Found \(services.count) services in DID document")
            
            // Find the ATProto PDS service
            for service in services {
                if let serviceType = service["type"] as? String,
                   serviceType == "AtprotoPersonalDataServer",
                   let serviceEndpoint = service["serviceEndpoint"] as? String {
                    print("✅ [PDSDiscovery] Found PDS service: \(serviceEndpoint)")
                    return serviceEndpoint
                }
            }
            
            print("❌ [PDSDiscovery] No AtprotoPersonalDataServer service found in DID document")
            return nil
        } catch {
            print("❌ [PDSDiscovery] Error resolving DID to PDS: \(error)")
            return nil
        }
    }
}

// MARK: - Multi-PDS Client

/// Client that supports multiple PDS servers with fallback behavior
@MainActor
public final class MultiPDSClient: @unchecked Sendable {
    
    private let session: URLSessionProtocol
    private let timeout: TimeInterval
    
    public init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
        self.timeout = AnchorConfig.shared.pdsTimeoutSeconds
    }
    
    /// Try an operation on the user's PDS first, then fallback to Bluesky PDS
    /// - Parameters:
    ///   - credentials: User credentials containing their PDS URL
    ///   - operation: The operation to perform, given a base URL
    /// - Returns: Result of the operation
    public func tryWithFallback<T: Sendable>(
        credentials: AuthCredentialsProtocol,
        operation: @escaping @Sendable (String) async throws -> T
    ) async throws -> T {
        
        // First try: User's PDS
        let userPDS = credentials.pdsURL
        do {
            return try await withTimeout(timeout) {
                try await operation(userPDS)
            }
        } catch {
            print("Operation failed on user PDS (\(credentials.pdsURL)): \(error)")
            
            // Second try: Bluesky PDS (if different)
            let blueskyPDS = AnchorConfig.shared.blueskyPDSURL
            if userPDS != blueskyPDS {
                do {
                    return try await withTimeout(timeout) {
                        try await operation(blueskyPDS)
                    }
                } catch {
                    print("Operation failed on Bluesky PDS: \(error)")
                    throw error
                }
            } else {
                // User's PDS is Bluesky, so just rethrow the original error
                throw error
            }
        }
    }
    
    /// Try to get profile info from the user's home PDS first, then fallback to Bluesky
    /// - Parameters:
    ///   - did: The DID to get profile info for
    ///   - accessToken: Access token for authentication
    ///   - fallbackPDS: Optional fallback PDS URL (defaults to Bluesky)
    /// - Returns: Profile information or nil if not found
    public func getProfileInfo(for did: String, accessToken: String? = nil, fallbackPDS: String? = nil) async -> BlueskyProfileInfo? {
        print("🔍 [MultiPDSClient] Getting profile info for DID: \(did)")
        
        // Try to discover the user's PDS
        if let userPDS = await PDSDiscovery.discoverPDS(for: did) {
            print("🔍 [MultiPDSClient] Discovered user PDS: \(userPDS)")
            if let profile = await tryGetProfile(from: userPDS, did: did, accessToken: accessToken) {
                print("✅ [MultiPDSClient] Got profile from user PDS: @\(profile.handle)")
                return profile
            }
            print("❌ [MultiPDSClient] Failed to get profile from user PDS: \(userPDS)")
        } else {
            print("🔍 [MultiPDSClient] Could not discover PDS for DID: \(did)")
        }
        
        // Fallback to specified PDS or Bluesky
        let fallback = fallbackPDS ?? AnchorConfig.shared.blueskyPDSURL
        print("🔍 [MultiPDSClient] Trying fallback PDS: \(fallback)")
        
        if let profile = await tryGetProfile(from: fallback, did: did, accessToken: accessToken) {
            print("✅ [MultiPDSClient] Got profile from fallback PDS: @\(profile.handle)")
            return profile
        }
        
        print("❌ [MultiPDSClient] Failed to get profile from all PDSs for DID: \(did)")
        return nil
    }
    
    private func tryGetProfile(from pdsURL: String, did: String, accessToken: String? = nil) async -> BlueskyProfileInfo? {
        do {
            let apiURL = pdsURL.hasSuffix("/") ? String(pdsURL.dropLast()) : pdsURL
            guard let url = URL(string: "\(apiURL)/xrpc/app.bsky.actor.getProfile?actor=\(did)") else {
                print("❌ [MultiPDSClient] Invalid URL for PDS: \(pdsURL)")
                return nil
            }
            
            var request = URLRequest(url: url)
            request.timeoutInterval = timeout
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Anchor/1.0", forHTTPHeaderField: "User-Agent")
            
            // Add authentication if access token is provided
            if let accessToken = accessToken {
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                print("🔐 [MultiPDSClient] Added authorization header for request")
            } else {
                print("⚠️ [MultiPDSClient] Making unauthenticated request (no access token provided)")
            }
            
            print("🌐 [MultiPDSClient] Making request to: \(url)")
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [MultiPDSClient] Invalid HTTP response for \(url)")
                return nil
            }
            
            print("📡 [MultiPDSClient] Response status: \(httpResponse.statusCode) for \(url)")
            
            guard httpResponse.statusCode == 200 else {
                if let errorData = String(data: data, encoding: .utf8) {
                    print("❌ [MultiPDSClient] HTTP \(httpResponse.statusCode) error: \(errorData)")
                }
                return nil
            }
            
            let profileResponse = try JSONDecoder().decode(BlueskyProfileResponse.self, from: data)
            
            return BlueskyProfileInfo(
                did: profileResponse.did,
                handle: profileResponse.handle,
                displayName: profileResponse.displayName,
                avatar: profileResponse.avatar
            )
            
        } catch {
            print("❌ [MultiPDSClient] Error getting profile from \(pdsURL): \(error)")
            return nil
        }
    }
    
    private func withTimeout<T: Sendable>(_ timeout: TimeInterval, operation: @escaping @Sendable () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw PDSError.timeout
            }
            
            guard let result = try await group.next() else {
                throw PDSError.timeout
            }
            
            group.cancelAll()
            return result
        }
    }
}

// MARK: - Errors

public enum PDSError: Error, LocalizedError {
    case timeout
    case discoveryFailed
    case invalidDID
    case noServiceEndpoint
    
    public var errorDescription: String? {
        switch self {
        case .timeout:
            return "PDS request timed out"
        case .discoveryFailed:
            return "Failed to discover user's PDS"
        case .invalidDID:
            return "Invalid DID format"
        case .noServiceEndpoint:
            return "No PDS service endpoint found in DID document"
        }
    }
}

// MARK: - Supporting Models

public struct BlueskyProfileResponse: Codable {
    let did: String
    let handle: String
    let displayName: String?
    let avatar: String?
}

public struct BlueskyProfileInfo: Sendable {
    public let did: String
    public let handle: String
    public let displayName: String?
    public let avatar: String?
    
    public init(did: String, handle: String, displayName: String?, avatar: String?) {
        self.did = did
        self.handle = handle
        self.displayName = displayName
        self.avatar = avatar
    }
} 
