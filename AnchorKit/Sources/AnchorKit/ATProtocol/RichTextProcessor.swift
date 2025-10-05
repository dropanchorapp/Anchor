import Foundation

// MARK: - Rich Text Processing Protocol

public protocol RichTextProcessorProtocol: Sendable {
    func detectFacets(in text: String) -> [RichTextFacet]
    func buildCheckinText(place: Place, customMessage: String?) -> (text: String, facets: [RichTextFacet])
}

// MARK: - Rich Text Processor Implementation

public final class RichTextProcessor: RichTextProcessorProtocol {
    public init() {}

    // MARK: - Public Methods

    public nonisolated func detectFacets(in text: String) -> [RichTextFacet] {
        var facets: [RichTextFacet] = []

        // Detect URLs
        facets.append(contentsOf: detectURLs(in: text))

        // Detect mentions
        facets.append(contentsOf: detectMentions(in: text))

        // Detect hashtags
        facets.append(contentsOf: detectHashtags(in: text))

        return facets
    }

    /// Builds enhanced text content for Bluesky social media posts
    ///
    /// **IMPORTANT DESIGN DECISION:**
    /// This method creates marketing-friendly posts with location taglines, hashtags,
    /// and rich text formatting for social media engagement on Bluesky.
    ///
    /// This is different from check-in records stored on the user's PDS using strongref
    /// architecture, which contain only the user's original message and structured location data.
    ///
    /// The enhanced format includes:
    /// - User's message (or default if empty)
    /// - Formatted location info ("at [Place Name] 🏔️")
    /// - Marketing hashtags (#checkin #dropanchor)
    /// - Rich text facets for links and hashtags
    ///
    /// - Parameters:
    ///   - place: The place being checked into
    ///   - customMessage: The user's original message, if any
    /// - Returns: Enhanced text with facets for social media posting
    public nonisolated func buildCheckinText(place: Place, customMessage: String?) -> (text: String, facets: [RichTextFacet]) {
        var text = ""
        var facets: [RichTextFacet] = []

        // Start with user's message, or use default marketing message if empty
        let messageToUse = if let customMessage,
                              !customMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            customMessage
        } else {
            AnchorConfig.shared.defaultCheckInMessage
        }

        text = messageToUse + "\n\n"

        // Detect facets in the message
        let messageFacets = detectFacets(in: messageToUse)
        facets.append(contentsOf: messageFacets)

        // Add marketing tagline with location info and hashtags
        let checkinPrefix = convertToItalic("at ")
        let checkinSuffix = " #checkin #dropanchor"
        let placeName = convertToBoldItalic(place.name)
        let placeIcon = place.icon

        let checkinText = checkinPrefix + placeName + " " + placeIcon + checkinSuffix
        text += checkinText

        // Calculate byte offsets for place name link
        let prefixByteCount = text.prefix(text.count - checkinText.count + checkinPrefix.count).utf8.count
        let placeNameByteCount = placeName.utf8.count

        // Add place name as link facet
        let placeURL = buildPlaceURL(for: place)
        let placeFacet = RichTextFacet(
            index: ByteRange(byteStart: prefixByteCount, byteEnd: prefixByteCount + placeNameByteCount),
            features: [.link(uri: placeURL)]
        )
        facets.append(placeFacet)

        // Add hashtag facets
        let checkinHashtagStart = text.utf8.count - " #checkin #dropanchor".utf8.count
        let checkinHashtagEnd = checkinHashtagStart + "#checkin".utf8.count

        let checkinHashtagFacet = RichTextFacet(
            index: ByteRange(
                byteStart: checkinHashtagStart + 1,
                byteEnd: checkinHashtagEnd + 1
            ), // +1 to skip space, include #
            features: [.tag(tag: "checkin")]
        )
        facets.append(checkinHashtagFacet)

        let dropanchorHashtagStart = checkinHashtagEnd + " ".utf8.count
        let dropanchorHashtagEnd = dropanchorHashtagStart + "#dropanchor".utf8.count

        let dropanchorHashtagFacet = RichTextFacet(
            index: ByteRange(
                byteStart: dropanchorHashtagStart + 1,
                byteEnd: dropanchorHashtagEnd + 1
            ), // +1 to skip space, include #
            features: [.tag(tag: "dropanchor")]
        )
        facets.append(dropanchorHashtagFacet)

        return (text, facets)
    }

    // MARK: - Private Methods

    private func detectURLs(in text: String) -> [RichTextFacet] {
        var facets: [RichTextFacet] = []

        do {
            // Use Foundation's NSDataDetector for robust URL detection and validation
            // This leverages Apple's battle-tested algorithms for finding valid URLs
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

            for match in matches {
                guard match.url != nil else { continue } // Ensure it's a valid URL

                let range = match.range
                let startIndex = text.utf16.index(text.startIndex, offsetBy: range.location)
                let endIndex = text.utf16.index(startIndex, offsetBy: range.length)
                let matchedText = String(text[startIndex ..< endIndex])

                // Convert to byte indices for AT Protocol
                let beforeMatch = String(text.prefix(upTo: startIndex))
                let byteStart = beforeMatch.utf8.count
                let byteEnd = byteStart + matchedText.utf8.count

                // Use NSDataDetector for validation, but preserve user-friendly display URLs
                var displayURL = matchedText
                if matchedText.lowercased().hasPrefix("www.") {
                    // Add https:// prefix for www URLs (user-friendly default)
                    displayURL = "https://" + matchedText
                }
                // Keep unicode characters for better readability in social media context

                let facet = RichTextFacet(
                    index: ByteRange(byteStart: byteStart, byteEnd: byteEnd),
                    features: [.link(uri: displayURL)]
                )
                facets.append(facet)
            }
        } catch {
            // Fallback: if data detector fails, return empty (graceful degradation)
            print("Warning: URL detection failed: \(error)")
        }

        return facets
    }

    private func detectMentions(in text: String) -> [RichTextFacet] {
        var facets: [RichTextFacet] = []

        do {
            // Pattern for @mentions - must not end with .invalid
            let pattern = "@([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?" +
                         "(?:\\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*)"
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

            for match in matches {
                let range = match.range
                let startIndex = text.utf16.index(text.startIndex, offsetBy: range.location)
                let endIndex = text.utf16.index(startIndex, offsetBy: range.length)
                let matchedText = String(text[startIndex ..< endIndex])

                // Skip domains with invalid TLDs
                let handleForValidation = String(matchedText.dropFirst()) // Remove @
                if !isValidDomain(handleForValidation) {
                    continue
                }

                // Convert to byte indices
                let beforeMatch = String(text.prefix(upTo: startIndex))
                let byteStart = beforeMatch.utf8.count
                let byteEnd = byteStart + matchedText.utf8.count

                // Extract handle (remove @)
                let handle = String(matchedText.dropFirst())

                let facet = RichTextFacet(
                    index: ByteRange(byteStart: byteStart, byteEnd: byteEnd),
                    features: [.mention(did: handle)] // In real implementation, resolve to DID
                )
                facets.append(facet)
            }
        } catch {
            print("Warning: Mention detection failed: \(error)")
        }

        return facets
    }

    private func detectHashtags(in text: String) -> [RichTextFacet] {
        var facets: [RichTextFacet] = []

        do {
            // Pattern for hashtags
            let pattern = "#([a-zA-Z][a-zA-Z0-9_]*)"
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

            for match in matches {
                let range = match.range
                let startIndex = text.utf16.index(text.startIndex, offsetBy: range.location)
                let endIndex = text.utf16.index(startIndex, offsetBy: range.length)
                let matchedText = String(text[startIndex ..< endIndex])

                // Convert to byte indices
                let beforeMatch = String(text.prefix(upTo: startIndex))
                let byteStart = beforeMatch.utf8.count
                let byteEnd = byteStart + matchedText.utf8.count

                // Extract tag (remove #)
                let tag = String(matchedText.dropFirst())

                let facet = RichTextFacet(
                    index: ByteRange(byteStart: byteStart, byteEnd: byteEnd),
                    features: [.tag(tag: tag)]
                )
                facets.append(facet)
            }
        } catch {
            print("Warning: Hashtag detection failed: \(error)")
        }

        return facets
    }

    private func buildPlaceURL(for place: Place) -> String {
        let elementTypePath = switch place.elementType {
        case .node:
            "node"
        case .way:
            "way"
        case .relation:
            "relation"
        }

        return "https://www.openstreetmap.org/\(elementTypePath)/\(place.elementId)"
    }

    /// Validates if a domain has a valid TLD structure for mentions
    private func isValidDomain(_ domain: String) -> Bool {
        // Split domain into components
        let components = domain.split(separator: ".")

        // Must have at least 2 components (e.g., "alice.bsky")
        guard components.count >= 2 else { return false }

        // Get the TLD (last component)
        let tld = String(components.last!)

        // Basic TLD validation:
        // 1. Must be at least 2 characters
        // 2. Must contain only letters (no numbers in real TLDs)
        // 3. Must not be known invalid TLDs
        guard tld.count >= 2 else { return false }
        guard tld.allSatisfy(\.isLetter) else { return false }

        // Invalid TLDs that should not be accepted for mentions
        // Note: .test is actually valid (RFC 6761 reserved for testing)
        let invalidTLDs = ["invalid", "localhost", "local", "example"]
        guard !invalidTLDs.contains(tld.lowercased()) else { return false }

        return true
    }

    /// Converts regular text to Unicode italic characters
    private func convertToItalic(_ text: String) -> String {
        let italicMap: [Character: Character] = [
            // Lowercase letters
            "a": "𝑎", "b": "𝑏", "c": "𝑐", "d": "𝑑", "e": "𝑒", "f": "𝑓", "g": "𝑔", "h": "ℎ",
            "i": "𝑖", "j": "𝑗", "k": "𝑘", "l": "𝑙", "m": "𝑚", "n": "𝑛", "o": "𝑜", "p": "𝑝",
            "q": "𝑞", "r": "𝑟", "s": "𝑠", "t": "𝑡", "u": "𝑢", "v": "𝑣", "w": "𝑤", "x": "𝑥",
            "y": "𝑦", "z": "𝑧",

            // Uppercase letters
            "A": "𝐴", "B": "𝐵", "C": "𝐶", "D": "𝐷", "E": "𝐸", "F": "𝐹", "G": "𝐺", "H": "𝐻",
            "I": "𝐼", "J": "𝐽", "K": "𝐾", "L": "𝐿", "M": "𝑀", "N": "𝑁", "O": "𝑂", "P": "𝑃",
            "Q": "𝑄", "R": "𝑅", "S": "𝑆", "T": "𝑇", "U": "𝑈", "V": "𝑉", "W": "𝑊", "X": "𝑋",
            "Y": "𝑌", "Z": "𝑍",

            // Numbers
            "0": "𝟢", "1": "𝟣", "2": "𝟤", "3": "𝟥", "4": "𝟦", "5": "𝟧", "6": "𝟨", "7": "𝟩",
            "8": "𝟪", "9": "𝟫"
        ]

        return String(text.map { italicMap[$0] ?? $0 })
    }

    /// Converts regular text to Unicode bold italic characters
    private func convertToBoldItalic(_ text: String) -> String {
        let boldItalicMap: [Character: Character] = [
            // Lowercase letters
            "a": "𝒂", "b": "𝒃", "c": "𝒄", "d": "𝒅", "e": "𝒆", "f": "𝒇", "g": "𝒈", "h": "𝒉",
            "i": "𝒊", "j": "𝒋", "k": "𝒌", "l": "𝒍", "m": "𝒎", "n": "𝒏", "o": "𝒐", "p": "𝒑",
            "q": "𝒒", "r": "𝒓", "s": "𝒔", "t": "𝒕", "u": "𝒖", "v": "𝒗", "w": "𝒘", "x": "𝒙",
            "y": "𝒚", "z": "𝒛",

            // Uppercase letters
            "A": "𝑨", "B": "𝑩", "C": "𝑪", "D": "𝑫", "E": "𝑬", "F": "𝑭", "G": "𝑮", "H": "𝑯",
            "I": "𝑰", "J": "𝑱", "K": "𝑲", "L": "𝑳", "M": "𝑴", "N": "𝑵", "O": "𝑶", "P": "𝑷",
            "Q": "𝑸", "R": "𝑹", "S": "𝑺", "T": "𝑻", "U": "𝑼", "V": "𝑽", "W": "𝑾", "X": "𝑿",
            "Y": "𝒀", "Z": "𝒁",

            // Numbers
            "0": "𝟎", "1": "𝟏", "2": "𝟐", "3": "𝟑", "4": "𝟒", "5": "𝟓", "6": "𝟔", "7": "𝟕",
            "8": "𝟖", "9": "𝟗"
        ]

        return String(text.map { boldItalicMap[$0] ?? $0 })
    }
}
