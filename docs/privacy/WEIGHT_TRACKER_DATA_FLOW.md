# Weight Tracker Data Flow & Storage – November 7, 2025

## Overview
- **Scope:** Weight entries, goal weight, milestone count, start-weight overrides, sync preferences.
- **Storage Model:** All values persist via `SecureWeightStorage` (AES-GCM encrypted snapshot) under `Application Support/SecureStorage/weight_persistence_v1.json.enc`.
- **Keys:** 256-bit symmetric key stored in Keychain (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`), never synced to iCloud.

## On-Device Protection
- Snapshot writes now force `NSFileProtectionComplete`; the parent directory uses `NSFileProtectionCompleteUnlessOpen` for background reads.
- All IO flows through a utility queue (`com.fastlife.weight.securestorage`) to keep UI work on the main actor.
- On failure, `CrashReportManager` records sanitized context (operation + schema version) without PHI payloads.

## Data Retention & Deletion
- Snapshot contains only the latest state; we do not keep historical copies.
- Deleting a weight entry removes it from memory, writes the new snapshot, and (when HealthKit sync is on) issues the corresponding HealthKit delete.
- “Reset data”/opt-out flows delete the encrypted file and erase legacy UserDefaults keys after migration.

## Reasons for Collection
- **App Functionality:** Offline-first experience for Weight Control Center, chart math, Trend Snapshot metrics, and goal progress.
- **Analytics (aggregated):** Only aggregate deltas (e.g., 7-day change) are surfaced to analytics; raw entries never leave the device unless the user exports CSV.

## Next Steps
1. Reference this doc + the privacy manifest entry inside HANDOFF (§3.76) and ADR backlog.
2. Once telemetry instrumentation lands, update this doc with emitted metric names / retention windows.
