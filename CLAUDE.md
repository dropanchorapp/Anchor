# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

### Building the App

```bash
# Build the iOS app
xcodebuild -project Anchor.xcodeproj -scheme AnchorMobile build -destination 'platform=iOS Simulator,name=iPhone 16'

# Or using Xcode Build MCP tools
# Use scheme "AnchorMobile" and project path "Anchor.xcodeproj"
```

### Running Tests

```bash
# Run iOS app tests
xcodebuild -project Anchor.xcodeproj -scheme AnchorMobile test -destination 'platform=iOS Simulator,name=iPhone 16'

# Run AnchorKit unit tests
cd AnchorKit && swift test
```

### Building the AnchorKit Package

```bash
# From the AnchorKit directory
cd AnchorKit
swift build
swift test
```

### Code Quality & Linting

#### SwiftLint Setup

The project includes SwiftLint for code quality enforcement:

```bash
# Run SwiftLint manually
swiftlint

# Run with strict mode (warnings treated as errors)
swiftlint --strict

# Auto-fix violations where possible
swiftlint --fix
```

**Configuration:**

- `.swiftlint.yml` - Project-specific rules and configuration
- Custom rules for AT Protocol and Bluesky naming conventions
- Integrated as Xcode build phase for automatic checking
- CI/CD integration with `--strict` mode for pull request validation

**Key Rules:**

- Force unwrapping and force try violations are treated as errors
- Custom naming conventions for AT Protocol (`ATProto`) and Bluesky
- Disabled `trailing_whitespace` (auto-fixed by Xcode)
- Optimized for SwiftUI development patterns

## Project Architecture

### High-Level Structure

Anchor is an iOS app for location-based check-ins to Bluesky using the AT Protocol. The project uses a modular architecture with two main components:

- **AnchorMobile (Main App)**: SwiftUI-based iOS application with TabView navigation
- **AnchorKit**: Reusable business logic package for potential macOS/watchOS expansion

### Key Architectural Patterns

1. **Shared Business Logic**: AnchorKit contains all models, services, and utilities that could be reused across platforms
2. **TabView Navigation**: Uses SwiftUI's TabView for native iOS navigation patterns
3. **Observable Pattern**: LocationService uses @Observable for reactive UI updates
4. **Async/Await**: Modern Swift concurrency throughout location and networking code
5. **Protocol-First Architecture**: Services accept protocol types for maximum testability without SwiftData dependencies
6. **Dependency Injection**: Protocol-based storage and service abstractions enable comprehensive testing

### Core Models

#### Location & Places
- **Place**: Represents OpenStreetMap POIs with element type/ID, coordinates, and tags
- **GeoCoordinates**: Geographic coordinates using community lexicon format (`community.lexicon.location.geo`)

#### StrongRef Records
- **StrongRef**: AT Protocol reference with URI + CID for content integrity verification
- **CommunityAddressRecord**: Structured address data following community lexicon (`community.lexicon.location.address`)
- **CheckinRecord**: Modern checkin format with strongref to address (`app.dropanchor.checkin`)
- **ResolvedCheckin**: Complete checkin with verified address data and integrity status

#### Authentication & Settings
- **AuthCredentials**: SwiftData model for authentication data with automatic storage and validation
- **AuthCredentialsProtocol**: Protocol abstraction enabling testing without SwiftData ModelContainer dependencies
- **AnchorSettings**: User preferences stored in UserDefaults with immutable update methods

#### AT Protocol Models
- **ATProtoCreateRecordResponse**: Standard AT Protocol record creation response with URI and CID
- **ATProtoGetRecordResponse**: Record retrieval response with content integrity data

### Services Architecture

- **LocationService**: CoreLocation wrapper with proper permission handling for iOS apps
- **AnchorService**: Backend-powered POI discovery via Anchor API
- **CheckInStore**: StrongRef-based check-in creation with atomic address + checkin record operations
- **FeedStore**: Feed management using new Anchor AppView backend (no authentication required)
- **AnchorAppViewService**: Client for the Anchor AppView API at `https://dropanchor.app`
- **ATProtoClient**: Full AT Protocol client with StrongRef support, CID verification, and atomic record creation
- **ATProtoAuthService**: Authentication service using `AuthCredentialsProtocol` for testability
- **BlueskyPostService**: Enhanced social posting for Bluesky with rich text formatting
- **CredentialsStorage**: Multiple storage implementations (Keychain, SwiftData, InMemory) with unified protocol interface

### Location Permission Strategy

The iOS app architecture provides proper location permission handling through native iOS permission flows. The LocationService is designed specifically for iOS apps where location permission dialogs work seamlessly with the app lifecycle.

### Protocol-First Architecture Implementation

The codebase implements a comprehensive protocol-first architecture that solves key SwiftData testing challenges:

#### Challenge Solved

- **Problem**: SwiftData `@Model` classes require ModelContainer setup, making unit tests complex and fragile
- **Solution**: Services accept `AuthCredentialsProtocol` instead of concrete `AuthCredentials` SwiftData models

#### Key Benefits

1. **Testing Independence**: Tests run without SwiftData ModelContainer dependencies
2. **Mock-Friendly**: `TestAuthCredentials` and `MockCredentialsStorage` enable comprehensive testing
3. **Production Flexibility**: Multiple storage implementations (Keychain, SwiftData, InMemory) with unified interface
4. **Clean Separation**: SwiftData models remain in storage layer, services use protocol abstractions

#### Implementation Details

- All services (`CheckInStore`, `ATProtoAuthService`, `ATProtoClient`) accept `AuthCredentialsProtocol`
- Storage implementations handle protocol→concrete conversion internally
- Tests use `TestAuthCredentials` struct that implements the protocol without SwiftData dependencies
- Production code continues using `AuthCredentials` SwiftData models for persistence

### StrongRef Architecture Implementation

The codebase implements a **StrongRef-based record architecture** following AT Protocol standards for content integrity and data normalization:

#### Core Concept

When creating a check-in, the system creates **two separate records** on the user's PDS:

1. **Address Record** (`community.lexicon.location.address`): Reusable venue information
   - Contains structured address data following community lexicon standards
   - Can be referenced by multiple check-ins at the same location
   - Enables proper venue normalization and deduplication

2. **Check-in Record** (`app.dropanchor.checkin`): User message with StrongRef to address
   - References the address record via StrongRef (URI + CID)
   - Contains user's message, coordinates, and metadata
   - Enables content integrity verification through CID matching

#### StrongRef Benefits

- **Self-contained**: All data stored on user's PDS (no external dependencies)
- **Content integrity**: CID verification prevents tampering and detects modifications
- **Reusable addresses**: Same venue can be referenced efficiently by multiple check-ins
- **Standards compliant**: Uses community lexicon properly for interoperability
- **Future-proof**: Supports address record evolution without breaking existing check-ins

#### Technical Implementation

- **Atomic Creation**: `ATProtoClient.createCheckinWithAddress()` creates both records atomically
- **Automatic Cleanup**: Orphaned address records are deleted if checkin creation fails
- **CID Verification**: `verifyStrongRef()` validates content integrity via CID comparison
- **Record Resolution**: `resolveCheckin()` fetches and verifies complete checkin data
- **Error Handling**: Comprehensive error handling for network failures and data integrity issues

#### Key Models

- **StrongRef**: AT Protocol compliant reference with URI + CID for content integrity
- **CommunityAddressRecord**: Structured address data following community lexicon
- **CheckinRecord**: Modern checkin format with strongref to address and coordinates
- **ResolvedCheckin**: Complete checkin with verified address data and integrity status

## Development Notes

### Platform Requirements

- iOS 18.6+ (declared in project settings)
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
- **UI tests**: iOS app functionality testing in AnchorUITests
- **Protocol-based testing**: Services accept `AuthCredentialsProtocol` enabling testing without SwiftData ModelContainer
- **Dependency injection**: URLSession mocking and in-memory storage for isolated unit tests
- **Mock implementations**: `TestAuthCredentials`, `MockCredentialsStorage`, `MockURLSession`, `MockATProtoClient`, `MockBlueskyPostService` for comprehensive testing
- **StrongRef testing**: Complete testing of atomic record creation, CID verification, and error handling scenarios

#### Test Organization & Tags

Tests are organized with semantic tags for filtering and categorization:

- `.unit` - Fast unit tests for models and utilities
- `.integration` - Tests requiring network access or external services
- `.services` - Service layer testing (FeedService, AnchorService, AuthService)
- `.stores` - Store layer testing (CheckInStore)
- `.models` - Data model testing (Place, ATProtoRecord, AuthCredentials)
- `.auth` - Authentication and credential management tests
- `.feed` - Feed parsing and AT Protocol record processing
- `.network` - Network-dependent tests (can be filtered out for offline development)
- `.location` - Location-based functionality tests
- `.markdown` - Markdown formatting and rich text processing
- `.facets` - AT Protocol facet and rich text feature tests

#### Test Execution

```bash
# Run all tests (46+ tests total)
swift test

# Run specific test categories
swift test --filter .unit          # Fast unit tests only
swift test --filter .integration   # Integration tests only
swift test --filter .services      # Service layer tests
swift test --filter .network       # Network-dependent tests

# Run from Xcode project (includes UI tests)
xcodebuild -project Anchor.xcodeproj -scheme AnchorMobile test -destination 'platform=iOS Simulator,name=iPhone 16'
```

#### Test Coverage

- **ATProtoRecord**: Markdown formatting, facet processing, timeline data conversion
- **FeedService**: Feed fetching, filtering, error handling with URLSession mocking
- **CheckInStore**: StrongRef-based checkin creation, atomic address + checkin operations, error handling
- **ATProtoClient**: StrongRef creation, CID verification, record resolution, cleanup on failure
- **StrongRef Models**: Record integrity, content verification, resolution workflows
- **AnchorService**: POI discovery, backend API integration
- **Core Models**: Place creation, ID parsing, settings management, credential validation

#### Testing Best Practices

- **Parameterized testing**: Using Swift Testing's arguments for comprehensive edge case coverage
- **Async/await support**: Proper handling of async service methods with MainActor isolation
- **Protocol-first mocking**: `AuthCredentialsProtocol` and storage protocols enable testing without production dependencies
- **Error handling**: Comprehensive error scenario testing for network failures and invalid data
- **Unicode support**: Proper UTF-8 byte counting for AT Protocol facet range calculations
- **Isolation**: Tests run independently without requiring external services or SwiftData containers

### iOS App Specifics

- Uses `TabView` for native iOS navigation patterns
- Supports standard iOS navigation with NavigationStack
- Native iOS UI patterns with proper safe area handling
- Location permissions handled through standard iOS permission flows

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

- Since this is an iOS app, all iOS simulator build MCP tools can be used
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

- **Native iOS app** with TabView navigation between Feed, Check In, and Settings
- **Quick check-in** interface for immediate check-ins at nearby places
- **Location permissions** handled through standard iOS permission flows
- **Native iOS integration** with proper system dialogs and navigation patterns
- **Standard iOS app lifecycle** with background/foreground state handling

### Main Views

#### FeedView (Feed Tab)

- Global check-in feed from Anchor AppView backend
- Individual check-in posts with rich text formatting
- Pull-to-refresh functionality
- Empty states with anchor-no-locations illustration

#### CheckInView (Check In Tab)

- Current location status with enable button
- "Check In" button to discover nearby places
- Location permission prompts and status

#### NearbyPlacesView (Place Discovery)

- List of nearby POIs from Overpass API (400m radius)
- Category filters (All, 🧗‍♂️, 🍽️, 🏪)
- Distance-based sorting (closest first)
- Empty state with anchor-no-locations illustration and subtle borders

#### CheckInComposeView (Check-in Interface)

- Selected place display with category icon
- Message input field for custom text
- Authentication status and Bluesky toggle
- Drop anchor button to create check-in

#### SettingsView (Settings Tab)

- Bluesky authentication status and sign-in
- Account information display
- Future: Default message preferences, app preferences

### Bluesky Integration & Anchor AppView

#### StrongRef-Based Record Storage

- **Address Records**: Structured venue data stored as `community.lexicon.location.address` records on user's PDS
- **Check-in Records**: User messages with StrongRef to address stored as `app.dropanchor.checkin` records on user's PDS
- **Content Integrity**: CID verification ensures address records haven't been tampered with since checkin creation
- **Atomic Creation**: Both address and checkin records created atomically with automatic cleanup on failure

#### Dual Posting Architecture

- **PDS Storage**: Clean, structured check-in data with StrongRef address references
- **Social Posting**: Enhanced marketing-friendly posts on Bluesky with rich text formatting
- **Feed Reading**: Uses new Anchor AppView backend at `https://dropanchor.app`
- **API Endpoints**: Global, nearby, user-specific, and following feeds via REST API

#### Technical Details

- Message format: `Dropped anchor at [Place Name] 🧭 "[Custom Message]" [Category Emoji]`
- Automatic token refresh and session management
- **Secure credential storage**: Multiple options (Keychain recommended, SwiftData legacy, InMemory for testing)
- **No authentication required** for feed reading - public API
- **Standards Compliance**: Uses community lexicon for location data interoperability

### Future Expansion

- **macOS companion app** using same AnchorKit business logic
- **Apple Watch complications** for ultra-quick drops
- **Shortcuts integration** for automation
- **Recent places** for quick repeat check-ins
- **Background location** for automatic check-ins
- **Widget support** for iOS home screen

## OAuth Authentication Flow

### Backend Integration

- **OAuth backend**: Uses `/Users/tijs/projects/atproto/anchor-appview` for web-based OAuth
- **Mobile flow**: iOS app loads `https://dropanchor.app/mobile-auth` in WebView
- **Callback handling**: Custom URL scheme `anchor-app://auth-callback` with auth parameters
- **PDS URL resolution**: Backend resolves user's actual PDS URL from DID document and includes it in mobile callback

### Key OAuth Implementation Details

- **Personal PDS support**: OAuth flow correctly resolves and stores PDS URLs for users with personal PDS servers (not just bsky.social)
- **User registration**: Mobile OAuth flow automatically registers users in backend database for PDS crawling
- **Flexible date parsing**: `ISO8601DateFormatter.flexibleDate()` utility handles both fractional seconds (`2025-08-11T18:34:55.966Z`) and basic formats (`2025-08-11T18:34:55Z`) from API responses

## Feed Display Architecture

### Date Parsing & Display

- **API timestamps**: Global feed provides ISO8601 timestamps with varying precision
- **Parsing strategy**: Two-tier parsing (fractional seconds first, basic format fallback)
- **Display format**: Time-only display (`6:34 PM`) since posts are grouped by date in sections
- **Grouping logic**: `Array<FeedPost>.groupedByDate()` creates date-based sections with newest-first sorting within each day

### Troubleshooting Feed Issues

- If posts show same timestamp: Check ISO8601 parsing - likely fallback to `Date()` due to parse failure
- If date grouping fails: Verify timezone handling in `Calendar.current.startOfDay(for:)`
- For debug logging: Temporarily add debug prints to `FeedModels.swift` date parsing

## Additional Development Notes

### Backend Management

- **Deploy backend changes**: `cd /Users/tijs/projects/atproto/anchor-appview && deno task deploy`
- **Backend URL**: All API endpoints at `https://dropanchor.app`
- **AT Protocol browser**: View records at `https://atproto-browser.vercel.app/at/{did}/{collection}/{rkey}`

### Known Dependencies Between Projects

- iOS app depends on anchor-appview for OAuth and feed APIs
- OAuth session management happens in backend, credentials stored in iOS app
- Feed timestamps require consistent ISO8601 parsing between backend API and iOS client
- the current year is 2025