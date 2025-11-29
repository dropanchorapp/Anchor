# ATProtoFoundation

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ftijs%2FATProtoFoundation%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/tijs/ATProtoFoundation)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ftijs%2FATProtoFoundation%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/tijs/ATProtoFoundation)

Building blocks for AT Protocol iOS apps. Parse rich text with facets, handle OAuth authentication via a backend, and work with timeline data from Bluesky and other AT Protocol services.

## When to use this package

**Good fit if you:**
- Are building an iOS/macOS app that connects to Bluesky or AT Protocol services
- Need to parse and display rich text posts with links, mentions, and hashtags
- Want BFF (Backend-For-Frontend) OAuth pattern with HttpOnly cookies
- Prefer a lightweight foundation over a full-featured SDK

**Less ideal if you:**
- Need a complete AT Protocol client with all XRPC methods
- Want to run your own PDS or build server-side tooling
- Need cross-platform support beyond Apple platforms

## Requirements

- Swift 6.0+
- iOS 18.0+ / macOS 14.0+

## Installation

### Swift Package Manager

Add ATProtoFoundation to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/tijs/ATProtoFoundation.git", from: "1.1.0")
]
```

Or add it via Xcode: File → Add Package Dependencies → Enter the repository URL.

## Features

### Models

#### BlueskyPostRecord & Facets

Types for working with Bluesky post records and rich text facets:

```swift
import ATProtoFoundation

// Create a record with rich text
let facet = ATProtoFacet(
    index: 10...28,
    feature: .link("https://example.com")
)
let record = BlueskyPostRecord(
    text: "Check out https://example.com for more",
    facets: [facet]
)

// Get markdown-formatted text with clickable links
let formatted = record.formattedText
```

Supported facet features:
- `.link(url)` - External URLs
- `.mention(did)` - AT Protocol user mentions
- `.hashtag(tag)` - Hashtags with search URLs

#### Timeline Models

Types for parsing timeline API responses:

```swift
// Decode timeline data from API
let record = try JSONDecoder().decode(TimelineRecord.self, from: jsonData)

// Convert to rich BlueskyPostRecord with facets
let postRecord = BlueskyPostRecord(from: record)
```

#### Lexicon Constants

Extensible constants for AT Protocol lexicon identifiers:

```swift
// Bluesky lexicons
BlueskyLexicon.feedPost        // "app.bsky.feed.post"
BlueskyLexicon.richTextLink    // "app.bsky.richtext.facet#link"
BlueskyLexicon.richTextMention // "app.bsky.richtext.facet#mention"
BlueskyLexicon.richTextTag     // "app.bsky.richtext.facet#tag"

// Community lexicons
CommunityLexicon.locationGeo     // "community.lexicon.location.geo"
CommunityLexicon.locationAddress // "community.lexicon.location.address"
```

### Authentication

#### BFF OAuth

[Backend-For-Frontend (BFF) pattern](https://atproto.com/specs/oauth) OAuth implementation using HttpOnly cookies. Mobile apps can't safely store private keys, so the [recommended approach](https://github.com/bluesky-social/atproto/blob/main/packages/oauth/oauth-client-node/README.md) is to have a backend server manage OAuth sessions and use session cookies to authenticate the mobile client.

For the server-side implementation, see [@tijs/atproto-oauth](https://github.com/tijs/atproto-oauth) and its [mobile authentication guide](https://github.com/tijs/atproto-oauth/blob/main/docs/mobile-authentication.md):

```swift
let coordinator = MobileOAuthCoordinator(
    storage: KeychainCredentialsStorage(),
    config: .default
)

// Start OAuth flow
let authURL = try await coordinator.startOAuthFlow()

// Handle callback
try await coordinator.completeOAuthFlow(callbackURL: url)

// Refresh session
let credentials = try await coordinator.refreshSession()
```

#### Credentials Storage

Protocol-based storage with multiple implementations:

```swift
// Keychain storage (recommended for production)
let storage = KeychainCredentialsStorage()

// In-memory storage (for testing)
let storage = InMemoryCredentialsStorage()

// Custom storage - implement CredentialsStorageProtocol
```

#### Configuration

Centralized OAuth configuration:

```swift
let config = OAuthConfiguration(
    baseURL: URL(string: "https://your-backend.app")!,
    userAgent: "YourApp/1.0 (iOS)",
    sessionCookieName: "sid",
    cookieDomain: "your-backend.app",
    callbackURLScheme: "your-app",
    sessionDuration: 86400,
    refreshThreshold: 3600,
    maxRetryAttempts: 3,
    maxRetryDelay: 8.0
)
```

### Networking

#### BFFAPIClient

HTTP client with automatic session management:

```swift
let client = BFFAPIClient(
    credentialsStorage: storage,
    config: .default
)

// GET request
let data = try await client.get(endpoint: "/api/endpoint")

// POST request with JSON
let response = try await client.post(
    endpoint: "/api/endpoint",
    body: someEncodable
)
```

### Utilities

#### Date Parsing

Flexible ISO8601 date parsing for API responses:

```swift
// Handles both formats:
// - With fractional seconds: "2025-01-15T12:30:45.123Z"
// - Without fractional seconds: "2025-01-15T12:30:45Z"
let date = ISO8601DateFormatter.flexibleDate(from: dateString)
```

#### Logging

Protocol-based logging with debug and silent implementations:

```swift
// Debug logger (prints to console in debug builds)
let logger = DebugLogger()

// Silent logger (no output)
let logger = SilentLogger()

// Custom logger - implement Logger protocol
```

## Architecture

ATProtoFoundation follows these principles:

- **Protocol-first**: All major components use protocols for testability
- **Dependency injection**: Services accept dependencies through initializers
- **Sendable by default**: Types are designed for Swift 6 strict concurrency
- **No external dependencies**: Uses only Foundation and Security frameworks

## Testing

Run tests:

```bash
swift test
```

The package includes comprehensive tests for all components using Swift Testing framework.

## License

MIT License - see LICENSE file for details.
