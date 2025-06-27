import Foundation

/// Shared configuration manager for Anchor app settings
public final class AnchorConfig: @unchecked Sendable {
    public static let shared = AnchorConfig()
    
    private let configData: [String: Any]
    
    private init() {
        // Try to load the shared configuration plist from the AnchorKit module bundle
        guard let path = Bundle.module.path(forResource: "AnchorConfig", ofType: "plist"),
              let data = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            print("Warning: Could not load AnchorConfig.plist from AnchorKit module, using default values")
            configData = [:]
            return
        }
        configData = data
    }
    
    // MARK: - Network Configuration
    
    /// The custom Anchor PDS URL for check-in records
    public var anchorPDSURL: String {
        configData["AnchorCustomPDSURL"] as? String ?? "https://anchorpds.val.run"
    }
    
    /// The Bluesky PDS URL for AT Protocol communication
    public var blueskyPDSURL: String {
        configData["BlueskyPDSURL"] as? String ?? "https://bsky.social"
    }
    
    // MARK: - App Settings
    
    /// Default message for check-ins
    public var defaultCheckInMessage: String {
        configData["AnchorDefaultCheckInMessage"] as? String ?? "Dropped anchor here!"
    }
    
    /// Maximum number of nearby places to fetch
    public var maxNearbyPlaces: Int {
        configData["AnchorMaxNearbyPlaces"] as? Int ?? 20
    }
    
    /// Location search radius in meters
    public var locationSearchRadius: Int {
        configData["AnchorLocationSearchRadius"] as? Int ?? 1000
    }
    
    /// Overpass API timeout in seconds
    public var overpassTimeout: Int {
        configData["AnchorOverpassTimeout"] as? Int ?? 10
    }
    
    // MARK: - Convenience Methods
    
    /// Get a string value from the configuration
    public func getString(for key: String) -> String? {
        return configData[key] as? String
    }
    
    /// Get an integer value from the configuration
    public func getInt(for key: String) -> Int? {
        return configData[key] as? Int
    }
    
    /// Get a boolean value from the configuration
    public func getBool(for key: String) -> Bool? {
        return configData[key] as? Bool
    }
    
    /// Get a raw value from the configuration
    public func getValue(for key: String) -> Any? {
        return configData[key]
    }
} 
