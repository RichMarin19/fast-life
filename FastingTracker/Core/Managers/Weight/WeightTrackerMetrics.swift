import Foundation
import os

/// Centralized observability hooks for Weight Tracker flows.
/// Emits signposted metrics and sanitized breadcrumbs while avoiding PHI payloads.
struct WeightTrackerMetrics {

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.fastlife.FastLIFe"
    private static let signpostLog = OSLog(subsystem: subsystem, category: "weight-metrics")

    static func recordAddEntry(duration: TimeInterval, source: WeightSource) {
        let metadata = ["source": source.rawValue]
        logMetric("weight_add_entry", duration: duration, metadata: metadata)
    }

    static func recordDeleteEntry(duration: TimeInterval, source: WeightSource) {
        let metadata = ["source": source.rawValue]
        logMetric("weight_delete_entry", duration: duration, metadata: metadata)
    }

    static func recordSync(result: SyncResult) {
        let metadata: [String: String] = [
            "type": result.type,
            "success": result.success ? "true" : "false"
        ]
        logMetric("weight_sync", duration: result.duration, metadata: metadata)
    }

    static func measure<T>(name: StaticString, block: () throws -> T) rethrows -> T {
        let start = Date()
        let signpostID = OSSignpostID(log: signpostLog)
        os_signpost(.begin, log: signpostLog, name: name, signpostID: signpostID)
        defer {
            os_signpost(.end, log: signpostLog, name: name, signpostID: signpostID)
        }
        do {
            let value = try block()
            logMetric(name, duration: Date().timeIntervalSince(start))
            return value
        } catch {
            logMetric(name, duration: Date().timeIntervalSince(start), metadata: ["success": "false"])
            throw error
        }
    }

    struct SyncResult {
        let type: String
        let duration: TimeInterval
        let success: Bool
    }

    enum GoalEvent: String {
        case startWeightInputEmpty = "goal_start_weight_input_empty"
        case startWeightInputInvalid = "goal_start_weight_input_invalid"
        case startWeightTrailingSeparator = "goal_start_weight_trailing_separator"
        case startWeightAutofill = "goal_start_weight_autofill"
        case startWeightSaved = "goal_start_weight_saved"
        case startWeightRejected = "goal_start_weight_rejected"
        case goalWeightInputTruncated = "goal_weight_input_truncated"
        case goalWeightSaved = "goal_weight_saved"
        case goalWeightDiscarded = "goal_weight_discarded"
        case milestoneUpdated = "goal_milestone_updated"
    }

    static func recordGoalEvent(_ event: GoalEvent, metadata: [String: String] = [:]) {
        var payload = metadata
        payload["event"] = event.rawValue
        logMetric("weight_goal_event", duration: nil, metadata: payload)
    }

    enum ProgressStoryEvent: String {
        case cardHidden = "progress_card_hidden"
        case cardReordered = "progress_card_reordered"
        case stackOptedOut = "progress_stack_opted_out"
    }

    static func recordProgressStoryEvent(_ event: ProgressStoryEvent, metadata: [String: String] = [:]) {
        var payload = metadata
        payload["event"] = event.rawValue
        logMetric("weight_progress_story_event", duration: nil, metadata: payload)
    }

    static func recordTrendSnapshotState(hasSevenDayData: Bool, hasThirtyDayData: Bool, trendState: String) {
        let metadata = [
            "has7day": hasSevenDayData.stringValue,
            "has30day": hasThirtyDayData.stringValue,
            "trend_state": trendState
        ]
        logMetric("weight_trend_snapshot_state", duration: nil, metadata: metadata)
    }
}

// MARK: - Helpers

private extension WeightTrackerMetrics {
    static func logMetric(_ name: StaticString, duration: TimeInterval?, metadata: [String: String] = [:]) {
        var payload = metadata
        if let duration {
            payload["duration_ms"] = duration.msString()
        }
        AppLogger.debug(
            "METRIC \(name) metadata=\(payload)",
            category: AppLogger.weightTracking,
            privacy: .public
        )
        os_signpost(.event, log: signpostLog, name: name, "%{public}s", metadataSummary(payload))
        CrashReportManager.shared.recordMetricEvent(String(describing: name), metadata: payload)
    }

    static func metadataSummary(_ metadata: [String: String]) -> String {
        metadata
            .map { "\($0.key)=\($0.value)" }
            .sorted()
            .joined(separator: ", ")
    }
}

private extension TimeInterval {
    func msString() -> String {
        String(format: "%.1f", self * 1000)
    }
}

private extension Bool {
    var stringValue: String { self ? "true" : "false" }
}
