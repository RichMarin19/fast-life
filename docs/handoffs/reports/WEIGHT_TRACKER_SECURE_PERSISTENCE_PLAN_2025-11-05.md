# Weight Tracker Secure Persistence Plan – 2025-11-05

## Goals
- Replace all weight-related `UserDefaults` storage with an encrypted, file-protected solution that satisfies Apple’s Sensitive Data guidelines and HIPAA-adjacent expectations.
- Maintain a single source of truth owned by `WeightManager`, eliminating divergent writes from view models or other coordinators.
- Provide a deterministic migration path for existing users so legacy plaintext data is securely rehydrated, then purged.

## Architecture Overview
1. **Key Management**
   - Generate a 256-bit AES-GCM symmetric key (CryptoKit) and store it in the iOS Keychain (`kSecClassKey`) with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
   - Reuse the key for all weight persistence operations; rotate by incrementing a key version when necessary.
   - Helper: `SecureKeyStore` wraps Keychain read/write following Apple’s Keychain Services Programming Guide.

2. **Encrypted Storage**
   - Create `SecureFileStorage` (in `FastingTracker/Core/Storage`) that:
     - Persists encrypted blobs to `Application Support/FastLIFe/SecureStorage`.
     - Applies `.complete` file protection after each write (per Apple File System Programming Guide).
     - Uses AES.GCM for encryption (`CryptoKit`), storing `sealedBox.combined` data.
   - All read/write operations execute off the main actor; public APIs hop back to main only when returning decoded models.

3. **Persistence Schema**
   - Define `WeightPersistenceSnapshot` (Codable) containing weight entries, sync flags, goal/milestone data, and start-weight overrides.
   - Store a single encrypted file (`weight_persistence_v1.json.enc`) to ensure atomic updates.

4. **Adapter Responsibilities**
   - `WeightPersistenceAdapter` loads/saves the snapshot exclusively through `SecureFileStorage`.
   - Provide migration helpers (`legacyDefaultsLoader`) that read existing `ThreadSafeUserDefaults` keys on first launch, populate the snapshot, write encrypted payload, then remove legacy keys.
   - All setter APIs update the in-memory snapshot and immediately persist the encrypted file.

## Migration Strategy
1. On adapter init:
   - Attempt to read encrypted snapshot; if present and decodable, hydrate state.
   - If missing, read legacy keys:
     - `weightEntries` JSON (`[WeightEntry]`), `syncWithHealthKit`, `weightStartOverride`/`weightStartDate`, `weightMilestoneCount`, `goalWeight`.
   - Build snapshot, persist via encrypted storage, and call `legacyDefaultsCleaner` to remove the plaintext keys.
   - Record migration success/failure via `CrashReportManager` (redacted context only).
2. Failures:
   - If encrypted write fails: surface error via `CrashReportManager`, keep legacy data untouched, and return empty snapshot (app continues with clean slate).
   - If legacy decode fails: log redacted error, skip migration for that key, but continue writing whatever succeeded.

## Dependency Updates
- `WeightManager` continues to inject `WeightPersistenceManaging`. Implementation updates internally—external API is unchanged.
- Remove direct `UserDefaults` writes from `WeightTrackingViewModel.saveGoalSettings`; route goal updates through `WeightManager.setGoalWeight`. (Follow-up: audit Control Center opt-out helpers once secure storage stabilises.)
- Introduce new async-safe wrappers where needed to keep @MainActor invariants.

## Testing Plan
1. **Unit Tests**
   - `WeightPersistenceAdapterTests`:
     - Migration from seeded legacy defaults.
     - Save/load round-trips for entries, goal weight, milestone count.
     - Corruption handling (write bad data, ensure adapter resets gracefully).
   - `SecureFileStorageTests`: encryption/decryption round-trip using a temporary directory and deterministic key.
2. **Integration Tests**
   - Instantiate `WeightManager` with fake `SecureFileStorage` to validate CRUD operations with encrypted persistence.
   - Ensure goal weight changes triggered via `WeightTrackingViewModel` propagate to the adapter only through `WeightManager`.
3. **Manual Validation**
   - Device build with preloaded legacy defaults -> launch -> confirm data intact.
   - Inspect Console logs to verify no plaintext weights appear.
   - Toggle HealthKit sync, goal edits, milestones, and confirm persistence across relaunches.

## Rollout & Documentation
- Update `HANDOFF.md` after implementation/testing with W/H/E/A summary.
- Document the secure storage design and migration checklist in `SESSION-PREFERENCES.md` and testing runbooks.
- Provide rollback instructions (restore from encrypted backup file) in case of production issues.

## Open Questions
- Future phases may migrate HealthKit anchors and notification settings; capture follow-up tasks once weight data migration is stable.
- Evaluate adding key rotation tooling in Phase 3 if compliance requirements demand periodic re-encryption.
