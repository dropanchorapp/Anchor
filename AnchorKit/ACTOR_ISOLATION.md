# Actor Isolation Documentation

This document describes the actor isolation strategy for AnchorKit, preparing the codebase for Swift 6.2's approachable concurrency with default MainActor isolation.

## Overview

AnchorKit uses a deliberate actor isolation strategy to ensure thread safety while maintaining performance. Components are categorized into three isolation domains:

1. **MainActor-isolated**: UI components and observable state
2. **Nonisolated**: CPU-bound utilities that can run on any thread
3. **Unspecified (Default)**: Services that will inherit MainActor isolation when approachable concurrency is enabled

## Nonisolated Components

These components are explicitly marked `nonisolated` because they perform CPU-bound work that should not block the main thread. They are pure functions with no shared mutable state.

### Image Processing (`ImageProcessor.swift`)

**Location**: `Sources/AnchorKit/Utilities/ImageProcessor.swift`

**Nonisolated Functions**:
- `processImageForUpload(_ image:)` - Complete image processing pipeline
- `normalizeOrientation(_ image:)` - EXIF orientation normalization
- `stripEXIFData(from:)` - EXIF metadata removal
- `formatFileSize(_ bytes:)` - Byte count formatting

**Nonisolated Constants**:
- `maxFileSizeBytes` - 5MB upload limit
- `maxDimension` - 2048px maximum dimension

**Rationale**: Image processing (orientation normalization, resizing, compression) is CPU-intensive work that should run off the main thread to prevent UI freezing during photo uploads.

### Rich Text Processing (`RichTextProcessor.swift`)

**Location**: `Sources/AnchorKit/ATProtocol/RichTextProcessor.swift`

**Nonisolated Methods**:
- `detectFacets(in:)` - URL, mention, and hashtag detection via regex
- `buildCheckinText(place:customMessage:)` - Rich text generation with facets

**Rationale**: Regex-based text processing and facet calculation involves string manipulation and pattern matching that can be expensive for long text. Running nonisolated allows this work to happen off the main thread.

### Feed Text Processing (`FeedTextProcessor.swift`)

**Location**: `Sources/AnchorKit/Utils/FeedTextProcessor.swift`

**Nonisolated Methods**:
- `extractPersonalMessage(from:locations:)` - Message extraction from check-in posts
- `extractCategoryIcon(from:)` - Emoji detection and extraction

**Rationale**: Text processing and emoji detection are pure functions that benefit from running off the main thread, especially when processing large feeds with many posts.

### Location Formatting (`LocationFormatter.swift`)

**Location**: `Sources/AnchorKit/Utils/LocationFormatter.swift`

**Nonisolated Methods**:
- `getLocationName(_:)` - Primary location name extraction
- `getLocationAddress(_:)` - Address formatting
- `formatInlineLocationInfo(_:)` - Compact location display
- `formatGeoLocationFooter(_:)` - Coordinate formatting
- `extractCoordinate(from:)` - Coordinate extraction

**Rationale**: Location formatting and extraction are pure data transformations with no UI dependencies, suitable for background execution.

## MainActor-Isolated Components

These components must run on the main thread due to UI updates or observable state management.

### SwiftUI Views

**Location**: `AnchorMobile/Features/**/*View.swift`

All SwiftUI views are implicitly MainActor-isolated:
- `FeedView` - Global check-in feed display
- `CheckInView` - Check-in interface
- `NearbyPlacesView` - Place discovery
- `CheckInComposeView` - Check-in composition
- `SettingsView` - App settings

**Rationale**: SwiftUI views must run on the main thread to update the UI safely.

### Observable Services

**Location**: `Sources/AnchorKit/Services/LocationService.swift`

The `LocationService` class is marked with `@Observable` and must be MainActor-isolated to safely update observable properties that drive SwiftUI views:
- `authorizationStatus` - Location permission state
- `currentLocation` - Current user location
- `isLocationServicesEnabled` - Device location capability

**Rationale**: Observable properties trigger SwiftUI view updates, which must happen on the main thread.

## Default Isolation Components

These components will inherit MainActor isolation when approachable concurrency is enabled. They currently have unspecified isolation.

### Service Layer

**Network Services**:
- `AnchorPlacesService` - POI discovery via Anchor API
- `AnchorCheckinsService` - Check-in creation backend
- `AnchorAppViewService` - Feed retrieval from AppView API
- `ATProtoClient` - AT Protocol client operations
- `CategoryCacheService` - Category metadata caching

**Store Layer**:
- `CheckInStore` - Check-in business logic
- `FeedStore` - Feed management

**Rationale**: These services coordinate async operations and may need to update observable state. Default MainActor isolation simplifies reasoning about state updates.

### Authentication

**Services**:
- `ATProtoAuthService` - AT Protocol authentication
- `BlueskyPostService` - Bluesky social posting

**Models**:
- `AuthCredentials` (SwiftData @Model) - Credential persistence
- `AnchorSettings` (SwiftData @Model) - User preferences

**Rationale**: Authentication state and settings are accessed from UI contexts and benefit from MainActor isolation.

## Migration to Approachable Concurrency

When enabling Swift 6.2 approachable concurrency (`.defaultIsolation(MainActor.self)`):

### What Will Change

1. **Default isolation**: All types without explicit isolation will become MainActor-isolated
2. **Cross-context calls**: Calling nonisolated code from MainActor contexts will require `await`
3. **Service access**: Services accessed from views will remain on MainActor (no change)

### What Won't Change

1. **Nonisolated utilities**: Already marked, will continue running off-main-thread
2. **SwiftUI views**: Already MainActor-isolated implicitly
3. **Observable services**: Already should be MainActor-isolated

### Testing Strategy

- ✅ **Complete**: All tests migrated to Swift Testing (60/60 tests)
- ✅ **Complete**: Swift Testing supports MainActor default isolation
- ✅ **Complete**: Tests use unique UserDefaults suite names for parallel execution

## Best Practices

### When to Use Nonisolated

Mark code as `nonisolated` when:
1. **CPU-bound work**: Image processing, text parsing, data transformation
2. **Pure functions**: No shared mutable state, deterministic output
3. **No UI dependencies**: Doesn't update SwiftUI views or observable state

### When to Keep MainActor Isolation

Keep MainActor isolation (default) when:
1. **UI updates**: Directly or indirectly updates SwiftUI views
2. **Observable state**: Manages `@Observable` or `@Published` properties
3. **Coordination logic**: Orchestrates multiple async operations with state

### Cross-Context Guidelines

When calling nonisolated code from MainActor context:

```swift
// Good: Explicit await for nonisolated work
let processedData = await ImageProcessor.processImageForUpload(image)

// Good: Nonisolated utilities called from nonisolated context
func processInBackground(text: String) {
    let facets = RichTextProcessor().detectFacets(in: text)
}
```

## Future Considerations

### Service Isolation Review

Some services may benefit from explicit `nonisolated` or actor isolation:

1. **AnchorPlacesService**: Network requests could be nonisolated if state is removed
2. **CategoryCacheService**: Caching logic could benefit from custom actor
3. **ATProtoClient**: May need actor for connection pooling

These should be evaluated case-by-case based on actual usage patterns.

### Protocol Evolution

As approachable concurrency matures, consider:
- Protocol requirements for isolation
- Sendable conformance for all model types
- Actor-based service architectures for complex state management

## References

- [Swift 6.2 Approachable Concurrency](https://useyourloaf.com/blog/approachable-concurrency-in-swift-packages/)
- [Swift Testing Migration Guide](https://developer.apple.com/documentation/testing)
- [Swift Concurrency Best Practices](https://developer.apple.com/documentation/swift/concurrency)
