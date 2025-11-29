# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

All xcodebuild and swift commands should be piped through `xcsift` to clean up output.

### Using Makefile (Recommended)

```bash
make help          # Show all available commands
make build         # Build AnchorMobile iOS app
make test          # Run ATProtoFoundation + AnchorKit tests
make test-ui       # Run AnchorMobile iOS tests
make lint          # Run SwiftLint
make lint-fix      # Auto-fix SwiftLint violations
make clean         # Clean all build artifacts
make info          # Show project/environment info
```

### Direct Commands

```bash
# Build iOS app
xcodebuild -project Anchor.xcodeproj -scheme AnchorMobile build -destination 'platform=iOS Simulator,name=iPhone 16' | xcsift

# Run all package tests
cd ATProtoFoundation && swift test | xcsift
cd AnchorKit && swift test | xcsift

# Run specific test by name
cd AnchorKit && swift test --filter "testMethodName" | xcsift

# Run tests by tag
cd AnchorKit && swift test --filter .unit | xcsift
cd AnchorKit && swift test --filter .integration | xcsift

# Run iOS app tests
xcodebuild -project Anchor.xcodeproj -scheme AnchorMobile test -destination 'platform=iOS Simulator,name=iPhone 16' | xcsift
```

### Code Quality

```bash
swiftlint          # Check for issues
swiftlint --fix    # Auto-fix violations
swiftlint --strict # Treat warnings as errors (used in CI)
```

Key SwiftLint rules: force_cast/force_try as errors, 120 char line length warning, 500 line file limit.

## Project Architecture

### Three-Package Structure

```
Anchor/
├── ATProtoFoundation/   # Generic AT Protocol & OAuth library (no app dependencies)
│   └── Sources/ATProtoFoundation/
│       ├── Auth/        # OAuth, credentials storage, cookie management
│       ├── Models/      # AuthCredentials, ATProtoModels, AuthenticationState
│       ├── Network/     # IronSessionAPIClient (multipart support)
│       └── Utilities/   # Logger, RichTextProcessor, URLSessionProtocol
│
├── AnchorKit/           # App-specific business logic (depends on ATProtoFoundation)
│   └── Sources/AnchorKit/
│       ├── ATProtocol/  # CheckinTextBuilder, ATProtoModels
│       ├── Models/      # Place, FeedModels, AnchorSettings, CategoryModels
│       ├── Services/    # LocationService, AnchorFeedService, AnchorPlacesService
│       ├── Stores/      # CheckInStore, FeedStore
│       └── Utils/       # FeedTextProcessor, LocationFormatter, ImageProcessor
│
└── AnchorMobile/        # iOS app (SwiftUI, depends on AnchorKit)
    ├── Features/
    │   ├── Auth/        # Sign-in UI
    │   ├── CheckIn/     # Place discovery, compose, nearby places
    │   ├── Feed/        # Feed views, post components
    │   └── Settings/    # Settings UI
    └── Stores/          # AppStateStore (app lifecycle)
```

### Key Architectural Patterns

1. **Protocol-First Testing**: Services accept `AuthCredentialsProtocol` instead of SwiftData models, enabling testing without ModelContainer
2. **Observable Pattern**: `@Observable` for reactive UI updates (LocationService, stores)
3. **Dependency Injection**: URLSession mocking, in-memory storage for isolated tests
4. **StrongRef Architecture**: Check-ins create two records atomically (address + checkin) with CID verification

### StrongRef Check-in Flow

When creating a check-in, two records are created on the user's PDS:

1. **Address Record** (`community.lexicon.location.address`): Reusable venue data
2. **Check-in Record** (`app.dropanchor.checkin`): References address via StrongRef (URI + CID)

Key methods:
- `ATProtoClient.createCheckinWithAddress()` - Atomic creation with automatic cleanup on failure
- `verifyStrongRef()` - Validates content integrity via CID comparison

## Development Notes

### Platform Requirements

- iOS 18.6+, macOS 14+
- Swift 6.0+ with strict concurrency
- No external dependencies - built-in frameworks only (SwiftUI, CoreLocation, Foundation)

### Testing

Uses Swift Testing framework with semantic tags for filtering:

| Tag | Description |
|-----|-------------|
| `.unit` | Fast unit tests (models, utilities) |
| `.integration` | Network-dependent tests |
| `.services` | Service layer tests |
| `.stores` | Store layer tests |
| `.auth` | Authentication tests |
| `.feed` | Feed parsing tests |
| `.network` | Can filter out for offline development |

Mock implementations available: `TestAuthCredentials`, `MockCredentialsStorage`, `MockURLSession`, `MockATProtoClient`, `MockBlueskyPostService`

## OAuth Authentication

- **Backend**: [anchor-appview](https://github.com/dropanchorapp/anchor-appview) handles OAuth
- **Mobile flow**: WebView loads `https://dropanchor.app/mobile-auth`
- **Callback**: Custom URL scheme `anchor-app://auth-callback`
- **PDS resolution**: Backend resolves actual PDS URL from DID document (supports personal PDS servers)
- **Cookie recreation**: On app launch, `sid` cookie is recreated from stored `sessionId` in credentials

## Backend Integration

- **Backend URL**: `https://dropanchor.app`
- **Feed API**: Public, no auth required
- **Deploy**: `deno task deploy` (from anchor-appview repo)
- **AT Protocol browser**: `https://atproto-browser.vercel.app/at/{did}/{collection}/{rkey}`

## Lexicons

- `community.lexicon.location.address` - Structured venue/address data
- `app.dropanchor.checkin` - Check-in record with StrongRef to address

## Troubleshooting

**Feed shows same timestamp for all posts**: ISO8601 parsing failing, check `FeedModels.swift`

**Date grouping incorrect**: Check timezone handling in `Calendar.current.startOfDay(for:)`

**Auth not working after restart**: Verify `sessionId` is stored and cookie recreation in `AppStateStore.initializeApp()`
