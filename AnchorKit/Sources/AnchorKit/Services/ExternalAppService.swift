//
//  ExternalAppService.swift
//  AnchorKit
//
//  Created by Tijs Teulings on 27/06/2025.
//

import Foundation
import CoreLocation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

#if canImport(MapKit)
import MapKit
#endif

/// Service for opening external applications with platform-specific implementations
public final class ExternalAppService: Sendable {
    public static let shared = ExternalAppService()
    
    private init() {}
    
    /// Open a Bluesky profile in the Bluesky app or web browser
    /// - Parameter handle: The user handle (with or without @)
    @MainActor
    public func openBlueskyProfile(handle: String) {
        let cleanHandle = handle.hasPrefix("@") ? String(handle.dropFirst()) : handle
        
        let blueskyURL = URL(string: "bluesky://profile/\(cleanHandle)")
        let webURL = URL(string: "https://bsky.app/profile/\(cleanHandle)")
        
        #if canImport(UIKit)
        if let blueskyURL = blueskyURL, UIApplication.shared.canOpenURL(blueskyURL) {
            UIApplication.shared.open(blueskyURL)
        } else if let webURL = webURL {
            UIApplication.shared.open(webURL)
        }
        #elseif canImport(AppKit)
        if let blueskyURL = blueskyURL, NSWorkspace.shared.urlForApplication(toOpen: blueskyURL) != nil {
            NSWorkspace.shared.open(blueskyURL)
        } else if let webURL = webURL {
            NSWorkspace.shared.open(webURL)
        }
        #endif
    }
    
    /// Open a location in the system Maps app
    /// - Parameters:
    ///   - coordinate: The coordinate to open
    ///   - locationName: Optional name for the location
    @MainActor
    public func openInMaps(coordinate: CLLocationCoordinate2D, locationName: String? = nil) {
        #if canImport(MapKit)
        // Use older API for compatibility
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = locationName ?? "Location"
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsMapTypeKey: MKMapType.standard.rawValue
        ])
        #elseif canImport(AppKit)
        let encodedName = locationName?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Location"
        let mapsURL = URL(string: "http://maps.apple.com/?ll=\(coordinate.latitude),\(coordinate.longitude)&q=\(encodedName)")
        if let mapsURL = mapsURL {
            NSWorkspace.shared.open(mapsURL)
        }
        #endif
    }
    
    /// Open a URL using the system's default handler
    /// - Parameter url: The URL to open
    @MainActor
    public func openURL(_ url: URL) {
        #if canImport(UIKit)
        UIApplication.shared.open(url)
        #elseif canImport(AppKit)
        NSWorkspace.shared.open(url)
        #endif
    }
    
    /// Open a URL string in the default browser or app
    /// - Parameter urlString: The URL string to open
    @MainActor
    public func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        openURL(url)
    }
} 
