import Foundation
import OSLog

/// Centralized crash reporting and analytics manager
/// Following Apple best practices for production error tracking
/// Reference: https://firebase.google.com/docs/crashlytics/get-started?platform=ios
class CrashReportManager {
    static let shared = CrashReportManager()

    private let logger = AppLogger.general
    private var isInitialized = false

    // MARK: - Categories from Beta Readiness Master Plan
    // Required categories: healthkit, hydration, weight, sleep, fasting, charts, notifications

    private enum CrashCategory: String {
        case healthkit = "healthkit"
        case hydration = "hydration"
        case weight = "weight"
        case sleep = "sleep"
        case fasting = "fasting"
        case charts = "charts"
        case notifications = "notifications"
        case general = "general"
        case ui = "ui"
        case persistence = "persistence"
    }

    private init() {
        // Private initializer for singleton pattern
    }

    // MARK: - Initialization

    /// Initialize crash reporting system
    /// Call this from FastingTrackerApp.init() following Firebase setup guide
    func initialize() {
        guard !isInitialized else {
            AppLogger.warning("CrashReportManager already initialized", category: AppLogger.general)
            return
        }

        #if DEBUG
        AppLogger.info("CrashReportManager: Debug mode - crash reporting disabled", category: AppLogger.general)
        #else
        // In production, this would initialize Firebase Crashlytics
        // FirebaseApp.configure()
        // Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        AppLogger.info("CrashReportManager initialized for production", category: AppLogger.general)
        #endif

        isInitialized = true
    }

    // MARK: - Crash Reporting Methods

    /// Record a non-fatal error for HealthKit operations
    func recordHealthKitError(_ error: Error, context: [String: Any] = [:]) {
        recordError(error, category: .healthkit, context: context)
    }

    /// Record a non-fatal error for hydration tracking
    func recordHydrationError(_ error: Error, context: [String: Any] = [:]) {
        recordError(error, category: .hydration, context: context)
    }

    /// Record a non-fatal error for weight tracking
    func recordWeightError(_ error: Error, context: [String: Any] = [:]) {
        recordError(error, category: .weight, context: context)
    }

    /// Record a non-fatal error for sleep tracking
    func recordSleepError(_ error: Error, context: [String: Any] = [:]) {
        recordError(error, category: .sleep, context: context)
    }

    /// Record a non-fatal error for fasting operations
    func recordFastingError(_ error: Error, context: [String: Any] = [:]) {
        recordError(error, category: .fasting, context: context)
    }

    /// Record a non-fatal error for chart rendering
    func recordChartError(_ error: Error, context: [String: Any] = [:]) {
        recordError(error, category: .charts, context: context)
    }

    /// Record a non-fatal error for notifications
    func recordNotificationError(_ error: Error, context: [String: Any] = [:]) {
        recordError(error, category: .notifications, context: context)
    }

    /// Record a non-fatal error for UI operations
    func recordUIError(_ error: Error, context: [String: Any] = [:]) {
        recordError(error, category: .ui, context: context)
    }

    /// Record a non-fatal error for persistence operations
    func recordPersistenceError(_ error: Error, context: [String: Any] = [:]) {
        recordError(error, category: .persistence, context: context)
    }

    /// Record a general non-fatal error
    func recordGeneralError(_ error: Error, context: [String: Any] = [:]) {
        recordError(error, category: .general, context: context)
    }

    // MARK: - Private Implementation

    private func recordError(_ error: Error, category: CrashCategory, context: [String: Any]) {
        // Log locally using AppLogger
        let contextString = context.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
        let logMessage = "Non-fatal error in \(category.rawValue): \(error.localizedDescription)"
        let fullMessage = contextString.isEmpty ? logMessage : "\(logMessage) | \(contextString)"

        AppLogger.error(fullMessage, category: AppLogger.general, error: error)

        #if DEBUG
        // In debug mode, just log the error
        print("🚨 CrashReport[\(category.rawValue)]: \(error.localizedDescription)")
        if !context.isEmpty {
            print("   Context: \(contextString)")
        }
        #else
        // In production, this would record to Firebase Crashlytics
        // Crashlytics.crashlytics().record(error: error)
        // Crashlytics.crashlytics().setCustomKeys(context)
        // Crashlytics.crashlytics().log("Category: \(category.rawValue)")
        #endif
    }

    // MARK: - Custom Logging

    /// Log a custom message for debugging production issues
    /// Useful for tracking user actions that lead to crashes
    func logCustomMessage(_ message: String, category: CrashCategory = .general, level: LogLevel = .info) {
        let logMessage = "Custom[\(category.rawValue)]: \(message)"

        switch level {
        case .debug:
            AppLogger.debug(logMessage, category: AppLogger.general)
        case .info:
            AppLogger.info(logMessage, category: AppLogger.general)
        case .warning:
            AppLogger.warning(logMessage, category: AppLogger.general)
        case .error:
            AppLogger.error(logMessage, category: AppLogger.general)
        case .fault:
            AppLogger.error(logMessage, category: AppLogger.general)
        default:
            AppLogger.info(logMessage, category: AppLogger.general)
        }

        #if !DEBUG
        // In production, this would log to Firebase Crashlytics
        // Crashlytics.crashlytics().log(logMessage)
        #endif
    }

    // MARK: - User Context

    /// Set user identifier for crash reports (use anonymized ID, never personal info)
    /// Following Apple privacy guidelines - use hashed identifiers only
    func setUserIdentifier(_ identifier: String) {
        let hashedID = identifier.hash.description // Simple hash for anonymization

        AppLogger.info("Setting user context: \(hashedID)", category: AppLogger.general)

        #if !DEBUG
        // In production, this would set user context in Firebase Crashlytics
        // Crashlytics.crashlytics().setUserID(hashedID)
        #endif
    }

    /// Set custom key-value pairs for crash context
    func setCustomValue(_ value: Any, forKey key: String) {
        AppLogger.debug("Setting custom value: \(key)=\(value)", category: AppLogger.general)

        #if !DEBUG
        // In production, this would set custom keys in Firebase Crashlytics
        // Crashlytics.crashlytics().setCustomValue(value, forKey: key)
        #endif
    }
}

// MARK: - LogLevel Extension

extension CrashReportManager {
    enum LogLevel {
        case debug
        case info
        case warning
        case error
        case fault
    }
}

// MARK: - Convenience Extensions

extension CrashReportManager {

    /// Quick method to record and log an error in one call
    func handleError(_ error: Error, in component: String, category: CrashCategory = .general, context: [String: Any] = [:]) {
        var fullContext = context
        fullContext["component"] = component

        recordError(error, category: category, context: fullContext)
    }

    /// Record performance issues (slow operations)
    func recordPerformanceIssue(operation: String, duration: TimeInterval, threshold: TimeInterval = 2.0) {
        if duration > threshold {
            let context = [
                "operation": operation,
                "duration": String(format: "%.3f", duration),
                "threshold": String(format: "%.3f", threshold)
            ]

            logCustomMessage("Performance issue detected", category: .general, level: .warning)

            #if !DEBUG
            // In production, record as non-fatal error
            let error = NSError(
                domain: "Performance",
                code: 1001,
                userInfo: [
                    NSLocalizedDescriptionKey: "Operation '\(operation)' took \(String(format: "%.3f", duration))s (threshold: \(String(format: "%.3f", threshold))s)"
                ]
            )
            recordError(error, category: .general, context: context)
            #endif
        }
    }
}