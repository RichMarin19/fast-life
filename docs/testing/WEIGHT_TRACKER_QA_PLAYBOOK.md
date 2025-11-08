# Weight Tracker QA Playbook
**Last Updated:** 2025-11-07

## Purpose
Guarantee every Fast LIFe weight-tracker build meets enterprise expectations by pairing automated privacy enforcement with a repeatable on-device smoke. This checklist mirrors how industry leaders (Apple, Whoop, Levels) validate sensitive flows: privacy gate first, then deterministic manual steps on real hardware.

## Prerequisites
- Physical iPhone connected via USB (FastLIFe developer device).
- Xcode 16+ installed; `xcode-select` pointing to the active toolchain.
- Homebrew `ripgrep` installed (privacy audit depends on it).
- Device UDID (Settings → General → About → tap Serial Number twice, or `xcrun xctrace list devices`).
- Fast LIFe repo synced and dependencies resolved.

## Step 1 – Automated Privacy + Test Harness
```bash
cd /Users/richmarin/Desktop/FastingTracker
export FASTLIFE_DEVICE_UDID=00008140-001814E20A53001C
./scripts/run-tests-auto.sh
```
What happens:
1. `scripts/log_privacy_audit.sh` blocks the run if any `privacy: .public`, PHI-bearing AppLogger payloads, or Crashlytics misuse is found.
2. `scripts/run_device_privacy_tests.sh` launches `log stream` with the Fast LIFe subsystem filter while `xcodebuild test` executes Command‑U on device.
3. `test_results.log` captures the suite output plus `✅ Console log privacy check passed.` when logs stay clean.

### Expected Outcome
- `test_results.log` ends with `TEST SUCCEEDED` and the privacy check ✅ line.
- `WeightManagerThreadSafetyTests` entries appear (no skips) to prove concurrency safety.
- If any step fails, fix the root cause before continuing—industry teams never proceed on a red privacy gate.

## Step 2 – Manual Device Smoke (Post-Command‑U)
Perform immediately after the automated run while the app is fresh on device.

1. **Launch Fast LIFe → Weight Control Center**
   - Confirm Trend Snapshot is the only progress card (7/30-day merged).
   - Drag cards to reorder, hide one, then restore via Manage My Experience.

2. **Add Weight Entry**
   - Tap “Log Weight”, enter a new value, save.
   - Verify entry appears at top of history and sync toast shows if HealthKit sync enabled.

3. **Delete Weight Entry**
   - Swipe-delete the entry added above; ensure it vanishes immediately and no duplicate remains after relaunch.

4. **Goal Editor**
   - Open Goal Weight card → edit value → save.
   - Check Weight Goal toggle + chart goal line reflect the change.

5. **Trend Snapshot Interactions**
   - Tap the card to cycle metrics, confirm copy references both 7- and 30-day deltas with correct units.
   - Verify there is no Progress Recap card anywhere in the stack.

6. **Chart Gestures**
   - Tap points to update the callout, pinch to zoom, drag when zoomed, double-tap to reset.
   - Listen via VoiceOver (if feasible) to ensure selection announcements include units.

7. **Offline / Low Connectivity Check**
   - Enable Airplane Mode, ask A.I.nstein a simple question, confirm it reports needing internet gracefully.
   - Disable Airplane Mode, confirm network banners clear.

8. **Console Spot Check**
   - In Console.app, filter by subsystem `com.fastlife.FastLIFe`, verify no PHI strings (weights, units, goal values) appear during the manual smoke.

## Step 3 – Record Results
- Update `test_results.log` + attach notable Console snippets if privacy harness flags anything.
- Note manual findings in `docs/handoffs/HANDOFF.md` (new W/H/E/A entry) before closing the session.

Following this playbook keeps us aligned with industry QA rigor: automated privacy gate + deterministic manual validation on real hardware every time.


## Milestone Ring / Trend Snapshot Localization

1. **Device Locale Setup**
    - Settings → General → Language & Region → set to **English (US)**.
    - Settings → General → Language & Region → Measurement **Imperial**.
    - Repeat later for a metric locale (e.g., **French (France)**) to verify kg labels.
2. **Imperial Verification**
    - Launch Fast LIFe → Weight Trends → ensure 7‑day/30‑day cards show localized copy and `lbs` unit.
    - Verify ring tags (LOST/GAINED/FLAT) and microcopy match the localized resources.
    - Capture screenshots for LOSS/GAIN/FLAT/NO DATA states.
3. **Metric Verification**
    - Switch locale to French (France) and confirm the cards now display `kg` with localized copy.
    - Re-run loss/gain/flat/no data states and capture screenshots/logs.
4. **Accessibility Validation**
    - In each locale, enable VoiceOver and focus the 7‑day and 30‑day cards.
    - Expected spoken template: “<Tag> <Value> <Unit> in <Period>”.
    - Confirm the no-data variant (“No data trend for …”) matches the localized string.
5. **Telemetry & Logs**
    - Run `scripts/run-tests-auto.sh` to verify privacy harness while the localized strings are active.
    - Document results in HANDOFF: include locale, unit, state, and whether telemetry emitted `weight_trend_snapshot_state`.
