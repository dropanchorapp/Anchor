# 🧭 Anchor CLI

A minimal command-line check-in app that lets you "drop anchor" at your favorite places and share them on Bluesky.

Built with Swift 6 for macOS, Anchor uses the AT Protocol to post location-based check-ins to your Bluesky feed, with rich location data powered by OpenStreetMap.

## ✨ Features

- **🔐 Bluesky Authentication** - Secure login using the AT Protocol
- **📍 Location Detection** - Automatic geolocation using CoreLocation
- **🗺️ Place Discovery** - Find nearby points of interest (climbing gyms, cafes, etc.)
- **💬 Custom Messages** - Add personal notes to your check-ins
- **⚙️ Configurable** - Set default messages and preferences
- **🎯 CLI-First** - Fast, keyboard-driven workflow

## 🚀 Quick Start

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/Anchor.git
cd Anchor

# Build the CLI tool
swift build -c release

# Add to your PATH (optional)
cp .build/release/anchor /usr/local/bin/
```

### First Time Setup

1. **Authenticate with Bluesky:**

   ```bash
   anchor login
   ```

2. **Configure your preferences:**

   ```bash
   anchor settings
   ```

3. **Drop your first anchor:**

   ```bash
   anchor drop
   ```

## 📖 Usage

### Commands

#### `anchor login`

Authenticate with your Bluesky account using the AT Protocol.

```bash
anchor login
# Follow the prompts to enter your Bluesky handle and password
```

#### `anchor settings`

Configure your default check-in message and other preferences.

```bash
anchor settings
# Set your default message for check-ins
```

#### `anchor drop`

Create a location-based check-in post.

**Interactive mode** (recommended):

```bash
anchor drop
# 1. Detects your current location
# 2. Shows nearby places to choose from
# 3. Prompts for an optional message
# 4. Posts to your Bluesky feed
```

**Quick mode** with parameters:

```bash
# Check in at a specific place
anchor drop --place "way:123456" --message "Great climbing session!"

# Use default message
anchor drop --place "node:789012"
```

#### `anchor nearby`

Discover nearby points of interest without checking in.

```bash
# Show all nearby places
anchor nearby

# Filter by type (e.g., climbing gyms)
anchor nearby --filter climbing
```

### Example Check-in Post

When you drop anchor, Anchor posts to Bluesky in this format:

```
Dropped anchor at Klimmuur Centraal 🧗‍♂️
"Lunch session with Marieke"
```

## 🏗️ Architecture

Anchor is built with a modular architecture:

- **AnchorKit** - Core business logic (reusable for future iOS app)
- **AnchorCLI** - Command-line interface and user interaction
- **Swift 6** - Modern async/await concurrency
- **AT Protocol** - Direct Bluesky integration
- **CoreLocation** - Native macOS location services
- **Overpass API** - Rich OpenStreetMap place data

## 🔧 Development

### Requirements

- macOS 14.0+
- Swift 6.0+
- Xcode 15.0+ (for development)

### Building from Source

```bash
# Debug build
swift build

# Release build
swift build -c release

# Run tests
swift test
```

### Project Structure

```
Anchor/
├── Package.swift              # Main package definition
├── AnchorKit/                 # Core business logic
│   ├── Sources/AnchorKit/
│   │   ├── Models/           # Data models
│   │   ├── Services/         # API services
│   │   └── Utils/            # Utilities
│   └── Tests/                # Unit tests
└── AnchorCLI/                # CLI interface
    └── Sources/AnchorCLI/
        ├── main.swift        # Entry point
        └── CLICommands.swift # Command definitions
```

## 🔒 Privacy & Security

- **Local Storage** - Credentials stored securely in macOS UserDefaults
- **Location Data** - Used only for place discovery, not stored or transmitted
- **Minimal Permissions** - Requests only necessary location and network access
- **No Tracking** - No analytics or user behavior tracking

## 🛣️ Roadmap

- [ ] **v1.0** - MVP with core check-in functionality
- [ ] **v1.1** - Custom `app.anchor.drop` record type for structured data
- [ ] **v1.2** - Check-in history and timeline viewing
- [ ] **v2.0** - iOS companion app using shared AnchorKit
- [ ] **v2.1** - Offline check-in queuing
- [ ] **v2.2** - Social features (following friends' check-ins)

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests for any improvements.

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

## 🔗 Links

- [Bluesky](https://bsky.app) - Decentralized social network
- [AT Protocol](https://atproto.com) - Authenticated Transfer Protocol
- [OpenStreetMap](https://openstreetmap.org) - Collaborative mapping project

---

**Made with ❤️ for the climbing and outdoor community**
