# ``ATProtoFoundation``

A Swift package providing foundational types and utilities for building AT Protocol (atproto) iOS applications.

## Overview

ATProtoFoundation provides the building blocks for iOS apps that interact with the AT Protocol network (including Bluesky). It includes:

- Rich text record types with facet support (links, mentions, hashtags)
- BFF (Backend-For-Frontend) OAuth authentication pattern
- Secure credential storage options
- Timeline API response parsing
- Date parsing utilities

## Topics

### Essentials

- <doc:GettingStarted>

### Records and Rich Text

- ``BlueskyPostRecord``
- ``ATProtoFacet``
- ``ATProtoFeature``

### Timeline Models

- ``TimelineRecord``
- ``TimelineFacet``
- ``FacetIndex``
- ``FacetFeature``

### Authentication

- ``MobileOAuthCoordinator``
- ``OAuthConfiguration``
- ``AuthCredentials``
- ``AuthCredentialsProtocol``
- ``AuthenticationState``

### Credentials Storage

- ``CredentialsStorageProtocol``
- ``KeychainCredentialsStorage``
- ``InMemoryCredentialsStorage``

### Networking

- ``BFFAPIClient``
- ``URLSessionProtocol``

### Utilities

- ``ISO8601DateFormatter``
- ``RichTextProcessor``
- ``Logger``

### Lexicon Constants

- ``BlueskyLexicon``
- ``CommunityLexicon``
