//
//  AnchorSettings.swift
//  AnchorKit
//
//  Created by Tijs Teulings on 04/10/2025.
//

import Foundation

/// User preferences for the Anchor app
@Observable
public final class AnchorSettings {

    // MARK: - Provider Preferences

    /// Provider for nearby places browsing
    public var nearbyPlacesProvider: PlaceProvider {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: Keys.nearbyPlacesProvider),
               let provider = PlaceProvider(rawValue: rawValue) {
                return provider
            }
            return .overpass // Default
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Keys.nearbyPlacesProvider)
        }
    }

    /// Provider for place search
    public var placeSearchProvider: PlaceProvider {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: Keys.placeSearchProvider),
               let provider = PlaceProvider(rawValue: rawValue) {
                return provider
            }
            return .nominatim // Default
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Keys.placeSearchProvider)
        }
    }

    // MARK: - Initialization

    public init() {}

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let nearbyPlacesProvider = "nearbyPlacesProvider"
        static let placeSearchProvider = "placeSearchProvider"
    }
}

// MARK: - Place Provider

/// Available place data providers
public enum PlaceProvider: String, CaseIterable, Sendable {
    case overpass = "overpass"
    case locationiq = "locationiq"
    case nominatim = "nominatim"

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
