import Foundation

/// Shared configuration manager for Anchor app settings
public final class AnchorConfig: @unchecked Sendable {
    public static let shared = AnchorConfig()

    private init() {}

    // MARK: - Network Configuration

    /// The custom Anchor PDS URL for check-in records
    public var anchorPDSURL: String {
        "https://anchorpds.val.run"
    }

    /// The default/fallback Bluesky PDS URL for AT Protocol communication
    public var blueskyPDSURL: String {
        "https://bsky.social"
    }

    /// Popular AT Protocol PDS servers for user selection
    public var availablePDSServers: [PDSServer] {
        [
            PDSServer(name: "Bluesky", url: "https://bsky.social", isDefault: true),
            PDSServer(name: "Custom PDS", url: "", isDefault: false) // User-configurable
        ]
    }

    // MARK: - App Settings

    /// Default message for check-ins
    public var defaultCheckInMessage: String {
        "Dropped ⚓"
    }

    /// Maximum number of nearby places to fetch
    public var maxNearbyPlaces: Int {
        50
    }

    /// Location search radius in meters
    public var locationSearchRadius: Int {
        1000
    }

    /// Overpass API timeout in seconds
    public var overpassTimeout: Int {
        10
    }

    /// Network timeout for PDS fallback attempts (seconds)
    public var pdsTimeoutSeconds: Double {
        5.0
    }
    
    // MARK: - DNS Configuration
    
    /// Primary DNS-over-HTTPS provider for AT Protocol DNS resolution
    /// Cloudflare's public DNS service (free for public use)
    public var primaryDNSOverHTTPSURL: String {
        "https://cloudflare-dns.com/dns-query"
    }
    
    /// Fallback DNS-over-HTTPS provider
    /// Google's public DNS service as backup
    public var fallbackDNSOverHTTPSURL: String {
        "https://dns.google/dns-query"
    }
    
    /// DNS query timeout in seconds
    public var dnsTimeoutSeconds: Double {
        10.0
    }
}

// MARK: - PDS Server Model

public struct PDSServer: Identifiable, Sendable {
    public let id = UUID()
    public let name: String
    public let url: String
    public let isDefault: Bool

    public init(name: String, url: String, isDefault: Bool = false) {
        self.name = name
        self.url = url
        self.isDefault = isDefault
    }
}
