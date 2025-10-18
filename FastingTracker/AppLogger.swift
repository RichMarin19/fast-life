import Foundation
import os.log

/// Centralized logging system following Apple Unified Logging guidelines
/// Reference: https://developer.apple.com/documentation/os/logging
/// Updated to modern Logger API (iOS 14+) for enhanced performance and privacy
struct AppLogger {

    // MARK: - Subsystem Configuration

    /// App bundle identifier for consistent log subsystem naming
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.fastlife.app"

    // MARK: - Logging Categories (Modern Logger API - iOS 14+)

    /// General app lifecycle and main functionality
    static let general = Logger(subsystem: subsystem, category: "general")

    /// Weight tracking operations and calculations
    static let weightTracking = Logger(subsystem: subsystem, category: "weight")

    /// Fasting timer operations and state management
    static let fastingTimer = Logger(subsystem: subsystem, category: "fasting-timer")

    /// Notification scheduling and management
    static let notifications = Logger(subsystem: subsystem, category: "notifications")

    /// CSV import/export operations
    static let csvOperations = Logger(subsystem: subsystem, category: "csv-operations")

    /// HealthKit integration events
    static let healthKit = Logger(subsystem: subsystem, category: "healthkit")

    /// Sleep tracking operations
    static let sleep = Logger(subsystem: subsystem, category: "sleep")

    /// Hydration tracking operations
    static let hydration = Logger(subsystem: subsystem, category: "hydration")

    /// User interface and navigation events
    static let ui = Logger(subsystem: subsystem, category: "ui")

    /// Data persistence operations
    static let persistence = Logger(subsystem: subsystem, category: "persistence")

    /// Force-unwrap safety fixes monitoring (CRITICAL for beta monitoring)
    static let safety = Logger(subsystem: subsystem, category: "safety")

    /// Mood tracking operations and validation
    static let mood = Logger(subsystem: subsystem, category: "mood")

    /// Fasting state transitions and validation
    static let fasting = Logger(subsystem: subsystem, category: "fasting")

    // MARK: - Safety Logging Methods

    /// Log safety warnings for force-unwrap fixes
    /// These logs are CRITICAL for monitoring our crash prevention fixes in production
    static func logSafetyWarning(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        safety.fault("⚠️ SAFETY: \(message, privacy: .public) [\(fileName, privacy: .public):\(line, privacy: .public) in \(function, privacy: .public)]")
    }

    /// Log successful safety handling
    static func logSafetySuccess(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        safety.info("✅ SAFETY: \(message, privacy: .public) [\(fileName, privacy: .public):\(line, privacy: .public) in \(function, privacy: .public)]")
    }

    // MARK: - Performance Logging

    /// Log performance metrics for optimization
    static func logPerformance(
        _ operation: String,
        duration: TimeInterval,
        file: String = #file,
        function: String = #function
    ) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        general.info("⏱️ PERF: \(operation, privacy: .public) completed in \(String(format: "%.3f", duration), privacy: .public)s [\(fileName, privacy: .public) in \(function, privacy: .public)]")
    }

    // MARK: - Convenience Logging Methods (Modern Logger API)

    /// Log general app events
    static func info(
        _ message: String,
        category: Logger = general
    ) {
        category.info("ℹ️ \(message, privacy: .public)")
    }

    /// Log debug information (only in debug builds)
    static func debug(
        _ message: String,
        category: Logger = general
    ) {
        #if DEBUG
        category.debug("🔍 DEBUG: \(message, privacy: .public)")
        #endif
    }

    /// Log error conditions
    static func error(
        _ message: String,
        category: Logger = general,
        error: Error? = nil
    ) {
        let errorInfo = error?.localizedDescription ?? ""
        let logMessage = errorInfo.isEmpty ? "❌ ERROR: \(message)" : "❌ ERROR: \(message) - \(errorInfo)"
        category.error("\(logMessage, privacy: .public)")
    }

    /// Log warning conditions
    static func warning(
        _ message: String,
        category: Logger = general
    ) {
        category.fault("⚠️ WARNING: \(message, privacy: .public)")
    }

    // MARK: - Legacy Print Replacement (Transition Helper)

    /// Drop-in replacement for print() statements during migration
    /// Automatically uses debug level and includes file context
    static func debugPrint(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        #if DEBUG
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let logMessage = "🖨️ PRINT: \(message) [\(fileName):\(line) in \(function)]"
        general.debug("\(logMessage, privacy: .public)")
        #endif
    }
}

// MARK: - Production Logging Best Practices

extension AppLogger {

    /// Guidelines for production logging:
    /// 1. Use appropriate log levels (info, debug, error, fault)
    /// 2. Include context (file, function, line) for debugging
    /// 3. Avoid logging sensitive user data
    /// 4. Use structured categories for filtering
    /// 5. Performance-conscious - OSLog is optimized for production
    ///
    /// Reference: https://developer.apple.com/videos/play/wwdc2020/10168/

}