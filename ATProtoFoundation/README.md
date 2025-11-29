# ATProtoFoundation

A Swift package providing foundational types and utilities for building AT Protocol (atproto) iOS applications.

## Requirements

- Swift 6.0+
- iOS 18.0+ / macOS 14.0+

## Installation

### Swift Package Manager

Add ATProtoFoundation to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/tijs/ATProtoFoundation.git", from: "1.0.0")
]
```

Or add it via Xcode: File → Add Package Dependencies → Enter the repository URL.

## Features

### Models

#### ATProtoRecord & Facets

Types for working with AT Protocol records and rich text facets:

```swift
import ATProtoFoundation

// Create a record with rich text
let facet = ATProtoFacet(
    index: 10...28,
    feature: .link("https://example.com")
)
let record = ATProtoRecord(
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

// Convert to rich ATProtoRecord with facets
let atRecord = ATProtoRecord(from: record)
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

#### Iron Session OAuth

Backend-For-Frontend (BFF) pattern OAuth implementation using HttpOnly cookies:

```swift
let coordinator = IronSessionMobileOAuthCoordinator(
    storage: KeychainCredentialsStorage(),
    config: .default
)

// Start OAuth flow
let authURL = try await coordinator.startOAuthFlow()

// Handle callback
try await coordinator.completeOAuthFlow(callbackURL: url)

// Refresh session
let credentials = try await coordinator.refreshIronSession()
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

#### IronSessionAPIClient

HTTP client with automatic session management:

```swift
let client = IronSessionAPIClient(
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
