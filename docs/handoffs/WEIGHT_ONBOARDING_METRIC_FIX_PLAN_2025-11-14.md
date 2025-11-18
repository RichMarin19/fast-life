# Weight Onboarding Metric Integrity – Recovery Plan (2025-11-14)

## Goal
Preserve the exact value the user types during onboarding (e.g., **82.1 kg**) so it appears unchanged on the Weight Tracker immediately after onboarding. The value may only change if the user later flips iOS measurement units; otherwise it must remain identical (`Single Source of Truth`).

## Guiding Principles
- **Single canonical store**: Persist pounds internally (existing HealthKit alignment) but never reconvert pounds→kilograms unless the measurement provider explicitly asks for a display conversion.
- **Measurement awareness everywhere**: Every surface (onboarding, WeightTrackingView, WeightManager) must ask `MeasurementSystemProviding` which unit to expect/render instead of assuming `.imperial`.
- **No silent conversions**: Onboarding must record the measurement system alongside the value it saves so it never “double converts” metric inputs.
- **Traceability**: Instrument the path so QA can tell which unit was captured/stored/rendered when debugging future regressions.

## Phase 1 – Evidence & Instrumentation
1. **Add scoped logging** (Debug builds only) in `FirstTimeWeightSetupView.save()` and `WeightTrackingView.onAppear`:
   - Input unit + value typed.
   - Canonical pounds value derived before persistence.
   - Measurement system returned by `MeasurementSystemProvider` when onboarding saves and when the tracker renders.
2. **Expose measurement provider in previews/tests** so we can simulate metric vs imperial without relying on the device.
3. **QA script**: Document steps Rich should follow (metric device → onboarding → tracker) and the log lines expected.

## Phase 2 – Onboarding Pipeline Fix
1. **Inject dependencies**: Provide `WeightDependencies` (or lighter `MeasurementSystemProviding` + `WeightManaging`) into onboarding instead of instantiating `.shared` managers so the measurement provider is identical between onboarding and the tracker.
2. **Unit-aware inputs**:
   - The “Current Weight” and “Goal Weight” fields display the active unit label from the provider (lbs/kg).
   - When the user taps “Next”, capture both `value` and `measurementSystem`.
3. **Single conversion to canonical pounds**:
   - If measurement system is metric, convert once via `MeasurementSystemConversion.kgToLbs`.
   - Store canonical pounds in `WeightManager`, but also store the original unit on the new entry/start-weight override for analytics/auditing.
4. **No conversion when not needed**:
   - If the measurement system is already metric, `WeightTrackingView` must request `WeightManager.displayWeight(using: measurementProvider)` which converts pounds→kg for display, guaranteeing the tracker shows 82.1 kg immediately.

## Phase 3 – Tracker Rendering Hardening
1. **WeightTrackingView** subscribes to `MeasurementSystemProvider` updates (Locale notifications + manual refresh after onboarding completes).
2. **CurrentWeightCard / StartWeight components** render `weightFormatter.string(for: measurementProvider.targetUnit)` so flipping the device units updates values in place.
3. **Add regression tests** (or at minimum SwiftUI preview harness) to cover:
   - Metric onboarding entry displays metric on tracker without restart.
   - Switching units post-onboarding updates text without altering stored pounds.

## Phase 4 – Verification & Cleanup
1. Remove temporary debug logging once QA screenshots confirm parity.
2. Update `docs/handoffs/HANDOFF.md` with the root cause, fix summary, and QA evidence paths.
3. Refresh guardrail scripts/baselines if new files were added for DI/measurement helpers.

## Deliverables
- Updated onboarding + tracker Swift files with DI-friendly measurement handling.
- QA log screenshots showing 82.1 kg typed → 82.1 kg displayed.
- HANDOFF entry linking to this plan and documenting execution results.
