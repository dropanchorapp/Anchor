# 🧭 Anchor

<p align="center">
  <img src="Static/AnchorAppIcon-transparent.png" alt="Anchor App Icon" width="200"/>
</p>

<p align="center">
  <strong>A native macOS menubar app for location-based check-ins using the AT Protocol</strong>
</p>

<p align="center">
  <a href="https://github.com/dropanchorapp/Anchor/actions/workflows/tests.yml">
    <img src="https://github.com/dropanchorapp/Anchor/actions/workflows/tests.yml/badge.svg" alt="Tests">
  </a>
  <a href="https://github.com/dropanchorapp/Anchor/actions/workflows/swiftlint.yml">
    <img src="https://github.com/dropanchorapp/Anchor/actions/workflows/swiftlint.yml/badge.svg" alt="SwiftLint">
  </a>
</p>

<p align="center">
  Drop anchor at your favorite places with structured data storage on AnchorPDS and optional social sharing via Bluesky.
</p>

## ✨ Features

- **🖥️ Native macOS Menubar App** - Always accessible from your menubar with a single click
- **🔐 Dual PDS Architecture** - Store check-ins on AnchorPDS with optional Bluesky posting
- **📍 Automatic Location** - CoreLocation integration with proper macOS permissions
- **🗺️ Place Discovery** - Find nearby climbing gyms, cafes, and points of interest via OpenStreetMap
- **💬 Custom Messages** - Add personal notes to your check-ins
- **🏗️ Modular Architecture** - Shared AnchorKit framework ready for iOS and watchOS expansion
- **🎯 Privacy-First** - Local storage only, no tracking or analytics
- **🌐 AT Protocol Native** - Uses community lexicon standards for structured location data

## 📱 Screenshots

<p align="center">
  <img src="Static/checkin-screen.png" alt="Anchor Check-in Screen" width="400"/>
  <img src="Static/settings-screen.png" alt="Anchor Settings Screen" width="400"/>
</p>

<p align="center">
  <em>Check-in interface and settings panel</em>
</p>

## 🚀 Quick Start

### System Requirements

- macOS 14.0 or later
- Location Services enabled

### Installation

1. **Download from Releases** (Coming Soon)

   Download the latest `.dmg` from our [Releases page](https://github.com/tijs/Anchor/releases)

2. **Build from Source**

   ```bash
   # Clone the repository
   git clone https://github.com/tijs/Anchor.git
   cd Anchor
   
   # Open in Xcode and build
   open Anchor/Anchor.xcodeproj
   
   # Or build from command line
   xcodebuild -project Anchor/Anchor.xcodeproj -scheme Anchor build
   ```

### First Launch

1. **Launch Anchor** - Look for the anchor (⚓) icon in your menubar
2. **Enable Location Services** - Click "Enable Location" when prompted
3. **Sign in to Bluesky** - Click "Sign In" and enter your Bluesky credentials
4. **Drop Your First Anchor** - Click "Nearby" to check in at your current location

## 🎯 How to Use

### Quick Check-in

The fastest way to check in:

1. Click the anchor icon in your menubar
2. Navigate to "Nearby" tab
3. Select a place and drop anchor
4. **Optional**: Toggle "Also post to Bluesky" to control social sharing

**Note**: All check-ins are stored on AnchorPDS regardless of your Bluesky posting preference.

### How Anchor Works: Dual PDS Architecture

Anchor uses a **dual Personal Data Server (PDS) architecture** that stores your check-ins on AnchorPDS while optionally posting to Bluesky:

#### 1. **AnchorPDS** - Your Check-in Data Store

All check-ins are stored on **AnchorPDS** (our dedicated Personal Data Server) using the official AT Protocol lexicon:

```json
{
  "$type": "app.dropanchor.checkin",
  "text": "Klimmuur Centraal (climbing)",
  "createdAt": "2024-12-29T14:30:00Z",
  "locations": [
    {
      "$type": "community.lexicon.location.geo",
      "latitude": "52.0705",
      "longitude": "4.3007"
    },
    {
      "$type": "community.lexicon.location.address",
      "name": "Klimmuur Centraal",
      "street": "Stationsplein 45",
      "locality": "Utrecht",
      "region": "UT",
      "country": "NL",
      "postalCode": "3511ED"
    }
  ]
}
```

#### 2. **Optional Bluesky Posts** - Share with Your Network

When you enable "Also post to Bluesky" (enabled by default), Anchor creates rich posts on your Bluesky feed:

**What you see on Bluesky:**

```
Dropped anchor at Klimmuur Centraal 🧭
"Great lunch session with the team!" 🧗‍♂️
```

**Under the hood (`app.bsky.feed.post`):**

```json
{
  "$type": "app.bsky.feed.post",
  "text": "Dropped anchor at Klimmuur Centraal 🧭\n\"Great lunch session with the team!\" 🧗‍♂️",
  "createdAt": "2024-12-29T14:30:00Z",
  "facets": [
    {
      "index": { "byteStart": 17, "byteEnd": 35 },
      "features": [{ 
        "$type": "app.bsky.richtext.facet#link", 
        "uri": "https://www.openstreetmap.org/way/123456" 
      }]
    }
  ]
}
```

#### Why This Architecture?

This dual-PDS approach provides the best of both worlds:

- **🏠 Dedicated Storage** - Your check-ins live on AnchorPDS with rich location data
- **🌐 Social Sharing** - Optional Bluesky posts for your social network
- **📊 Future Features** - Rich querying and analytics from structured AnchorPDS data
- **🔐 Privacy Control** - Choose what to share publicly vs. keep private
- **🌍 AT Protocol Native** - Uses community lexicon standards for interoperability

## 🏗️ Architecture

Anchor is built with a modular architecture designed for cross-platform expansion:

### Core Components

- **Anchor (macOS App)** - Native SwiftUI menubar application
- **AnchorKit** - Shared business logic framework for future iOS/watchOS apps
- **AnchorPDS** - Dedicated Personal Data Server for structured check-in storage

### Technology Stack

- **Swift 6** - Modern async/await concurrency with strict concurrency checking
- **SwiftUI** - Native macOS user interface with MenuBarExtra
- **AT Protocol** - Dual PDS integration (AnchorPDS + optional Bluesky)
- **Community Lexicon** - Uses `community.lexicon.location.*` standards
- **CoreLocation** - Native location services with proper permission handling
- **Overpass API** - Rich OpenStreetMap place data via `overpass.private.coffee`

### Project Structure

```
Anchor/
├── Anchor/                    # macOS MenuBar App
│   ├── Anchor.xcodeproj      # Xcode project
│   ├── Assets.xcassets/      # App icons and assets
│   └── Features/             # SwiftUI views organized by feature
│       ├── CheckIn/Views/    # Drop anchor interface
│       ├── Core/Views/       # Main content view
│       ├── Feed/Views/       # Future: check-in history
│       ├── Nearby/Views/     # Place discovery
│       └── Settings/Views/   # App configuration
├── AnchorKit/                # Shared Business Logic
│   ├── Sources/AnchorKit/
│   │   ├── Models/          # Place, AuthCredentials, Settings
│   │   ├── Services/        # AnchorPDS, Bluesky, Overpass, Location
│   │   ├── ATProtocol/      # AT Protocol client implementations
│   │   └── Utils/           # Shared utilities
│   └── Tests/               # Unit tests (55 tests)
└── Static/                  # Assets and documentation
```

**Note**: AnchorPDS backend is a separate project available at <https://www.val.town/x/tijs/anchorPDS>

## 🔧 Development

### Building AnchorKit

The shared framework can be built and tested independently:

```bash
cd AnchorKit
swift build
swift test  # Runs 55 tests including AnchorPDS integration
```

### Building the macOS App

```bash
# Using Xcode (recommended)
open Anchor/Anchor.xcodeproj

# Using xcodebuild
xcodebuild -project Anchor/Anchor.xcodeproj -scheme Anchor build
```

### Running Tests

```bash
# Test AnchorKit (includes AnchorPDS client tests)
cd AnchorKit && swift test

# Test the full app
xcodebuild -project Anchor/Anchor.xcodeproj -scheme Anchor test
```

### AnchorPDS

AnchorPDS is a separate project hosted on Val Town. You can experiment with it at: <https://www.val.town/x/tijs/anchorPDS>

## 🔒 Privacy & Security

- **Local Storage Only** - All data stored locally in macOS UserDefaults
- **No Analytics** - Zero tracking, telemetry, or user behavior monitoring  
- **Minimal Permissions** - Only requests location access when needed
- **Secure Authentication** - Bluesky credentials handled via AT Protocol best practices
- **Open Source** - Complete transparency with public source code

## 🛣️ Roadmap

### ✅ Completed (v1.0)

- [x] Native macOS menubar app
- [x] **Dual PDS Architecture** - AnchorPDS + optional Bluesky posting
- [x] **Community Lexicon Integration** - Uses AT Protocol standards
- [x] Location services integration
- [x] Nearby place discovery
- [x] Modular AnchorKit architecture

### 🔄 In Progress (v1.1)

- [ ] App Store distribution
- [ ] Check-in history view (from AnchorPDS)
- [ ] Default message preferences
- [ ] Launch at login option
- [ ] Global feed discovery

### 🚀 Future (v2.0+)

- [ ] **iOS Companion App** - Full iOS app using shared AnchorKit
- [ ] **Apple Watch App** - Quick drops from your wrist
- [ ] **Rich Analytics** - Personal insights from AnchorPDS data
- [ ] **Shortcuts Integration** - Automate check-ins
- [ ] **Federation** - Connect with other Anchor instances
- [ ] **Social Features** - Follow friends' check-ins across the AT Protocol network

## 🤝 Contributing

We welcome contributions! The modular architecture makes it easy to contribute to specific areas:

- **AnchorKit** - Business logic, models, and services
- **macOS App** - SwiftUI interface and platform-specific features
- **Documentation** - Help improve guides and API docs

Please check our [Contributing Guidelines](CONTRIBUTING.md) before submitting pull requests.

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

## 🔗 Connect

- **Bluesky**: [@anchor.app](https://bsky.app/profile/anchor.app) - Follow us for updates
- **AT Protocol**: [atproto.com](https://atproto.com) - Learn about the decentralized web
- **OpenStreetMap**: [openstreetmap.org](https://openstreetmap.org) - The collaborative mapping project powering our place data

---

**Made with ❤️ for the climbing and outdoor community**

*Join the decentralized social web and start dropping anchors at your favorite places today.*
