# AnchorKit

Core functionality for location-based check-ins using the AT Protocol.

## Overview

AnchorKit is a reusable Swift package that provides the business logic for Anchor, a location-based check-in app. It's designed to be platform-agnostic and can be used across macOS, iOS, and other Apple platforms.

## Features

- **Location Services**: Proper CoreLocation integration with permission handling
- **OpenStreetMap Integration**: Place discovery via Overpass API with smart caching
- **Bluesky Integration**: AT Protocol authentication and posting
- **Modern Swift**: Uses Swift 6 with strict concurrency and @Observable patterns

## Architecture

### Models

- `Place` - Location data from OpenStreetMap with coordinates and metadata
- `AuthCredentials` - Bluesky authentication with secure storage
- `AnchorSettings` - User preferences and app configuration

### Services

- `LocationService` - CoreLocation wrapper with menubar app permission handling
- `OverpassService` - OpenStreetMap POI queries with intelligent caching
- `BlueskyService` - AT Protocol communication for posts and authentication
- `NearbyPlacesService` - Coordinated location and place discovery

### Key Technologies

- **CoreLocation** - Native macOS/iOS geolocation
- **AT Protocol** - Direct Bluesky integration without third-party SDKs
- **Overpass API** - Rich OpenStreetMap data via `overpass.private.coffee`
- **Swift Concurrency** - Modern async/await patterns throughout

## Usage

```swift
import AnchorKit

// Location services
let locationService = LocationService()
await locationService.requestLocationPermission()

// Find nearby places
let nearbyService = NearbyPlacesService(locationService: locationService)
await nearbyService.searchNearbyPlaces()

// Bluesky integration
let blueskyService = BlueskyService()
try await blueskyService.authenticate(handle: "user.bsky.social", password: "password")
try await blueskyService.postCheckIn(place: selectedPlace, message: "Great climbing session!")
```

## Platform Requirements

- **macOS 14.0+** / **iOS 17.0+**
- **Swift 6.0+**
- **Xcode 15.0+**

## Dependencies

None! AnchorKit uses only Apple's built-in frameworks to keep the package lightweight and reduce external dependencies.
