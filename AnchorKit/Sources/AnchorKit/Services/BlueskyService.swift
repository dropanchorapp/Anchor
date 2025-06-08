import Foundation
import SwiftData

/// Service for interacting with Bluesky via AT Protocol
@Observable
public final class BlueskyService: Sendable {
    
    // MARK: - Properties
    
    private let session: URLSession
    private let baseURL = "https://bsky.social"
    
    /// Current authentication credentials
    @MainActor
    public private(set) var credentials: AuthCredentials?
    
    /// Whether the user is currently authenticated
    @MainActor
    public var isAuthenticated: Bool {
        credentials?.isValid ?? false
    }
    
    // MARK: - Initialization
    
    public init(session: URLSession = .shared) {
        self.session = session
        // Note: loadStoredCredentials will be called when modelContext becomes available
    }
    
    // MARK: - Authentication
    
    /// Load stored credentials from SwiftData
    @MainActor
    public func loadStoredCredentials(from context: ModelContext) {
        credentials = AuthCredentials.current(from: context)
        print("🔑 Loading credentials: \(credentials != nil ? "Found credentials for @\(credentials!.handle)" : "No credentials found")")
    }
    
    /// Authenticate with Bluesky using handle and app password
    /// - Parameters:
    ///   - handle: Bluesky handle (e.g., "user.bsky.social")
    ///   - appPassword: App password (recommended) or account password
    ///   - context: SwiftData ModelContext for persisting credentials
    /// - Returns: Success status
    @MainActor
    public func authenticate(handle: String, appPassword: String, context: ModelContext) async throws -> Bool {
        let loginRequest = LoginRequest(identifier: handle, password: appPassword)
        let request = try buildRequest(
            endpoint: "/xrpc/com.atproto.server.createSession",
            method: "POST",
            body: loginRequest
        )
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BlueskyError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw BlueskyError.invalidCredentials
            }
            throw BlueskyError.httpError(httpResponse.statusCode)
        }
        
        let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
        
        // Create and store credentials
        let newCredentials = AuthCredentials(
            handle: handle,
            accessToken: loginResponse.accessJwt,
            refreshToken: loginResponse.refreshJwt,
            did: loginResponse.did,
            expiresAt: Date().addingTimeInterval(3600) // 1 hour from now
        )
        
        try AuthCredentials.save(newCredentials, to: context)
        self.credentials = newCredentials
        print("🔑 Saved credentials for @\(newCredentials.handle)")
        
        return true
    }
    
    /// Open Bluesky app password creation page
    /// - Returns: URL to create an app password
    @MainActor
    public func getAppPasswordURL() -> URL {
        return URL(string: "https://bsky.app/settings/app-passwords")!
    }
    
    /// Sign out and clear stored credentials
    @MainActor
    public func signOut(context: ModelContext) {
        try? AuthCredentials.clearAll(from: context)
        credentials = nil
    }
    
    /// Refresh the current session if needed
    @MainActor
    public func refreshSessionIfNeeded(context: ModelContext) async throws {
        guard let currentCredentials = credentials,
              currentCredentials.isExpired else {
            return
        }
        
        try await refreshSession(context: context)
    }
    
    // MARK: - Posting
    
    /// Post a check-in to Bluesky following the new AT Protocol strategy
    /// - Parameters:
    ///   - place: The place being checked into
    ///   - message: Optional custom message
    ///   - context: SwiftData ModelContext for session refresh
    /// - Returns: Success status
    @MainActor
    public func postCheckIn(place: Place, message: String? = nil, context: ModelContext) async throws -> Bool {
        try await refreshSessionIfNeeded(context: context)
        
        guard let credentials = credentials else {
            throw BlueskyError.notAuthenticated
        }
        
        // Step 1: Create the check-in record with structured location data
        let checkinRecord = try await createCheckinRecord(place: place, message: message, credentials: credentials)
        
        // Step 2: Create the main feed post with embed pointing to the check-in record
        let success = try await createFeedPost(place: place, message: message, embedRecord: checkinRecord, credentials: credentials)
        
        return success
    }
    
    /// Step 1: Create an app.dropanchor.checkin record with structured location data
    /// - Parameters:
    ///   - place: The place being checked into
    ///   - message: Optional custom message
    ///   - credentials: Authentication credentials
    /// - Returns: The created record response with uri and cid
    @MainActor
    private func createCheckinRecord(place: Place, message: String?, credentials: AuthCredentials) async throws -> CreateRecordResponse {
        let currentTime = ISO8601DateFormatter().string(from: Date())
        
        // Build structured location data using community lexicon types
        var locations: [CheckinLocation] = []
        
        // Add geographic coordinates
        let geoLocation = CheckinLocation.geo(CheckinGeoLocation(
            latitude: String(place.latitude),
            longitude: String(place.longitude),
            name: place.name
        ))
        locations.append(geoLocation)
        
        // Add address information if available from place tags
        if let address = buildAddressFromPlace(place) {
            locations.append(.address(address))
        }
        
        // Create the check-in record
        let checkinRecord = CheckinRecord(
            text: buildCheckinRecordText(place: place, message: message),
            createdAt: currentTime,
            locations: locations
        )
        
        let createRequest = CreateCheckinRequest(
            repo: credentials.did,
            collection: "app.dropanchor.checkin",
            record: checkinRecord
        )
        
        let request = try buildAuthenticatedRequest(
            endpoint: "/xrpc/com.atproto.repo.createRecord",
            method: "POST",
            body: createRequest,
            accessToken: credentials.accessToken
        )
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BlueskyError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw BlueskyError.httpError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(CreateRecordResponse.self, from: data)
    }
    
    /// Step 2: Create the main feed post with embed pointing to the check-in record
    /// - Parameters:
    ///   - place: The place being checked into
    ///   - message: Optional custom message
    ///   - embedRecord: The check-in record to embed
    ///   - credentials: Authentication credentials
    /// - Returns: Success status
    @MainActor
    private func createFeedPost(place: Place, message: String?, embedRecord: CreateRecordResponse, credentials: AuthCredentials) async throws -> Bool {
        let (postText, facets) = buildCheckInTextWithFacets(place: place, customMessage: message)
        
        // Create embed pointing to the check-in record
        let embed = PostEmbed(
            record: EmbedRecord(
                uri: embedRecord.uri,
                cid: embedRecord.cid
            )
        )
        
        let post = CreatePostRequest(
            repo: credentials.did,
            collection: "app.bsky.feed.post",
            record: PostRecord(
                text: postText,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                facets: facets,
                embed: embed
            )
        )
        
        let request = try buildAuthenticatedRequest(
            endpoint: "/xrpc/com.atproto.repo.createRecord",
            method: "POST",
            body: post,
            accessToken: credentials.accessToken
        )
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BlueskyError.invalidResponse
        }
        
        return httpResponse.statusCode == 200
    }
    
    /// Build text content for the check-in record (shorter, structured label)
    /// - Parameters:
    ///   - place: The place being checked into
    ///   - message: Optional custom message
    /// - Returns: Text for the check-in record
    private func buildCheckinRecordText(place: Place, message: String?) -> String {
        if let message = message, !message.isEmpty {
            return "\(place.name) - \(message)"
        } else {
            return place.name
        }
    }
    
    /// Build address from place tags if available
    /// - Parameter place: The place with potential address tags
    /// - Returns: Address object or nil if insufficient data
    private func buildAddressFromPlace(_ place: Place) -> CheckinAddress? {
        let tags = place.tags
        
        // Check if we have enough address components to make it worthwhile
        let hasStreet = tags["addr:street"] != nil || tags["addr:housenumber"] != nil
        let hasLocality = tags["addr:city"] != nil || tags["addr:village"] != nil || tags["addr:town"] != nil
        let hasCountry = tags["addr:country"] != nil
        
        guard hasStreet || hasLocality || hasCountry else {
            return nil
        }
        
        // Build street address
        var streetComponents: [String] = []
        if let housenumber = tags["addr:housenumber"] {
            streetComponents.append(housenumber)
        }
        if let street = tags["addr:street"] {
            streetComponents.append(street)
        }
        let streetAddress = streetComponents.isEmpty ? nil : streetComponents.joined(separator: " ")
        
        // Get locality (try different tag variants)
        let locality = tags["addr:city"] ?? tags["addr:village"] ?? tags["addr:town"]
        
        return CheckinAddress(
            country: tags["addr:country"],
            locality: locality,
            region: tags["addr:state"] ?? tags["addr:province"],
            street: streetAddress,
            postalCode: tags["addr:postcode"],
            name: place.name
        )
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func refreshSession(context: ModelContext) async throws {
        guard let currentCredentials = credentials else {
            throw BlueskyError.notAuthenticated
        }
        
        let refreshRequest = RefreshRequest(refreshJwt: currentCredentials.refreshToken)
        let request = try buildRequest(
            endpoint: "/xrpc/com.atproto.server.refreshSession",
            method: "POST",
            body: refreshRequest
        )
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BlueskyError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            // Refresh failed, need to re-authenticate
            signOut(context: context)
            throw BlueskyError.sessionExpired
        }
        
        let refreshResponse = try JSONDecoder().decode(RefreshResponse.self, from: data)
        
        let newCredentials = AuthCredentials(
            handle: currentCredentials.handle,
            accessToken: refreshResponse.accessJwt,
            refreshToken: refreshResponse.refreshJwt,
            did: currentCredentials.did,
            expiresAt: Date().addingTimeInterval(3600) // 1 hour from now
        )
        
        try AuthCredentials.save(newCredentials, to: context)
        self.credentials = newCredentials
    }
    
    private func buildCheckInText(place: Place, customMessage: String?) -> String {
        let (text, _) = buildCheckInTextWithFacets(place: place, customMessage: customMessage)
        return text
    }
    
    /// Build check-in text with rich text facets for links and hashtags
    /// - Parameters:
    ///   - place: The place being checked into
    ///   - customMessage: Optional custom message from user
    /// - Returns: Tuple of (text, facets) for Bluesky post
    internal func buildCheckInTextWithFacets(place: Place, customMessage: String?) -> (String, [RichTextFacet]) {
        var text = ""
        var facets: [RichTextFacet] = []
        
        // Start with user's literal message (no quotes or generated emoji)
        if let message = customMessage, !message.isEmpty {
            // Calculate remaining characters for user message
            // Footer: "Dropped ⚓ at [name] #checkin #dropanchor" + 2 newlines
            let footerBaseLength = 12 + place.name.count + 19 + 2 // ~33 + place name length
            let maxUserMessageLength = max(50, 300 - footerBaseLength) // At least 50 chars for user
            
            let trimmedMessage = String(message.prefix(maxUserMessageLength))
            text += trimmedMessage
            
            // Detect facets in user message
            let userMessageFacets = detectFacetsInText(trimmedMessage)
            facets.append(contentsOf: userMessageFacets)
            
            text += "\n\n" // Blank line
        }
        
        // Add "Dropped ⚓ at <location>" with venue name as link
        let osmURL = "https://www.openstreetmap.org/\(place.elementType.rawValue)/\(place.elementId)"
        let anchorText = "Dropped ⚓ at \(place.name) #checkin #dropanchor"
        
        // Calculate byte positions for facets using UTF-8 encoding
        let textBeforeAnchor = text
        let textBeforeVenueName = textBeforeAnchor + "Dropped ⚓ at "
        let textBeforeFirstHashtag = textBeforeVenueName + place.name + " "
        let textBeforeSecondHashtag = textBeforeFirstHashtag + "#checkin "
        
        text += anchorText
        
        // Create facets using proper UTF-8 byte indexing
        // Link facet for venue name (links to OpenStreetMap)
        let venueNameStartBytes = textBeforeVenueName.utf8.count
        let venueNameEndBytes = (textBeforeVenueName + place.name).utf8.count
        
        facets.append(RichTextFacet(
            index: ByteRange(byteStart: venueNameStartBytes, byteEnd: venueNameEndBytes),
            features: [.link(uri: osmURL)]
        ))
        
        // First hashtag facet for #checkin (including the #)
        let firstHashtagStartBytes = textBeforeFirstHashtag.utf8.count
        let firstHashtagEndBytes = (textBeforeFirstHashtag + "#checkin").utf8.count
        
        facets.append(RichTextFacet(
            index: ByteRange(byteStart: firstHashtagStartBytes, byteEnd: firstHashtagEndBytes),
            features: [.tag(tag: "checkin")]
        ))
        
        // Second hashtag facet for #dropanchor (including the #)
        let secondHashtagStartBytes = textBeforeSecondHashtag.utf8.count
        let secondHashtagEndBytes = (textBeforeSecondHashtag + "#dropanchor").utf8.count
        
        facets.append(RichTextFacet(
            index: ByteRange(byteStart: secondHashtagStartBytes, byteEnd: secondHashtagEndBytes),
            features: [.tag(tag: "dropanchor")]
        ))
        
        return (text, facets)
    }
    
    /// Detect rich text facets (URLs, hashtags, mentions) in text
    /// - Parameter text: The text to analyze
    /// - Returns: Array of detected facets with proper UTF-8 byte indexing
    private func detectFacetsInText(_ text: String) -> [RichTextFacet] {
        var facets: [RichTextFacet] = []
        
        // Detect URLs
        facets.append(contentsOf: detectURLFacets(in: text))
        
        // Detect hashtags
        facets.append(contentsOf: detectHashtagFacets(in: text))
        
        // Detect mentions
        facets.append(contentsOf: detectMentionFacets(in: text))
        
        // Sort facets by start position and remove any overlaps
        return removeOverlappingFacets(facets.sorted { $0.index.byteStart < $1.index.byteStart })
    }
    
    /// Detect URL facets in text
    private func detectURLFacets(in text: String) -> [RichTextFacet] {
        var facets: [RichTextFacet] = []
        
        // Regex for URLs - matches both http(s):// and domain names
        // Based on Bluesky documentation pattern
        let pattern = #"(?:^|\s|\()((?:https?://[\S]+)|(?:[a-z][a-z0-9]*(?:\.[a-z0-9]+)+[\S]*))"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return facets
        }
        
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        for match in matches {
            guard match.numberOfRanges > 1 else { continue }
            
            let urlRange = match.range(at: 1) // Capture group 1 is the URL
            guard urlRange.location != NSNotFound else { continue }
            
            // Convert UTF-16 range to string
            let utf16StartIndex = text.utf16.index(text.utf16.startIndex, offsetBy: urlRange.location)
            let utf16EndIndex = text.utf16.index(utf16StartIndex, offsetBy: urlRange.length)
            
            let startIndex = String.Index(utf16StartIndex, within: text)!
            let endIndex = String.Index(utf16EndIndex, within: text)!
            
            let urlString = String(text[startIndex..<endIndex])
            var cleanURL: String = urlString
            
            // Strip ending punctuation
            let trailingPunctuationPattern = #"[.,;!?]+$"#
            if let punctuationRegex = try? NSRegularExpression(pattern: trailingPunctuationPattern) {
                let range = NSRange(location: 0, length: cleanURL.utf16.count)
                cleanURL = punctuationRegex.stringByReplacingMatches(in: cleanURL, options: [], range: range, withTemplate: "")
            }
            
            // Strip trailing ) if no opening ( in URL
            if cleanURL.hasSuffix(")") && !cleanURL.contains("(") {
                cleanURL = String(cleanURL.dropLast())
            }
            
            // Add https:// prefix if needed
            var uri: String = cleanURL
            if !uri.starts(with: "http") {
                // Validate it's a real domain
                if isValidDomain(cleanURL.components(separatedBy: "/").first ?? "") {
                    uri = "https://\(cleanURL)"
                } else {
                    continue
                }
            }
            
            // Calculate UTF-8 byte positions
            let textBeforeUrl = String(text[..<startIndex])
            let adjustedURLLength = cleanURL.utf8.count
            
            let byteStart = textBeforeUrl.utf8.count
            let byteEnd = byteStart + adjustedURLLength
            
            facets.append(RichTextFacet(
                index: ByteRange(byteStart: byteStart, byteEnd: byteEnd),
                features: [.link(uri: uri)]
            ))
        }
        
        return facets
    }
    
    /// Detect hashtag facets in text
    private func detectHashtagFacets(in text: String) -> [RichTextFacet] {
        var facets: [RichTextFacet] = []
        
        // Regex for hashtags - based on Bluesky documentation
        let pattern = #"(?:^|\s)(#[^\d\s]\S*)(?=\s|$)"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return facets
        }
        
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        for match in matches {
            guard match.numberOfRanges > 1 else { continue }
            
            let hashtagRange = match.range(at: 1) // Capture group 1 is the hashtag
            guard hashtagRange.location != NSNotFound else { continue }
            
            // Convert UTF-16 range to string
            let utf16StartIndex = text.utf16.index(text.utf16.startIndex, offsetBy: hashtagRange.location)
            let utf16EndIndex = text.utf16.index(utf16StartIndex, offsetBy: hashtagRange.length)
            
            let startIndex = String.Index(utf16StartIndex, within: text)!
            let endIndex = String.Index(utf16EndIndex, within: text)!
            
            var hashtag: String = String(text[startIndex..<endIndex])
            
            // Strip ending punctuation
            let trailingPunctuationPattern = #"\p{P}+$"#
            if let punctuationRegex = try? NSRegularExpression(pattern: trailingPunctuationPattern, options: []) {
                let range = NSRange(location: 0, length: hashtag.utf16.count)
                hashtag = punctuationRegex.stringByReplacingMatches(in: hashtag, options: [], range: range, withTemplate: "")
            }
            
            // Check max length (66 chars including #)
            guard hashtag.count <= 66 else { continue }
            
            // Calculate UTF-8 byte positions
            let textBeforeHashtag = String(text[..<startIndex])
            let adjustedHashtagLength = hashtag.utf8.count
            
            let byteStart = textBeforeHashtag.utf8.count
            let byteEnd = byteStart + adjustedHashtagLength
            
            // Remove # for tag value
            let tagValue = String(hashtag.dropFirst())
            
            facets.append(RichTextFacet(
                index: ByteRange(byteStart: byteStart, byteEnd: byteEnd),
                features: [.tag(tag: tagValue)]
            ))
        }
        
        return facets
    }
    
    /// Detect mention facets in text
    private func detectMentionFacets(in text: String) -> [RichTextFacet] {
        var facets: [RichTextFacet] = []
        
        // Simplified regex for mentions - based on Bluesky documentation example
        let pattern = #"(?:^|\s|\()(@([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)(?=\s|$|\)|\.|\!|\?|,)"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return facets
        }
        
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        for match in matches {
            guard match.numberOfRanges > 1 else { continue }
            
            let mentionRange = match.range(at: 1) // Capture group 1 is the @handle
            guard mentionRange.location != NSNotFound else { continue }
            
            // Convert UTF-16 range to string
            let utf16StartIndex = text.utf16.index(text.utf16.startIndex, offsetBy: mentionRange.location)
            let utf16EndIndex = text.utf16.index(utf16StartIndex, offsetBy: mentionRange.length)
            
            let startIndex = String.Index(utf16StartIndex, within: text)!
            let endIndex = String.Index(utf16EndIndex, within: text)!
            
            let mentionText: String = String(text[startIndex..<endIndex])
            
            // Extract handle (remove @)
            let handle = String(mentionText.dropFirst())
            
            // Validate domain
            guard isValidDomain(handle) else { continue }
            
            // Calculate UTF-8 byte positions
            let textBeforeMention = String(text[..<startIndex])
            
            let byteStart = textBeforeMention.utf8.count
            let byteEnd = byteStart + mentionText.utf8.count // @handle in UTF-8 bytes
            
            facets.append(RichTextFacet(
                index: ByteRange(byteStart: byteStart, byteEnd: byteEnd),
                features: [.mention(did: handle)] // Note: In production, this should be resolved to a DID
            ))
        }
        
        return facets
    }
    
    /// Validate if a string looks like a valid domain
    private func isValidDomain(_ domain: String) -> Bool {
        // Simple domain validation - has at least one dot and valid TLD
        let components = domain.components(separatedBy: ".")
        guard components.count >= 2 else { return false }
        
        // Check if it has a reasonable TLD
        let tld = components.last ?? ""
        let validTLDs = ["com", "org", "net", "edu", "gov", "mil", "int", "co", "uk", "ca", "de", "fr", "jp", "au", "br", "cn", "ru", "in", "test", "bsky", "social"]
        
        // Reject "invalid" TLD and require either known TLD or at least 2 chars
        if tld == "invalid" {
            return false
        }
        
        return validTLDs.contains(tld) || tld.count >= 2
    }
    
    /// Remove overlapping facets, keeping the first one in case of overlap
    private func removeOverlappingFacets(_ facets: [RichTextFacet]) -> [RichTextFacet] {
        var result: [RichTextFacet] = []
        
        for facet in facets {
            let hasOverlap = result.contains { existing in
                // Check if ranges overlap
                let existingRange = existing.index
                let newRange = facet.index
                
                return (newRange.byteStart < existingRange.byteEnd && newRange.byteEnd > existingRange.byteStart)
            }
            
            if !hasOverlap {
                result.append(facet)
            }
        }
        
        return result
    }
    
    private func buildRequest<T: Codable>(
        endpoint: String,
        method: String,
        body: T? = nil
    ) throws -> URLRequest {
        guard let url = URL(string: baseURL + endpoint) else {
            throw BlueskyError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Anchor/1.0 (macOS)", forHTTPHeaderField: "User-Agent")
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        return request
    }
    
    private func buildAuthenticatedRequest<T: Codable>(
        endpoint: String,
        method: String,
        body: T? = nil,
        accessToken: String
    ) throws -> URLRequest {
        var request = try buildRequest(endpoint: endpoint, method: method, body: body)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return request
    }
    

}

// MARK: - Request/Response Models

private struct LoginRequest: Codable {
    let identifier: String
    let password: String
}

private struct LoginResponse: Codable {
    let accessJwt: String
    let refreshJwt: String
    let handle: String
    let did: String
    let email: String?
    let emailConfirmed: Bool?
}

private struct RefreshRequest: Codable {
    let refreshJwt: String
}

private struct RefreshResponse: Codable {
    let accessJwt: String
    let refreshJwt: String
    let handle: String
    let did: String
}

private struct CreatePostRequest: Codable {
    let repo: String
    let collection: String
    let record: PostRecord
}

private struct PostRecord: Codable {
    let text: String
    let createdAt: String
    let type: String = "app.bsky.feed.post"
    
    // Rich text facets for links, mentions, and hashtags
    let facets: [RichTextFacet]?
    
    // Embed for pointing to check-in record
    let embed: PostEmbed?
    
    private enum CodingKeys: String, CodingKey {
        case text, createdAt, facets, embed
        case type = "$type"
    }
    
    init(text: String, createdAt: String, facets: [RichTextFacet]? = nil, embed: PostEmbed? = nil) {
        self.text = text
        self.createdAt = createdAt
        self.facets = facets
        self.embed = embed
    }
}

// MARK: - Check-in Record Models

private struct CreateCheckinRequest: Codable {
    let repo: String
    let collection: String
    let record: CheckinRecord
}

private struct CheckinRecord: Codable {
    let text: String
    let createdAt: String
    let type: String = "app.dropanchor.checkin"
    let locations: [CheckinLocation]
    
    private enum CodingKeys: String, CodingKey {
        case text, createdAt, locations
        case type = "$type"
    }
    
    init(text: String, createdAt: String, locations: [CheckinLocation]) {
        self.text = text
        self.createdAt = createdAt
        self.locations = locations
    }
}

private enum CheckinLocation: Codable {
    case geo(CheckinGeoLocation)
    case address(CheckinAddress)
    
    func encode(to encoder: Encoder) throws {
        switch self {
        case .geo(let geo):
            try geo.encode(to: encoder)
        case .address(let address):
            try address.encode(to: encoder)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "community.lexicon.location.geo":
            let geo = try CheckinGeoLocation(from: decoder)
            self = .geo(geo)
        case "community.lexicon.location.address":
            let address = try CheckinAddress(from: decoder)
            self = .address(address)
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown location type: \(type)")
            )
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case type = "$type"
    }
}

private struct CheckinGeoLocation: Codable {
    let latitude: String
    let longitude: String
    let name: String?
    let type: String = "community.lexicon.location.geo"
    
    private enum CodingKeys: String, CodingKey {
        case latitude, longitude, name
        case type = "$type"
    }
    
    init(latitude: String, longitude: String, name: String?) {
        self.latitude = latitude
        self.longitude = longitude
        self.name = name
    }
}

private struct CheckinAddress: Codable {
    let country: String?
    let locality: String?
    let region: String?
    let street: String?
    let postalCode: String?
    let name: String?
    let type: String = "community.lexicon.location.address"
    
    private enum CodingKeys: String, CodingKey {
        case country, locality, region, street, postalCode, name
        case type = "$type"
    }
    
    init(country: String?, locality: String?, region: String?, street: String?, postalCode: String?, name: String?) {
        self.country = country
        self.locality = locality
        self.region = region
        self.street = street
        self.postalCode = postalCode
        self.name = name
    }
}

// MARK: - Embed Models

private struct PostEmbed: Codable {
    let type: String = "app.bsky.embed.record"
    let record: EmbedRecord
    
    private enum CodingKeys: String, CodingKey {
        case record
        case type = "$type"
    }
    
    init(record: EmbedRecord) {
        self.record = record
    }
}

private struct EmbedRecord: Codable {
    let uri: String
    let cid: String
    
    init(uri: String, cid: String) {
        self.uri = uri
        self.cid = cid
    }
}

private struct CreateRecordResponse: Codable {
    let uri: String
    let cid: String
}

// MARK: - Rich Text Facets

internal struct RichTextFacet: Codable {
    let index: ByteRange
    let features: [RichTextFeature]
}

internal struct ByteRange: Codable {
    let byteStart: Int
    let byteEnd: Int
}

internal enum RichTextFeature: Codable {
    case link(uri: String)
    case mention(did: String)
    case tag(tag: String)
    
    private enum CodingKeys: String, CodingKey {
        case type = "$type"
        case uri, did, tag
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .link(let uri):
            try container.encode("app.bsky.richtext.facet#link", forKey: .type)
            try container.encode(uri, forKey: .uri)
        case .mention(let did):
            try container.encode("app.bsky.richtext.facet#mention", forKey: .type)
            try container.encode(did, forKey: .did)
        case .tag(let tag):
            try container.encode("app.bsky.richtext.facet#tag", forKey: .type)
            try container.encode(tag, forKey: .tag)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "app.bsky.richtext.facet#link":
            let uri = try container.decode(String.self, forKey: .uri)
            self = .link(uri: uri)
        case "app.bsky.richtext.facet#mention":
            let did = try container.decode(String.self, forKey: .did)
            self = .mention(did: did)
        case "app.bsky.richtext.facet#tag":
            let tag = try container.decode(String.self, forKey: .tag)
            self = .tag(tag: tag)
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown facet type: \(type)")
            )
        }
    }
}

// MARK: - Error Types

public enum BlueskyError: LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case invalidCredentials
    case notAuthenticated
    case sessionExpired
    case encodingError(Error)
    case decodingError(Error)

    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Bluesky API URL"
        case .invalidResponse:
            return "Invalid response from Bluesky"
        case .httpError(let code):
            return "HTTP error \(code) from Bluesky API"
        case .invalidCredentials:
            return "Invalid username or password"
        case .notAuthenticated:
            return "Not authenticated with Bluesky"
        case .sessionExpired:
            return "Session expired, please sign in again"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}