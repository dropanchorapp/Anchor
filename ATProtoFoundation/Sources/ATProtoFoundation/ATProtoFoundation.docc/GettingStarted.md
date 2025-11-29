# Getting Started with ATProtoFoundation

Learn how to set up and use ATProtoFoundation in your iOS app.

## Overview

ATProtoFoundation provides the core building blocks for AT Protocol applications. This guide walks you through the basic setup and common use cases.

## Adding the Package

Add ATProtoFoundation to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/tijs/ATProtoFoundation.git", from: "1.0.0")
]
```

Or add it via Xcode: **File → Add Package Dependencies** → Enter the repository URL.

## Working with Rich Text Records

AT Protocol supports rich text through facets - annotations that mark regions of text as links, mentions, or hashtags.

### Creating a Record with Facets

```swift
import ATProtoFoundation

// Create a mention facet
let mentionFacet = ATProtoFacet(
    index: 10...25,  // Character range in the text
    feature: .mention("did:plc:abc123")
)

// Create the record
let record = BlueskyPostRecord(
    text: "Check out @username.bsky.social's post!",
    facets: [mentionFacet]
)

// Get markdown-formatted text for display
print(record.formattedText)
// Output: Check out [@username.bsky.social](https://bsky.app/profile/did:plc:abc123)'s post!
```

### Parsing Timeline Responses

When receiving data from AT Protocol APIs, use ``TimelineRecord`` to parse the response:

```swift
let jsonData = /* ... from API ... */
let timelineRecord = try JSONDecoder().decode(TimelineRecord.self, from: jsonData)

// Convert to BlueskyPostRecord for rich text processing
let record = BlueskyPostRecord(from: timelineRecord)
```

## Authentication with BFF Pattern

ATProtoFoundation uses the Backend-For-Frontend (BFF) pattern for OAuth, where sensitive tokens are managed server-side using HttpOnly cookies.

### Setting Up the OAuth Coordinator

```swift
import ATProtoFoundation

// Use keychain storage for production
let storage = KeychainCredentialsStorage()

// Configure OAuth settings
let config = OAuthConfiguration(
    baseURL: URL(string: "https://your-backend.app")!,
    userAgent: "YourApp/1.0 (iOS)",
    sessionCookieName: "sid",
    cookieDomain: "your-backend.app",
    callbackURLScheme: "your-app"
)

let coordinator = MobileOAuthCoordinator(
    storage: storage,
    config: config
)
```

### Handling the OAuth Flow

```swift
// 1. Start the OAuth flow - returns a URL to present in a web view
let authURL = try await coordinator.startOAuthFlow()

// 2. Present authURL in a web view...

// 3. Handle the callback URL when received
try await coordinator.completeOAuthFlow(callbackURL: callbackURL)

// 4. Credentials are now stored and can be refreshed
let credentials = try await coordinator.refreshSession()
```

## Date Parsing

AT Protocol APIs return dates in ISO8601 format with varying precision. Use the flexible date parser:

```swift
// Handles both formats:
// - With fractional seconds: "2025-01-15T12:30:45.123Z"
// - Without fractional seconds: "2025-01-15T12:30:45Z"
if let date = ISO8601DateFormatter.flexibleDate(from: dateString) {
    print(date)
}
```

## Lexicon Constants

Use predefined constants for AT Protocol lexicon identifiers:

```swift
// Bluesky lexicons
let postType = BlueskyLexicon.feedPost  // "app.bsky.feed.post"
let linkType = BlueskyLexicon.richTextLink  // "app.bsky.richtext.facet#link"

// Community lexicons
let geoType = CommunityLexicon.locationGeo  // "community.lexicon.location.geo"
```
