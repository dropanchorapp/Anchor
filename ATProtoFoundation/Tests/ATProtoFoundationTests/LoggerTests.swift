//
//  LoggerTests.swift
//  AnchorKit
//
//  Tests for Logger protocol and implementations
//

import Foundation
import Testing
@testable import ATProtoFoundation

// MARK: - MockLogger Tests

@Suite("MockLogger", .tags(.unit, .auth))
struct MockLoggerTests {

    @Test("MockLogger captures log entries")
    func capturesLogEntries() {
        let logger = MockLogger()

        logger.log("Test message 1", level: .info, category: .auth)
        logger.log("Test message 2", level: .error, category: .network)

        #expect(logger.entries.count == 2)
        #expect(logger.entries[0].message == "Test message 1")
        #expect(logger.entries[0].level == .info)
        #expect(logger.entries[0].category == .auth)
        #expect(logger.entries[1].message == "Test message 2")
        #expect(logger.entries[1].level == .error)
        #expect(logger.entries[1].category == .network)
    }

    @Test("MockLogger filters entries by category")
    func filtersByCategory() {
        let logger = MockLogger()

        logger.log("Auth message 1", level: .info, category: .auth)
        logger.log("Network message", level: .debug, category: .network)
        logger.log("Auth message 2", level: .error, category: .auth)
        logger.log("Session message", level: .info, category: .session)

        let authEntries = logger.entries(for: .auth)
        #expect(authEntries.count == 2)
        #expect(authEntries[0].message == "Auth message 1")
        #expect(authEntries[1].message == "Auth message 2")

        let networkEntries = logger.entries(for: .network)
        #expect(networkEntries.count == 1)
        #expect(networkEntries[0].message == "Network message")
    }

    @Test("MockLogger filters entries by level")
    func filtersByLevel() {
        let logger = MockLogger()

        logger.log("Debug message", level: .debug, category: .auth)
        logger.log("Info message", level: .info, category: .auth)
        logger.log("Warning message", level: .warning, category: .network)
        logger.log("Error message", level: .error, category: .session)

        let errorEntries = logger.entries(for: .error)
        #expect(errorEntries.count == 1)
        #expect(errorEntries[0].message == "Error message")

        let warningEntries = logger.entries(for: .warning)
        #expect(warningEntries.count == 1)
        #expect(warningEntries[0].message == "Warning message")
    }

    @Test("MockLogger clears entries")
    func clearsEntries() {
        let logger = MockLogger()

        logger.log("Message 1", level: .info, category: .auth)
        logger.log("Message 2", level: .debug, category: .network)

        #expect(logger.entries.count == 2)

        logger.clear()

        #expect(logger.entries.isEmpty)
    }

    @Test("MockLogger is thread-safe")
    func isThreadSafe() async {
        let logger = MockLogger()

        // Concurrently log from multiple tasks
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    logger.log("Message \(i)", level: .info, category: .auth)
                }
            }
        }

        // Should have captured all 100 messages without crashes
        #expect(logger.entries.count == 100)
    }

    @Test("MockLogger captures timestamps")
    func capturesTimestamps() {
        let logger = MockLogger()
        let beforeLog = Date()

        logger.log("Test message", level: .info, category: .auth)

        let afterLog = Date()
        let entry = logger.entries.first!

        // Timestamp should be between before and after
        #expect(entry.timestamp >= beforeLog)
        #expect(entry.timestamp <= afterLog)
    }
}

// MARK: - DebugLogger Tests

@Suite("DebugLogger", .tags(.unit, .auth))
struct DebugLoggerTests {

    @Test("DebugLogger doesn't crash on basic usage")
    func basicUsage() {
        let logger = DebugLogger()

        // Should not crash
        logger.log("Test message", level: .debug, category: .auth)
        logger.log("Test message with emoji 🔐", level: .info, category: .oauth)
        logger.log("Test error message", level: .error, category: .network)
        logger.log("Test warning", level: .warning, category: .session)
    }

    @Test("DebugLogger handles all log levels")
    func handlesAllLogLevels() {
        let logger = DebugLogger()

        // Should not crash with any log level
        logger.log("Debug", level: .debug, category: .auth)
        logger.log("Info", level: .info, category: .auth)
        logger.log("Warning", level: .warning, category: .auth)
        logger.log("Error", level: .error, category: .auth)
    }

    @Test("DebugLogger handles all categories")
    func handlesAllCategories() {
        let logger = DebugLogger()

        // Should not crash with any category
        logger.log("Test", level: .info, category: .auth)
        logger.log("Test", level: .info, category: .network)
        logger.log("Test", level: .info, category: .session)
        logger.log("Test", level: .info, category: .oauth)
        logger.log("Test", level: .info, category: .cookie)
        logger.log("Test", level: .info, category: .checkin)
    }

    @Test("DebugLogger handles long messages")
    func handlesLongMessages() {
        let logger = DebugLogger()
        let longMessage = String(repeating: "A", count: 10000)

        // Should not crash with very long message
        logger.log(longMessage, level: .info, category: .auth)
    }

    @Test("DebugLogger handles special characters")
    func handlesSpecialCharacters() {
        let logger = DebugLogger()

        // Should not crash with special characters
        logger.log("Test with\nnewline", level: .info, category: .auth)
        logger.log("Test with\ttab", level: .info, category: .auth)
        logger.log("Test with \"quotes\"", level: .info, category: .auth)
        logger.log("Test with emoji 🔐🌐✅❌", level: .info, category: .auth)
    }
}

// MARK: - LogLevel Tests

@Suite("LogLevel", .tags(.unit, .auth))
struct LogLevelTests {

    @Test("LogLevel raw values are correct")
    func rawValuesAreCorrect() {
        #expect(LogLevel.debug.rawValue == "DEBUG")
        #expect(LogLevel.info.rawValue == "INFO")
        #expect(LogLevel.warning.rawValue == "WARNING")
        #expect(LogLevel.error.rawValue == "ERROR")
    }
}

// MARK: - LogCategory Tests

@Suite("LogCategory", .tags(.unit, .auth))
struct LogCategoryTests {

    @Test("LogCategory raw values are correct")
    func rawValuesAreCorrect() {
        #expect(LogCategory.auth.rawValue == "[AUTH]")
        #expect(LogCategory.network.rawValue == "[NETWORK]")
        #expect(LogCategory.session.rawValue == "[SESSION]")
        #expect(LogCategory.oauth.rawValue == "[OAUTH]")
        #expect(LogCategory.cookie.rawValue == "[COOKIE]")
        #expect(LogCategory.checkin.rawValue == "[CHECKIN]")
    }
}
