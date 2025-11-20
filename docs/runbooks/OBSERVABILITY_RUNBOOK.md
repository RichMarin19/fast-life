# Observability Runbook – Privacy-Safe Logging & Crashlytics

**Purpose:** Provide a step-by-step reference for inspecting Fast LIFe runtime telemetry without exposing PHI. All logging and Crashlytics usage must follow the privacy guardrails introduced in Phase 2.

## 1. Crashlytics Usage

### 1.1 Sanitised Telemetry
- All app code must route Crashlytics calls through `CrashReportManager`.
- `CrashTelemetrySanitizer` redacts weight/goal/BMI strings and flattens nested context; expect `[REDACTED]` markers for sensitive values.
- Custom keys include:
  - `context_keys` – pipe-delimited list of keys attached to the error.
  - `containsSensitiveTelemetry` – `true` if any input value was redacted.
  - Other keys mirror sanitized summaries (e.g., `operation`, `duration`).
- Direct calls to `Crashlytics.crashlytics()` outside `CrashReportManager` are blocked by `AppLoggerPrivacyTests`.

### 1.2 Recording Errors
```swift
CrashReportManager.shared.recordWeightError(error, context: [
    "operation": "syncNewEntries",
    "addedCount": summary.added
])
```
- Context values may be strings, numbers, dictionaries, or arrays—sanitizer converts them to safe strings.
- Avoid including raw PHI (weights, timestamps). Use aggregate counts or boolean flags instead.

### 1.3 Inspecting Crashlytics Issues
1. Open Firebase Console → Crashlytics.
2. Filter by `app` bundle `com.fastlife.app`.
3. In each issue, expand **Keys** to see sanitized entries (`context_keys`, `containsSensitiveTelemetry`).
4. Cross-check with the `[REDACTED]` markers to confirm no PHI leaked.

### 1.4 Crashlytics Metric Dashboard (METRIC Logs)
Crashlytics does not expose custom dashboards for non-fatal logs, so we emulate one using the **Logs** tab and saved filters. This lets QA/leadership review the PHI-safe `METRIC[...]` events emitted by `WeightTrackerMetrics`.

#### A. Create the Saved Filter (one time)
1. Firebase Console → Crashlytics → **Logs** tab.
2. Use the search box and enter: `log:"METRIC"`.
3. Add filters:
   - **App version** → select the current build under test.
   - **Custom key** → `context_keys` contains `weight_goal_event|weight_trend_snapshot_state` (add more keys as needed).
4. Click **Save Filter** → name it `Weight Metrics – METRIC Logs`.

#### B. Reviewing Metrics Each QA Cycle
1. Open the saved filter (`Weight Metrics – METRIC Logs`).
2. Use the time selector to match the QA window (e.g., “Last 24 hours”).
3. Export the results (Download CSV) and attach to QA notes if stakeholders need archival evidence.
4. For quick health checks, scan the `log` column: each entry follows `METRIC[event] key=value …` and should never display raw weights, PHI, or unit strings beyond sanitized abbreviations (`lbs`,`kg`).
5. If a log looks suspect, click through to the associated issue/session for deeper context, then reference `CrashTelemetrySanitizer` to verify the sanitization path.

> **Tip:** add additional saved filters for specific metadata (e.g., `log:"METRIC weight_goal_event"` with `custom key: event=goal_weight_saved`) to track adoption of each Control Center action.

## 2. Console Privacy Harness
- Primary script: `scripts/run-tests-auto.sh` (auto device detection) or `scripts/run_device_privacy_tests.sh <UDID>`.
- Logs are streamed from `subsystem == "com.fastlife.FastLIFe"` and scanned for tokens (`lbs`, `kg`, `goal weight`, `weight change`, `current weight`).
- Failures print offending log lines and exit non-zero—treat as P0 until remediated.

## 3. Manual Log Review Checklist
1. Reproduce the scenario on a physical device.
2. Run `scripts/console_privacy_check.sh <UDID> <custom-command>` if you need a targeted flow.
3. Review the generated log file in the script’s temp directory for `PRIVATE` placeholders and absence of PHI.

## 4. Escalation & Reporting
- Record privacy regressions in HANDOFF.md with What/How/Expected/Actual and link to the offending log snippet.
- Coordinate fixes within ISSUE-P2-4 (console) or ISSUE-P2-3 (Crashlytics) depending on the surface.

## References
- `FastingTracker/Core/Managers/CrashReportManager.swift`
- `FastingTrackerTests/Infrastructure/AppLoggerPrivacyTests.swift`
- `docs/runbooks/CONSOLE_PRIVACY_RUNBOOK.md`

## 5. Structured Metrics & Signposts

- `FastingTracker/Core/Managers/Weight/WeightTrackerMetrics.swift` emits sanitized telemetry for every add/delete/sync flow. Each helper:
  - Logs an `AppLogger` debug line (`METRIC weight_add_entry ...`) with aggregate metadata only.
  - Emits an `os_signpost(.event)` on subsystem `com.fastlife.FastLIFe`, category `weight-metrics`. These signposts contain only non-PHI values (source, success flags, durations in ms).
  - Calls `CrashReportManager.recordMetricEvent` so the same sanitized summary is mirrored into Crashlytics logs (look for `METRIC[...]` entries under the device/session). This provides remote visibility without waiting for a crash report.
- Event catalogue:

| Event | Metadata | Description |
| --- | --- | --- |
| `weight_add_entry` | `source`, `duration_ms` | Fired when a manual or HealthKit entry is persisted. |
| `weight_delete_entry` | `source`, `duration_ms` | Fired whenever an entry is removed. |
| `weight_sync` | `type` (`incremental`, `historical`, `manual_reset`), `success`, `duration_ms` | Fired at the end of every sync pass. |
| `goal_start_*` | varies (`reason`, `source`, `source_count`) | Covers start-weight input validation, autofill, and save/reject events. |
| `goal_weight_*` | `source`, `reason` | Tracks Control Center goal weight saves/discards and formatter truncation. |
| `goal_milestone_updated` | `count` | Fired when milestone count changes via Control Center. |
| `weight_trend_snapshot_state` | `has7day`, `has30day`, `trend_state` | Logs whether Trend Snapshot has data for each period + state tag. |

### 5.1 Metric QA Procedure
1. Run **Weight Tracker Smoke** on device (Command‑U + manual flows: add weight, delete weight, edit goal, toggle milestones, run Trend Snapshot).
2. In Firebase Crashlytics, open the saved `Weight Metrics – METRIC Logs` filter (Section 1.4) and confirm the events appear with the expected metadata.
3. Cross-check Console.app signposts (`subsystem: com.fastlife.FastLIFe`, `category: weight-metrics`) to ensure the event counts match between local signposts and Crashlytics logs.
4. Attach the CSV export and screenshots to the QA report, noting any missing events or anomalies.

- To inspect:
  1. **Console.app** → select the device → filter by `subsystem:"com.fastlife.FastLIFe" category:"weight-metrics"`. Copy/paste the PHI-safe events directly into QA notes.
  2. **Instruments** → Points of Interest template → target the device build → run a weight scenario → search for `weight_*` events to view timelines and average durations (Apple’s recommended method for os_signpost analysis).
  3. Each event is mirrored in `AppLogger` (debug level) so log archives also include the metrics, but signposts are the preferred path for duration analysis.

- When adding new weight flows, prefer calling `WeightTrackerMetrics` helpers (or extend the struct) so all observability remains centralized and consistent with Apple’s Unified Logging + signpost guidance.
