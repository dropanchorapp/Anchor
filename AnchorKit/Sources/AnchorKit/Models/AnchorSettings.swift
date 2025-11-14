//
//  AnchorSettings.swift
//  AnchorKit
//
//  Created by Tijs Teulings on 04/10/2025.
//

import Foundation
import SwiftData

/// User preferences for the Anchor app
@Model
public final class AnchorSettings {

    // MARK: - Provider Preferences

    /// Provider for nearby places browsing (stored as raw string value)
    private var nearbyPlacesProviderRaw: String

    /// Provider for place search (stored as raw string value)
    private var placeSearchProviderRaw: String

    /// Provider for nearby places browsing
    public var nearbyPlacesProvider: PlaceProvider {
        get {
            PlaceProvider(rawValue: nearbyPlacesProviderRaw) ?? .overpass
        }
        set {
            nearbyPlacesProviderRaw = newValue.rawValue
        }
    }

    /// Provider for place search
    public var placeSearchProvider: PlaceProvider {
        get {
            PlaceProvider(rawValue: placeSearchProviderRaw) ?? .nominatim
        }
        set {
            placeSearchProviderRaw = newValue.rawValue
        }
    }

    // MARK: - Initialization

    public init(
        nearbyPlacesProvider: PlaceProvider = .overpass,
        placeSearchProvider: PlaceProvider = .nominatim
    ) {
        self.nearbyPlacesProviderRaw = nearbyPlacesProvider.rawValue
        self.placeSearchProviderRaw = placeSearchProvider.rawValue
    }
}

// MARK: - Place Provider

/// Available place data providers
public enum PlaceProvider: String, CaseIterable, Sendable {
    case overpass
    case locationiq
    case nominatim

    public var displayName: String {
        switch self {
        case .overpass:
            return "Overpass API"
        case .locationiq:
            return "LocationIQ"
        case .nominatim:
            return "Nominatim"
        }
    }

    public var description: String {
        switch self {
        case .overpass:
            return "Direct OpenStreetMap data via Overpass API"
        case .locationiq:
            return "OpenStreetMap data via LocationIQ"
        case .nominatim:
            return "OpenStreetMap geocoding via Nominatim"
        }
    }

    /// Providers available for nearby places browsing
    public static var nearbyProviders: [PlaceProvider] {
        [.overpass, .locationiq]
    }

    /// Providers available for place search
    public static var searchProviders: [PlaceProvider] {
        [.nominatim]
    }
}
