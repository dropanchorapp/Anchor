# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

### Building the App
```bash
# Build the Xcode project
xcodebuild -project Anchor/Anchor.xcodeproj -scheme Anchor build

# Or using Xcode Build MCP tools
# Use scheme "Anchor" and workspace path "Anchor/Anchor.xcodeproj"
```

### Running Tests
```bash
# Run unit tests
xcodebuild -project Anchor/Anchor.xcodeproj -scheme Anchor test

# Run specific test target
xcodebuild -project Anchor/Anchor.xcodeproj -scheme AnchorTests test
```

### Building the AnchorKit Package
```bash
# From the AnchorKit directory
cd Anchor/AnchorKit
swift build
swift test
```

## Project Architecture

### High-Level Structure

Anchor is a macOS menubar app for location-based check-ins to Bluesky using the AT Protocol. The project uses a modular architecture with two main components:

- **Anchor (Main App)**: SwiftUI-based menubar application
- **AnchorKit**: Reusable business logic package for potential iOS/watchOS expansion

### Key Architectural Patterns

1. **Shared Business Logic**: AnchorKit contains all models, services, and utilities that could be reused across platforms
2. **MenuBarExtra Pattern**: Uses SwiftUI's MenuBarExtra for native macOS menubar integration
3. **Observable Pattern**: LocationService uses @Observable for reactive UI updates
4. **Async/Await**: Modern Swift concurrency throughout location and networking code

### Core Models

- **Place**: Represents OpenStreetMap POIs with element type/ID, coordinates, and tags
- **AnchorSettings**: User preferences stored in UserDefaults with immutable update methods
- **AuthCredentials**: Bluesky authentication data with automatic storage and validation

### Services Architecture

- **LocationService**: CoreLocation wrapper with proper permission handling for menubar apps
- **OverpassService**: OpenStreetMap POI discovery via Overpass API
- **BlueskyService**: AT Protocol authentication and posting to Bluesky

### Location Permission Strategy

The menubar app architecture solves critical location permission issues that CLI apps face on macOS. The LocationService is designed specifically for MenuBarExtra apps where permission dialogs work properly.

## Development Notes

### Platform Requirements
- macOS 14.0+ (declared in project settings)
- Swift 6.0+ with strict concurrency
- Xcode 15.0+ for development

### Key Dependencies
- No external dependencies - uses built-in frameworks only
- SwiftUI for UI
- CoreLocation for geolocation
- Foundation for data models

### Testing Strategy

#### Framework & Architecture
- **Swift Testing**: Modern declarative testing framework (migrated from XCTest)
- **Unit tests**: Comprehensive business logic testing in AnchorKit package
- **Integration tests**: Network-dependent tests for external APIs (Overpass, Bluesky)
- **UI tests**: Menubar app functionality testing in AnchorUITests
- **Dependency injection**: Protocol-based testing with URLSession mocking for network services

#### Test Organization & Tags
Tests are organized with semantic tags for filtering and categorization:
- `.unit` - Fast unit tests for models and utilities
- `.integration` - Tests requiring network access or external services
- `.services` - Service layer testing (BlueskyService, FeedService, OverpassService)
- `.models` - Data model testing (Place, ATProtoRecord, AuthCredentials)
- `.auth` - Authentication and credential management tests
- `.feed` - Feed parsing and AT Protocol record processing
- `.network` - Network-dependent tests (can be filtered out for offline development)
- `.location` - Location-based functionality tests
- `.markdown` - Markdown formatting and rich text processing
- `.facets` - AT Protocol facet and rich text feature tests

#### Running Tests
```bash
# Run all tests (47 tests total)
swift test

# Run specific test categories
swift test --filter .unit          # Fast unit tests only
swift test --filter .integration   # Integration tests only
swift test --filter .services      # Service layer tests
swift test --filter .network       # Network-dependent tests

# Run from Xcode project (includes UI tests)
xcodebuild -project Anchor/Anchor.xcodeproj -scheme Anchor test
```

#### Test Coverage
- **ATProtoRecord**: Markdown formatting, facet processing, timeline data conversion
- **FeedService**: Feed fetching, filtering, error handling with URLSession mocking
- **BlueskyService**: Rich text facet generation, check-in text formatting, URL/mention/hashtag detection
- **OverpassService**: POI discovery, query building, API integration
- **Core Models**: Place creation, ID parsing, settings management, credential validation

#### Testing Best Practices
- **Parameterized testing**: Using Swift Testing's arguments for comprehensive edge case coverage
- **Async/await support**: Proper handling of async service methods with MainActor isolation
- **Mocking**: Protocol-based dependency injection for URLSession and external services
- **Error handling**: Comprehensive error scenario testing for network failures and invalid data
- **Unicode support**: Proper UTF-8 byte counting for AT Protocol facet range calculations

### Menubar App Specifics
- Uses `.menuBarExtraStyle(.window)` for proper window presentation
- Frame size: 320x400 pixels for optimal menubar experience
- Includes quit button since app doesn't appear in dock

## Available MCP Tools

### 🧠 Thinking & Sequential Reasoning

- `mcp__think__think` - Record thoughts for complex reasoning and cache memory
- `mcp__think__get_thoughts` - Retrieve all recorded thoughts from session
- `mcp__think__clear_thoughts` - Clear thought history to start fresh
- `mcp__think__get_thought_stats` - Get statistics about thinking session
- `mcp__sequential-thinking__process_thought` - Add sequential thoughts with metadata and stages
- `mcp__sequential-thinking__generate_summary` - Generate summary of thinking process
- `mcp__sequential-thinking__clear_history` - Clear sequential thought history

### 💻 IDE Integration

- `mcp__ide__getDiagnostics` - Get VS Code language diagnostics for debugging
- `mcp__ide__executeCode` - Execute Python code in Jupyter kernel for testing

### 📱 Xcode & iOS Development

- Since this is a mac os app not all xcode build mcp tools can be used
- `mcp__XcodeBuildMCP__clean_ws` - Clean workspace build products
- `mcp__XcodeBuildMCP__clean_proj` - Clean project build products
- `mcp__XcodeBuildMCP__build_ios_sim_name_ws` - Build for named simulator (workspace)
- `mcp__XcodeBuildMCP__build_ios_sim_name_proj` - Build for named simulator (project)
- `mcp__XcodeBuildMCP__build_run_ios_sim_name_ws` - Build & run on named simulator (workspace)
- `mcp__XcodeBuildMCP__build_run_ios_sim_name_proj` - Build & run on named simulator (project)
- `mcp__XcodeBuildMCP__boot_sim` - Boot iOS simulator for testing
- `mcp__XcodeBuildMCP__open_sim` - Open iOS Simulator app
- `mcp__XcodeBuildMCP__install_app_sim` - Install app in simulator
- `mcp__XcodeBuildMCP__launch_app_sim` - Launch app in simulator
- `mcp__XcodeBuildMCP__get_ios_bundle_id` - Extract bundle ID from app bundle
- `mcp__XcodeBuildMCP__start_sim_log_cap` - Start capturing simulator logs
- `mcp__XcodeBuildMCP__stop_sim_log_cap` - Stop log capture and retrieve logs

### 📚 Documentation & Context

- `mcp__context7__resolve-library-id` - Resolve library names to Context7 IDs
- `mcp__context7__get-library-docs` - Fetch up-to-date library documentation

### Common Use Cases

- **Building & Testing**: Use Xcode MCP tools for automated builds and simulator testing
- **Complex Problem Solving**: Use thinking tools for planning and reasoning through architecture decisions
- **Documentation**: Use context7 tools to get current library documentation
- **Debugging**: Use IDE diagnostics and simulator log capture for troubleshooting

## App Features & Design

### Core Functionality

- **Always accessible** via menubar icon with anchor symbol
- **Quick drop** interface for immediate check-ins at current location
- **Location permissions** work properly (critical advantage over CLI apps)
- **Native macOS integration** with proper system dialogs
- **Hide from Dock** (`LSUIElement = true`) - menubar-only app
- **Quit button** in interface (no dock to quit from)

### Main Views

#### ContentView (Main Interface)

- Current location status with enable button
- Quick drop button for current location
- Recent check-ins display (future)
- Navigation to nearby places and settings

#### DropView (Check-in Interface)

- Selected place or current location display
- Message input field for custom text
- Authentication status and sign-in prompts
- Drop button to post to Bluesky via AT Protocol

#### NearbyView (Place Discovery)

- List of nearby POIs from Overpass API
- Category filters (All, 🧗‍♂️, 🍽️, 🏪)
- Quick selection for dropping anchor
- Distance-based sorting

#### SettingsView (Configuration)

- Bluesky authentication status
- Future: Default message preferences, app preferences

### Bluesky Integration

- Posts as `app.bsky.feed.post` record type via AT Protocol
- Message format: `Dropped anchor at [Place Name] 🧭 "[Custom Message]" [Category Emoji]`
- Automatic token refresh and session management
- Secure credential storage in UserDefaults

### Future Expansion

- **iOS companion app** using same AnchorKit business logic
- **Apple Watch complications** for ultra-quick drops
- **Shortcuts integration** for automation
- **Recent places** for quick repeat check-ins
- **Launch at login** functionality