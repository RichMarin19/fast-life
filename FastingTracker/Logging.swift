import Foundation
import OSLog

// MARK: - Log Levels

/// Log severity levels matching OSLog's LogType
enum LogLevel: Int, Comparable {
    case debug = 0      // Verbose, development-only
    case info = 1       // General informational messages
    case notice = 2     // Default level, notable events
    case warning = 3    // Potential issues
    case error = 4      // Errors that don't crash
    case fault = 5      // Critical failures

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .notice: return .default
        case .warning: return .error
        case .error: return .error
        case .fault: return .fault
        }
    }
}

// MARK: - Log Categories

/// Organized categories for filtering logs
enum LogCategory: String {
    case healthkit = "HealthKit"
    case hydration = "Hydration"
    case weight = "Weight"
    case sleep = "Sleep"
    case fasting = "Fasting"
    case charts = "Charts"
    case notifications = "Notifications"
    case onboarding = "Onboarding"
    case settings = "Settings"
    case storage = "Storage"
    case performance = "Performance"
    case general = "General"
}

// MARK: - App Log Infrastructure

/// Central logging infrastructure
struct AppLog {
    static let subsystem = "ai.fastlife.app"

    /// Creates a logger for a specific category
    static func logger(for category: LogCategory) -> Logger {
        return Logger(subsystem: subsystem, category: category.rawValue)
    }
}

// MARK: - Log Facade

/// Main logging facade - replaces all print() statements
class Log {

    // MARK: - Runtime Control

    /// Current runtime log level (can be overridden by debug screen)
    private static var runtimeLevel: LogLevel = {
        #if DEBUG
        return .debug  // Show everything in development
        #elseif TESTFLIGHT
        return .info   // Show info+ in TestFlight
        #else
        return .notice // Show notice+ in production
        #endif
    }()

    /// Override runtime level (used by hidden debug screen)
    static func setRuntimeLevel(_ level: LogLevel) {
        runtimeLevel = level
        UserDefaults.standard.set(level.rawValue, forKey: "LogRuntimeLevel")
        Log.notice("Runtime log level changed", category: .general, metadata: ["level": "\(level)"])
    }

    /// Get current runtime level
    static func getRuntimeLevel() -> LogLevel {
        if let savedLevel = UserDefaults.standard.value(forKey: "LogRuntimeLevel") as? Int,
           let level = LogLevel(rawValue: savedLevel) {
            return level
        }
        return runtimeLevel
    }

    // MARK: - Logging Methods

    /// Debug-level log (verbose, development only)
    static func debug(_ message: String, category: LogCategory = .general, metadata: [String: String] = [:]) {
        log(message, level: .debug, category: category, metadata: metadata)
    }

    /// Info-level log (general informational)
    static func info(_ message: String, category: LogCategory = .general, metadata: [String: String] = [:]) {
        log(message, level: .info, category: category, metadata: metadata)
    }

    /// Notice-level log (notable events, default level)
    static func notice(_ message: String, category: LogCategory = .general, metadata: [String: String] = [:]) {
        log(message, level: .notice, category: category, metadata: metadata)
    }

    /// Warning-level log (potential issues)
    static func warning(_ message: String, category: LogCategory = .general, metadata: [String: String] = [:]) {
        log(message, level: .warning, category: category, metadata: metadata)
    }

    /// Error-level log (errors that don't crash)
    static func error(_ message: String, category: LogCategory = .general, metadata: [String: String] = [:], error: Error? = nil) {
        var finalMetadata = metadata
        if let error = error {
            finalMetadata["error"] = error.localizedDescription
        }
        log(message, level: .error, category: category, metadata: finalMetadata)
    }

    /// Fault-level log (critical failures)
    static func fault(_ message: String, category: LogCategory = .general, metadata: [String: String] = [:], error: Error? = nil) {
        var finalMetadata = metadata
        if let error = error {
            finalMetadata["error"] = error.localizedDescription
        }
        log(message, level: .fault, category: category, metadata: finalMetadata)
    }

    // MARK: - Core Log Function

    private static func log(_ message: String, level: LogLevel, category: LogCategory, metadata: [String: String]) {
        // Check runtime level
        guard level >= getRuntimeLevel() else { return }

        let logger = AppLog.logger(for: category)

        // Format metadata if present
        let metadataString = metadata.isEmpty ? "" : " | " + metadata.map { "\($0)=\($1)" }.joined(separator: ", ")
        let fullMessage = message + metadataString

        // Log with appropriate OSLog level
        switch level {
        case .debug:
            logger.debug("\(fullMessage, privacy: .public)")
        case .info:
            logger.info("\(fullMessage, privacy: .public)")
        case .notice:
            logger.notice("\(fullMessage, privacy: .public)")
        case .warning:
            logger.warning("\(fullMessage, privacy: .public)")
        case .error:
            logger.error("\(fullMessage, privacy: .public)")
        case .fault:
            logger.fault("\(fullMessage, privacy: .public)")
        }
    }

    // MARK: - Privacy-Safe Helpers

    /// Log a count/quantity without revealing actual health data
    static func logCount(_ count: Int, action: String, category: LogCategory) {
        info("\(action): \(count) items", category: category)
    }

    /// Log a successful operation without revealing data
    static func logSuccess(_ operation: String, category: LogCategory) {
        info("✅ \(operation) completed successfully", category: category)
    }

    /// Log a failed operation with error details
    static func logFailure(_ operation: String, category: LogCategory, error: Error? = nil) {
        Log.error("❌ \(operation) failed", category: category, error: error)
    }

    /// Log an authorization request (never log the result, only the request)
    static func logAuthRequest(_ dataType: String, category: LogCategory = .healthkit) {
        info("📱 Requesting authorization for \(dataType)", category: category)
    }

    /// Log an authorization result (boolean only, no sensitive data)
    static func logAuthResult(_ dataType: String, granted: Bool, category: LogCategory = .healthkit) {
        if granted {
            info("✅ Authorization granted for \(dataType)", category: category)
        } else {
            warning("❌ Authorization denied for \(dataType)", category: category)
        }
    }
}

// MARK: - Performance Signposts

/// Performance tracking using os.signpost for Instruments
class PerformanceLog {
    private static let log = OSLog(subsystem: AppLog.subsystem, category: "Performance")

    /// Begin a performance interval
    static func begin(_ name: StaticString, id: OSSignpostID = .exclusive) {
        os_signpost(.begin, log: log, name: name, signpostID: id)
    }

    /// End a performance interval
    static func end(_ name: StaticString, id: OSSignpostID = .exclusive) {
        os_signpost(.end, log: log, name: name, signpostID: id)
    }

    /// Log an event within an interval
    static func event(_ name: StaticString, id: OSSignpostID = .exclusive, message: String = "") {
        os_signpost(.event, log: log, name: name, signpostID: id, "%{public}s", message)
    }

    // MARK: - Convenience Methods

    /// Measure chart rendering performance
    static func beginChartRender() {
        begin("Chart Render")
    }

    static func endChartRender() {
        end("Chart Render")
    }

    /// Measure HealthKit sync performance
    static func beginHealthKitSync() {
        begin("HealthKit Sync")
    }

    static func endHealthKitSync() {
        end("HealthKit Sync")
    }

    /// Measure database query performance
    static func beginDatabaseQuery() {
        begin("Database Query")
    }

    static func endDatabaseQuery() {
        end("Database Query")
    }
}

// MARK: - Migration Helpers

/// Temporary helpers to ease migration from print() statements
extension Log {
    /// Replace print() with this during migration
    @available(*, deprecated, message: "Use Log.debug/info/notice instead")
    static func print(_ message: String, category: LogCategory = .general) {
        debug(message, category: category)
    }
}
