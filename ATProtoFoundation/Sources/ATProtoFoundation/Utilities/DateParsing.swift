import Foundation

// MARK: - ISO8601 Date Parsing Utilities

extension ISO8601DateFormatter {
    /// Parse ISO8601 date string with flexible format handling
    ///
    /// AT Protocol APIs return timestamps with varying precision. Some include
    /// fractional seconds (e.g., `2025-08-11T18:34:55.966Z`) while others use
    /// basic format (e.g., `2025-08-11T18:34:55Z`). This method handles both.
    ///
    /// - Parameter string: ISO8601 formatted date string
    /// - Returns: Parsed date, or nil if parsing fails
    ///
    /// Example:
    /// ```swift
    /// let date1 = ISO8601DateFormatter.flexibleDate(from: "2025-08-11T18:34:55.966Z")
    /// let date2 = ISO8601DateFormatter.flexibleDate(from: "2025-08-11T18:34:55Z")
    /// // Both return valid Date objects
    /// ```
    public static func flexibleDate(from string: String) -> Date? {
        // Try with fractional seconds first (for real API data like "2025-08-11T18:34:55.966Z")
        let formatterWithFractional = ISO8601DateFormatter()
        formatterWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatterWithFractional.date(from: string) {
            return date
        }

        // Fallback to format without fractional seconds (for test data like "2024-01-01T12:00:00Z")
        let formatterBasic = ISO8601DateFormatter()
        return formatterBasic.date(from: string)
    }
}
