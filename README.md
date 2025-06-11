# 🧭 Anchor

<p align="center">
  <img src="Static/AnchorAppIcon-transparent.png" alt="Anchor App Icon" width="200"/>
</p>

<p align="center">
  <strong>A native macOS menubar app for location-based check-ins to Bluesky</strong>
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
  Drop anchor at your favorite places and share them on the decentralized social web using the AT Protocol.
</p>

## ✨ Features

- **🖥️ Native macOS Menubar App** - Always accessible from your menubar with a single click
- **🔐 Bluesky Integration** - Secure authentication and posting via AT Protocol
- **📍 Automatic Location** - CoreLocation integration with proper macOS permissions
- **🗺️ Place Discovery** - Find nearby climbing gyms, cafes, and points of interest via OpenStreetMap
- **💬 Custom Messages** - Add personal notes to your check-ins
- **🏗️ Modular Architecture** - Shared AnchorKit framework ready for iOS and watchOS expansion
- **🎯 Privacy-First** - Local storage only, no tracking or analytics

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

### Your Check-ins on Bluesky

When you drop anchor, Anchor creates rich posts on your Bluesky feed with embedded location data:

**What you see on Bluesky:**

```
Dropped anchor at Klimmuur Centraal 🧭
"Great lunch session with the team!" 🧗‍♂️
```

**Under the hood - structured data:**

**1. Standard Bluesky Post (`app.bsky.feed.post`)**

```json
{
  "$type": "app.bsky.feed.post",
  "text": "Dropped anchor at Klimmuur Centraal 🧭\n\"Great lunch session with the team!\" 🧗‍♂️",
  "createdAt": "2024-12-29T14:30:00Z",
  "embed": {
    "$type": "app.bsky.embed.record",
    "record": {
      "uri": "at://did:plc:abc123.../app.dropanchor.checkin/xyz789",
      "cid": "bafyreighakis..."
    }
  },
  "facets": [
    {
      "index": { "byteStart": 17, "byteEnd": 35 },
      "features": [{ "$type": "app.bsky.richtext.facet#link", "uri": "https://www.openstreetmap.org/way/123456" }]
    }
  ]
}
```

**2. Embedded Check-in Record (`app.dropanchor.checkin`)**

```json
{
  "$type": "app.dropanchor.checkin",
  "text": "Klimmuur Centraal (climbing)",
  "createdAt": "2024-12-29T14:30:00Z",
  "location": {
    "$type": "app.dropanchor.place",
    "name": "Klimmuur Centraal", 
    "geo": {
      "$type": "app.dropanchor.geo",
      "lat": 52.0705,
      "lng": 4.3007
    },
    "address": {
      "streetAddress": "Stationsplein 45",
      "locality": "Utrecht",
      "region": "UT", 
      "country": "NL",
      "postalCode": "3511ED"
    },
    "uri": "https://www.openstreetmap.org/way/123456"
  }
}
```

This dual-layer approach ensures your check-ins:

- **Display beautifully** in all Bluesky clients with rich text formatting
- **Remain fully compatible** with likes, replies, and reposts
- **Include structured location data** for future mapping and discovery features
- **Link to OpenStreetMap** for accurate place information

## 🏗️ Architecture

Anchor is built with a modular architecture designed for cross-platform expansion:

### Core Components

- **Anchor (macOS App)** - Native SwiftUI menubar application
- **AnchorKit** - Shared business logic framework for future iOS/watchOS apps

### Technology Stack

- **Swift 6** - Modern async/await concurrency with strict concurrency checking
- **SwiftUI** - Native macOS user interface with MenuBarExtra
- **AT Protocol** - Direct integration with Bluesky's decentralized network
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
│   │   ├── Services/        # Bluesky, Overpass, Location services
│   │   └── Utils/           # Shared utilities
│   └── Tests/               # Unit tests
└── Static/                  # Assets and documentation
```

## 🔧 Development

### Building AnchorKit

The shared framework can be built and tested independently:

```bash
cd AnchorKit
swift build
swift test
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
# Test AnchorKit
cd AnchorKit && swift test

# Test the full app
xcodebuild -project Anchor/Anchor.xcodeproj -scheme Anchor test
```

## 🔒 Privacy & Security

- **Local Storage Only** - All data stored locally in macOS UserDefaults
- **No Analytics** - Zero tracking, telemetry, or user behavior monitoring  
- **Minimal Permissions** - Only requests location access when needed
- **Secure Authentication** - Bluesky credentials handled via AT Protocol best practices
- **Open Source** - Complete transparency with public source code

## 🛣️ Roadmap

### ✅ Completed (v1.0)

- [x] Native macOS menubar app
- [x] Bluesky authentication and posting
- [x] Location services integration
- [x] Nearby place discovery
- [x] Modular AnchorKit architecture

### 🔄 In Progress (v1.1)

- [ ] App Store distribution
- [ ] Check-in history view
- [ ] Default message preferences
- [ ] Launch at login option

### 🚀 Future (v2.0+)

- [ ] **iOS Companion App** - Full iOS app using shared AnchorKit
- [ ] **Apple Watch App** - Quick drops from your wrist
- [ ] **Custom Record Type** - `app.anchor.drop` for richer structured data
- [ ] **Shortcuts Integration** - Automate check-ins
- [ ] **Social Features** - Follow friends' check-ins across the network

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
