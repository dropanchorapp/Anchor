//
//  Logger.swift
//  AnchorKit
//
//  Structured logging abstraction for production-safe debug output
//

import Foundation

// MARK: - Log Category

/// Categories for organizing log messages
public enum LogCategory: String, Sendable {
    case auth = "[AUTH]"
    case network = "[NETWORK]"
    case session = "[SESSION]"
    case oauth = "[OAUTH]"
    case cookie = "[COOKIE]"
    case checkin = "[CHECKIN]"
}

// MARK: - Log Level

/// Log severity levels
public enum LogLevel: String, Sendable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
}

// MARK: - Logger Protocol

/// Protocol for structured logging across AnchorKit
public protocol Logger: Sendable {
    /// Log a message with category and level
    /// - Parameters:
    ///   - message: The log message
    ///   - level: Severity level
    ///   - category: Organizational category
    func log(_ message: String, level: LogLevel, category: LogCategory)
}

// MARK: - Debug Logger

/// Production-safe logger using debugPrint()
///
/// Uses debugPrint() which is automatically stripped by the Swift compiler
/// in release builds, ensuring zero logging overhead in production.
public final class DebugLogger: Logger {

    public init() {}

    public func log(_ message: String, level: LogLevel, category: LogCategory) {
        debugPrint("\(category.rawValue) \(level.rawValue): \(message)")
    }
}

// MARK: - Mock Logger

/// Mock logger for testing that captures log messages
public final class MockLogger: Logger, @unchecked Sendable {

    public struct LogEntry: Sendable {
        public let message: String
        public let level: LogLevel
        public let category: LogCategory
        public let timestamp: Date
    }

    private let lock = NSLock()
    private var _entries: [LogEntry] = []

    public init() {}

    public func log(_ message: String, level: LogLevel, category: LogCategory) {
        lock.lock()
        defer { lock.unlock() }
        _entries.append(LogEntry(
            message: message,
            level: level,
            category: category,
            timestamp: Date()
        ))
    }

    /// Get all captured log entries (thread-safe)
    public var entries: [LogEntry] {
        lock.lock()
        defer { lock.unlock() }
        return _entries
    }

    /// Clear all captured log entries (thread-safe)
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        _entries.removeAll()
    }

    /// Get entries for specific category
    public func entries(for category: LogCategory) -> [LogEntry] {
        lock.lock()
        defer { lock.unlock() }
        return _entries.filter { $0.category == category }
    }

    /// Get entries for specific level
    public func entries(for level: LogLevel) -> [LogEntry] {
        lock.lock()
        defer { lock.unlock() }
        return _entries.filter { $0.level == level }
    }
}
