import Foundation
import CoreLocation

/// Utility for formatting location data consistently across the app
public final class LocationFormatter: Sendable {
    public static let shared = LocationFormatter()
    
    private init() {}
    
    /// Get the primary display name for a location
    /// - Parameter locations: Array of location items
    /// - Returns: The most appropriate name to display
    public func getLocationName(_ locations: [LocationItem]) -> String {
        for location in locations {
            switch location {
            case .address(let addressLocation):
                return addressLocation.name ?? addressLocation.street ?? ""
            case .geo:
                return "" // Geo locations don't have display names
            }
        }
        return "Unknown Location"
    }
    
    /// Get a detailed address string for a location (secondary information)
    /// - Parameter locations: Array of location items
    /// - Returns: Formatted address string or nil if no detailed address available
    public func getLocationAddress(_ locations: [LocationItem]) -> String {
        for location in locations {
            switch location {
            case .address(let addressLocation):
                if let street = addressLocation.street, !street.isEmpty {
                    var address = street
                    if let locality = addressLocation.locality, !locality.isEmpty {
                        address += ", \(locality)"
                    }
                    return address
                }
                return addressLocation.name ?? ""
            case .geo:
                continue // Skip geo locations for address display
            }
        }
        return ""
    }
    
    /// Format location info for inline display (used in compact views)
    /// - Parameter locations: Array of location items
    /// - Returns: Short formatted string for inline display
    public func formatInlineLocationInfo(_ locations: [LocationItem]) -> String {
        let name = getLocationName(locations)
        let address = getLocationAddress(locations)
        
        if !name.isEmpty && !address.isEmpty && name != address {
            return "\(name) • \(address)"
        } else if !name.isEmpty {
            return name
        } else if !address.isEmpty {
            return address
        } else {
            return "Unknown Location"
        }
    }
    
    /// Format geo location info for footer display
    /// - Parameter locations: Array of location items
    /// - Returns: Formatted coordinate string for footer display
    public func formatGeoLocationFooter(_ locations: [LocationItem]) -> String? {
        if let coordinate = extractCoordinate(from: locations) {
            return String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
        }
        return nil
    }
    
    /// Extract coordinate from location items
    /// - Parameter locations: Array of location items
    /// - Returns: CLLocationCoordinate2D if geo location is found
    public func extractCoordinate(from locations: [LocationItem]) -> CLLocationCoordinate2D? {
        for location in locations {
            switch location {
            case .geo(let geoLocation):
                let lat = Double(geoLocation.latitude) ?? 0.0
                let lon = Double(geoLocation.longitude) ?? 0.0
                return CLLocationCoordinate2D(latitude: lat, longitude: lon)
            case .address:
                continue // Address locations don't have coordinates
            }
        }
        return nil
    }
}

// MARK: - CoreLocation Import
#if canImport(CoreLocation)
import CoreLocation
#endif 
