//
//  DateParsingTests.swift
//  ATProtoFoundation
//
//  Tests for ISO8601DateFormatter.flexibleDate() utility
//

import Foundation
import Testing
@testable import ATProtoFoundation

@Suite("Date Parsing", .tags(.unit, .models))
struct DateParsingTests {

    // MARK: - Valid Date Parsing Tests

    @Test("Parse date with fractional seconds")
    func parseDateWithFractionalSeconds() {
        let dateString = "2025-01-15T12:30:45.123Z"
        let date = ISO8601DateFormatter.flexibleDate(from: dateString)

        #expect(date != nil)

        if let date = date {
            let calendar = Calendar(identifier: .gregorian)
            var components = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: date)
            #expect(components.year == 2025)
            #expect(components.month == 1)
            #expect(components.day == 15)
            #expect(components.hour == 12)
            #expect(components.minute == 30)
            #expect(components.second == 45)
        }
    }

    @Test("Parse date without fractional seconds")
    func parseDateWithoutFractionalSeconds() {
        let dateString = "2025-01-15T12:30:45Z"
        let date = ISO8601DateFormatter.flexibleDate(from: dateString)

        #expect(date != nil)

        if let date = date {
            let calendar = Calendar(identifier: .gregorian)
            var components = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: date)
            #expect(components.year == 2025)
            #expect(components.month == 1)
            #expect(components.day == 15)
        }
    }

    @Test("Parse date with milliseconds precision")
    func parseDateWithMilliseconds() {
        let dateString = "2024-06-15T08:45:30.999Z"
        let date = ISO8601DateFormatter.flexibleDate(from: dateString)

        #expect(date != nil)
    }

    @Test("Parse date with microseconds precision")
    func parseDateWithMicroseconds() {
        let dateString = "2024-06-15T08:45:30.123456Z"
        let date = ISO8601DateFormatter.flexibleDate(from: dateString)

        #expect(date != nil)
    }

    // MARK: - Invalid Date Parsing Tests

    @Test("Invalid date string returns nil")
    func invalidDateStringReturnsNil() {
        let invalidStrings = [
            "not-a-date",
            "2025-13-45", // Invalid month/day
            "",
            "2025",
            "2025-01",
        ]

        for dateString in invalidStrings {
            let date = ISO8601DateFormatter.flexibleDate(from: dateString)
            #expect(date == nil, "Expected nil for: \(dateString)")
        }
    }

    // MARK: - Edge Cases

    @Test("Parse midnight UTC")
    func parseMidnightUTC() {
        let dateString = "2025-01-01T00:00:00Z"
        let date = ISO8601DateFormatter.flexibleDate(from: dateString)

        #expect(date != nil)

        if let date = date {
            let calendar = Calendar(identifier: .gregorian)
            var components = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: date)
            #expect(components.hour == 0)
            #expect(components.minute == 0)
            #expect(components.second == 0)
        }
    }

    @Test("Parse end of day UTC")
    func parseEndOfDayUTC() {
        let dateString = "2025-12-31T23:59:59Z"
        let date = ISO8601DateFormatter.flexibleDate(from: dateString)

        #expect(date != nil)

        if let date = date {
            let calendar = Calendar(identifier: .gregorian)
            var components = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: date)
            #expect(components.hour == 23)
            #expect(components.minute == 59)
            #expect(components.second == 59)
        }
    }

    @Test("Both formats parse to equivalent dates")
    func bothFormatsParseSameTime() {
        // Same moment, different precision
        let withFractional = "2025-01-15T12:30:45.000Z"
        let withoutFractional = "2025-01-15T12:30:45Z"

        let date1 = ISO8601DateFormatter.flexibleDate(from: withFractional)
        let date2 = ISO8601DateFormatter.flexibleDate(from: withoutFractional)

        #expect(date1 != nil)
        #expect(date2 != nil)

        if let d1 = date1, let d2 = date2 {
            // Should be within 1 second of each other
            #expect(abs(d1.timeIntervalSince(d2)) < 1.0)
        }
    }
}
