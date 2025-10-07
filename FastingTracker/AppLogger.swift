import Foundation
import os.log

/// Centralized logging system following Apple Unified Logging guidelines
/// Reference: https://developer.apple.com/documentation/os/logging
struct AppLogger {

    // MARK: - Subsystem Configuration

    /// App bundle identifier for consistent log subsystem naming
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.fastlife.app"

    // MARK: - Logging Categories

    /// General app lifecycle and main functionality
    static let general = OSLog(subsystem: subsystem, category: "General")

    /// Weight tracking operations and calculations
    static let weightTracking = OSLog(subsystem: subsystem, category: "WeightTracking")

    /// Fasting timer operations and state management
    static let fastingTimer = OSLog(subsystem: subsystem, category: "FastingTimer")

    /// Notification scheduling and management
    static let notifications = OSLog(subsystem: subsystem, category: "Notifications")

    /// CSV import/export operations
    static let csvOperations = OSLog(subsystem: subsystem, category: "CSVOperations")

    /// HealthKit integration events
    static let healthKit = OSLog(subsystem: subsystem, category: "HealthKit")

    /// User interface and navigation events
    static let ui = OSLog(subsystem: subsystem, category: "UI")

    /// Data persistence operations
    static let persistence = OSLog(subsystem: subsystem, category: "Persistence")

    /// Force-unwrap safety fixes monitoring (CRITICAL for beta monitoring)
    static let safety = OSLog(subsystem: subsystem, category: "Safety")

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
        let logMessage = "⚠️ SAFETY: \(message) [\(fileName):\(line) in \(function)]"
        os_log("%{public}@", log: safety, type: .fault, logMessage)
    }

    /// Log successful safety handling
    static func logSafetySuccess(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let logMessage = "✅ SAFETY: \(message) [\(fileName):\(line) in \(function)]"
        os_log("%{public}@", log: safety, type: .info, logMessage)
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
        let logMessage = "⏱️ PERF: \(operation) completed in \(String(format: "%.3f", duration))s [\(fileName) in \(function)]"
        os_log("%{public}@", log: general, type: .info, logMessage)
    }

    // MARK: - Convenience Logging Methods

    /// Log general app events
    static func info(
        _ message: String,
        category: OSLog = general
    ) {
        os_log("ℹ️ %{public}@", log: category, type: .info, message)
    }

    /// Log debug information (only in debug builds)
    static func debug(
        _ message: String,
        category: OSLog = general
    ) {
        #if DEBUG
        os_log("🔍 DEBUG: %{public}@", log: category, type: .debug, message)
        #endif
    }

    /// Log error conditions
    static func error(
        _ message: String,
        category: OSLog = general,
        error: Error? = nil
    ) {
        let errorInfo = error?.localizedDescription ?? ""
        let logMessage = errorInfo.isEmpty ? "❌ ERROR: \(message)" : "❌ ERROR: \(message) - \(errorInfo)"
        os_log("%{public}@", log: category, type: .error, logMessage)
    }

    /// Log warning conditions
    static func warning(
        _ message: String,
        category: OSLog = general
    ) {
        os_log("⚠️ WARNING: %{public}@", log: category, type: .fault, message)
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
        os_log("%{public}@", log: general, type: .debug, logMessage)
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