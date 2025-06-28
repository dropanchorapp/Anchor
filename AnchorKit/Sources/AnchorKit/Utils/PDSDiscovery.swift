import Foundation

/// Main PDS discovery coordinator
public final class PDSDiscovery: @unchecked Sendable {
    
    /// Discover the PDS URL for a given handle or DID
    /// - Parameter identifier: Handle (user.bsky.social) or DID (did:plc:...)
    /// - Returns: PDS URL or nil if discovery fails
    public static func discoverPDS(for identifier: String) async -> String? {
        print("🔍 [PDSDiscovery] Discovering PDS for: \(identifier)")
        
        // If it's a DID, resolve it directly
        if identifier.hasPrefix("did:") {
            let pdsURL = await DIDResolver.resolveDIDToPDS(identifier)
            if let pdsURL = pdsURL {
                print("✅ [PDSDiscovery] Resolved DID to PDS: \(pdsURL)")
            } else {
                print("❌ [PDSDiscovery] Failed to resolve DID to PDS: \(identifier)")
            }
            return pdsURL
        }
        
        // If it's a handle, resolve it to DID first, then to PDS
        if let did = await DIDResolver.resolveHandleToDID(identifier) {
            print("✅ [PDSDiscovery] Resolved handle to DID: \(did)")
            let pdsURL = await DIDResolver.resolveDIDToPDS(did)
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
} 
