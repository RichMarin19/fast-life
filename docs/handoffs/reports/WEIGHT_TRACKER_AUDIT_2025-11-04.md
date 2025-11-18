# Weight Tracker Audit – 2025-11-04

## Scope
- Reviewed `WeightTrackingView`, `WeightManager`, `HealthKitManager`, persistence helpers, and weight-related UI flows.
- Cross-referenced project goals documented in `docs/PHASE_0_FOUNDATION.md`, `docs/PHASE_1_ARCHITECTURE_COMPLETE.md`, and `docs/PHASE_2_SCALE_POLISH_COMPLETE.md`.
- Objective: surface data-handling risks, diagnose slowdown sources, and decide whether to refactor before adding new UI polish (“North Star” focus).

## Key Findings & Risks

### 1. Protected Health Information stored unencrypted in `UserDefaults`
- `WeightManager` persists the full `weightEntries` array via `JSONEncoder` straight into the shared `UserDefaults` suite (`weightEntriesKey`).
- Risk: `UserDefaults` is a plist on disk without encryption or access controls. Losing a device/backups exposes weight, BMI, body-fat, and timestamps—explicit HIPAA/PHI and GDPR PII.
- Impact: Violates the compliance goals called out in Phase 2 docs (GDPR export/deletion, enterprise hardening) and contradicts the “Infrastructure before features” mandate in `SESSION-PREFERENCES.md`.
- Recommendation:
  - Move persistence to an encrypted store (e.g., `SecureEnclave`-backed keychain items or `CryptoKit`-sealed file inside an App Group container).
  - Introduce a `WeightPersistenceAdapter` (actor-isolated) so UI holds no storage logic; this refactor aligns with the planned architectural slices.
  - Add opt-in data export/delete hooks to satisfy GDPR.

### 2. HealthKit sync fan-out creates UI hitches
- `HealthKitManager.fetchWeightData` issues a new BMI and body-fat query per sample (N+1 pattern) and builds results on the main queue.
- Completion handler re-sorts and writes back to `UserDefaults` on every sync.
- With 365 days of history the app can spawn hundreds of HK queries and JSON encodes the array each time, causing stutters on launch (noted by the delayed asyncAfter hack in `WeightManager.init`).
- Recommendation:
  - Replace per-sample BMI/body-fat lookups with a single batched `HKStatisticsCollectionQuery`.
  - Perform merge/dedupe work off the main actor and write back using a background task + async/await (`Task { await persistence.save(entries) }`).
  - Cache a hash/signature of the last synced day so we only re-encode changed snapshots.

### 3. Duplicate-detection is O(n²) and misses edits
- `syncFromHealthKit` loops through `weightEntries` for each incoming entry and considers a record duplicate if within 60s/0.1 lbs. This scales poorly and still allows mutated records through.
- Recommendation: index existing entries by `HKSample` UUID (if available) or `(day, source)` dictionary, and reconcile using deterministic IDs. This change should land inside the same persistence refactor to keep storage responsibilities centralized.

### 4. Thread-safety gaps block future concurrency work
- `WeightManager` mutates `@Published` state from background closures without `@MainActor` annotations, relying on implicit main-queue callbacks. Any shift to async/await (a Phase 2 goal) would surface data races instantly.
- Recommendation: mark managers `@MainActor` (or split command/query actors) before expanding UI surface area. This is an ideal refactor starting point.

### 5. Observability blind spots
- No metrics, logging categories, or crash breadcrumbs around sync, persistence, or errors—the only diagnostics are `print` statements.
- Recommendation: introduce a lightweight telemetry protocol now (e.g., `WeightTelemetry`) so subsequent refactors can report merge timings, error rates, and storage failures. This supports the “enterprise-grade observability” milestone in `docs/SUCCESS_METRICS.md`.

## Refactor Readiness – Should we proceed now?
- **Yes.** Continuing UI/UX polish (“North Star” cards, Control Center tweaks) on top of the current weight stack will propagate compliance and performance debt.
- The documentation emphasises finishing foundational architecture before feature polish; the findings above show foundational gaps (security, async model, observability).
- Recommended order:
  1. Introduce secure persistence & coordinator actors.
  2. Batch HealthKit queries + deterministic reconciliation.
  3. Layer telemetry and automated regression tests.
  4. Return to UI polish once metrics prove the stack is stable and compliant.

## Suggested Next Steps
1. Draft `WeightPersistenceAdapter` API surface (async actor, encrypted storage) and migrate `WeightManager` read/write paths.
2. Swap HealthKit fetch logic for batched queries; write regression tests covering duplicate merges and empty-data scenarios.
3. Add instrumentation hooks and capture baseline timings before/after the refactor.
4. Only after the above succeeds: resume Control Center and Progress Story UI slicing with confidence that the underlying data layer is trustworthy.

## Testing Recommendations
- Add unit tests around the new persistence actor (save/load/upgrade scenarios).
- Introduce integration tests simulating HealthKit sync with mixed manual + HK entries to verify dedupe and batching.
- Once telemetry is in place, set a threshold alert for sync duration to catch regressions automatically.

## Reference Materials
- `docs/PHASE_0_FOUNDATION.md` – mandate to stabilise infrastructure first.
- `docs/PHASE_1_ARCHITECTURE_COMPLETE.md` – outlines modular manager/coordinator pattern we should adopt.
- `docs/PHASE_2_SCALE_POLISH_COMPLETE.md` – compliance, async/await, and test coverage targets that informed the recommendations above.
