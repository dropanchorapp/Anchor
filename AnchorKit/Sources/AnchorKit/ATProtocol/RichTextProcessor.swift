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

    public func detectFacets(in text: String) -> [RichTextFacet] {
        var facets: [RichTextFacet] = []

        // Detect URLs
        facets.append(contentsOf: detectURLs(in: text))

        // Detect mentions
        facets.append(contentsOf: detectMentions(in: text))

        // Detect hashtags
        facets.append(contentsOf: detectHashtags(in: text))

        return facets
    }

    public func buildCheckinText(place: Place, customMessage: String?) -> (text: String, facets: [RichTextFacet]) {
        var text = ""
        var facets: [RichTextFacet] = []

        // Add custom message if provided
        if let customMessage, !customMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            text = customMessage + "\n\n"

            // Detect facets in custom message
            let customMessageFacets = detectFacets(in: customMessage)
            facets.append(contentsOf: customMessageFacets)
        }

        // Add check-in text
        let checkinPrefix = "Dropped ⚓ at "
        let checkinSuffix = " #checkin #dropanchor"
        let placeName = place.name

        let checkinText = checkinPrefix + placeName + checkinSuffix
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
            index: ByteRange(byteStart: checkinHashtagStart + 1, byteEnd: checkinHashtagEnd + 1), // +1 to skip space, include #
            features: [.tag(tag: "checkin")]
        )
        facets.append(checkinHashtagFacet)

        let dropanchorHashtagStart = checkinHashtagEnd + " ".utf8.count
        let dropanchorHashtagEnd = dropanchorHashtagStart + "#dropanchor".utf8.count

        let dropanchorHashtagFacet = RichTextFacet(
            index: ByteRange(byteStart: dropanchorHashtagStart + 1, byteEnd: dropanchorHashtagEnd + 1), // +1 to skip space, include #
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
            let pattern = "@([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*)"
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
}
