//
//  FeedTextProcessor.swift
//  AnchorKit
//
//  Created by Tijs Teulings on 27/06/2025.
//

import Foundation

/// Utility for processing text content in feed posts
/// This is separate from RichTextProcessor which handles creating posts with rich text facets
public final class FeedTextProcessor: Sendable {
    public static let shared = FeedTextProcessor()

    private init() {}

    /// Extract the user's personal message from a check-in post
    /// - Parameters:
    ///   - text: The full post text
    ///   - locations: Location data to help filter out location-related content
    /// - Returns: The personal message if substantial enough, otherwise nil
    public func extractPersonalMessage(from text: String, locations: [LocationRepresentable]?) -> String? {
        guard let locations = locations, !locations.isEmpty else {
            // If no location data, return the full text if it's not just an emoji
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.count > 3 ? trimmed : nil
        }

        var processedText = text

        // Remove all location names from the text
        for location in locations {
            let locationName = getLocationName(from: location)
            if let locationName, !locationName.isEmpty {
                // Remove exact matches (case insensitive)
                processedText = processedText.replacingOccurrences(
                    of: locationName,
                    with: "",
                    options: .caseInsensitive
                )
            }
        }

        // Clean up the remaining text
        let cleaned = processedText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "  +", with: " ", options: .regularExpression) // Remove multiple spaces

        // Return nil if what's left is just whitespace, single emoji, or very short
        return cleaned.count > 3 ? cleaned : nil
    }

    /// Extract a category icon from text content
    /// - Parameter text: The text to extract emoji from
    /// - Returns: The first emoji found, or a default location icon
    public func extractCategoryIcon(from text: String) -> String {
        // Simple emoji detection - find first emoji-like character
        for char in text where char.isEmoji {
            return String(char)
        }
        return "📍" // Default location icon
    }

    // MARK: - Private Helper Methods

    private func getLocationName(from location: LocationRepresentable) -> String? {
        return location.displayName
    }
}

// MARK: - Character Extension for Emoji Detection

private extension Character {
    var isEmoji: Bool {
        // Check if character is in emoji ranges
        guard let scalar = unicodeScalars.first else { return false }

        switch scalar.value {
        case 0x1F600...0x1F64F, // Emoticons
             0x1F300...0x1F5FF, // Misc Symbols and Pictographs
             0x1F680...0x1F6FF, // Transport and Map Symbols
             0x1F1E6...0x1F1FF, // Regional indicator symbols
             0x2600...0x26FF,   // Misc symbols
             0x2700...0x27BF,   // Dingbats
             0xFE00...0xFE0F,   // Variation selectors
             0x1F900...0x1F9FF, // Supplemental Symbols and Pictographs
             0x1F018...0x1F270: // Various emoji blocks
            return true
        default:
            return false
        }
    }
}
