# Anchor

<p align="center">
  <img src="Static/anchor-logo-transparent.png" alt="Anchor Logo" width="200"/>
</p>

<p align="center">
  <strong>Native iOS app for location-based check-ins using the AT Protocol</strong>
</p>

<p align="center">
  <a href="https://github.com/dropanchorapp/Anchor/actions/workflows/tests.yml">
    <img src="https://github.com/dropanchorapp/Anchor/actions/workflows/tests.yml/badge.svg" alt="Tests">
  </a>
  <a href="https://github.com/dropanchorapp/Anchor/actions/workflows/swiftlint.yml">
    <img src="https://github.com/dropanchorapp/Anchor/actions/workflows/swiftlint.yml/badge.svg" alt="SwiftLint">
  </a>
  <a href="https://ko-fi.com/tijsteulings">
    <img src="https://ko-fi.com/img/githubbutton_sm.svg" alt="Support on Ko-fi">
  </a>
</p>

<p align="center">
  Drop anchor at your favorite places with structured data storage on your home PDS and optional social sharing via Bluesky.
</p>

## Features

- **Native iOS App** - Full-featured mobile experience with native location services
- **StrongRef Architecture** - Store address records and check-ins with content integrity on your home PDS
- **Optional Social Sharing** - Choose to share check-ins as posts on Bluesky to notify your followers
- **Global Feed** - Discover check-ins from around the world via the Anchor AppView feed
- **Place Discovery** - Find nearby climbing gyms, cafes, and points of interest via OpenStreetMap
- **Privacy-First** - All data stored on your own PDS, no tracking or analytics
- **AT Protocol Native** - Uses community lexicon standards for structured location data

## Screenshots

<p align="center">
  <img src="Static/anchor-feed-screen.jpeg" alt="Anchor Global Feed" width="240"/>
  <img src="Static/anchor-checkin-screen.jpeg" alt="Anchor Check-in Screen" width="240"/>
  <img src="Static/anchor-nearby-locations-screen.jpeg" alt="Anchor Nearby Places" width="240"/>
  <img src="Static/anchor-checkin-message-screen.jpeg" alt="Anchor Check-in Message" width="240"/>
</p>

<p align="center">
  <em>Global feed, check-in interface, nearby places discovery, and message composition</em>
</p>

## Quick Start

### Requirements

- iOS 18.6 or later
- Location Services enabled

### Installation

**App Store**: Coming soon

**Build from Source**:

```bash
git clone https://github.com/dropanchorapp/Anchor.git
cd Anchor

# Open in Xcode
open Anchor.xcodeproj

# Or build from command line
make build
```

### First Launch

1. Browse the global feed (no sign-in required)
2. Sign in to Bluesky via Settings to create check-ins
3. Enable location services when prompted
4. Tap "Check In" to discover nearby places and drop anchor

## How It Works

Anchor stores check-ins on your Personal Data Server (PDS) using a StrongRef architecture:

1. **Address Record** (`community.lexicon.location.address`) - Reusable venue data
2. **Check-in Record** (`app.dropanchor.checkin`) - References address via StrongRef (URI + CID)

This approach provides content integrity verification, data efficiency through reusable addresses, and full ownership of your data on your PDS.

<details>
<summary>Example Records</summary>

**Address Record:**
```json
{
  "$type": "community.lexicon.location.address",
  "name": "Klimmuur Centraal",
  "street": "Stationsplein 45",
  "locality": "Utrecht",
  "country": "NL"
}
```

**Check-in Record:**
```json
{
  "$type": "app.dropanchor.checkin",
  "text": "Great session!",
  "createdAt": "2025-01-30T14:30:00Z",
  "addressRef": {
    "uri": "at://did:plc:user123/community.lexicon.location.address/abc123",
    "cid": "bafyreigh2akiscaildc..."
  },
  "coordinates": {
    "$type": "community.lexicon.location.geo",
    "latitude": "52.0705",
    "longitude": "4.3007"
  }
}
```
</details>

## Architecture

```
Anchor/
├── ATProtoFoundation/   # Generic AT Protocol & OAuth library
├── AnchorKit/           # App-specific business logic
└── AnchorMobile/        # iOS app (SwiftUI)
```

- **Swift 6** with strict concurrency
- **SwiftUI** with NavigationStack and TabView
- **AT Protocol** with community lexicon standards
- **CoreLocation** for native location services

The global feed is provided by [Anchor AppView](https://dropanchor.app), a separate backend project.

## Development

```bash
# Build and test
make build           # Build iOS app
make test            # Run all package tests
make lint-fix        # Fix SwiftLint issues

# Or directly
cd AnchorKit && swift test
cd ATProtoFoundation && swift test
```

See [CLAUDE.md](CLAUDE.md) for detailed development instructions.

## Privacy

- All check-in data stored on your home PDS
- No tracking or analytics
- Location access only when needed
- Open source for full transparency

## Contributing

Contributions welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## AI Disclosure

Developed with assistance from [Claude Code](https://claude.ai/code) under human oversight. All design choices and quality control guided by human developers.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Links

- [Bluesky @dropanchor.app](https://bsky.app/profile/dropanchor.app)
- [AT Protocol](https://atproto.com)
- [Support on Ko-fi](https://ko-fi.com/tijsteulings)
