# Phase 3 Slice 3C – Stats & Chart Polish (2025-11-04)

## Scope
- Align the weight statistics card bundle with design-system typography, spacing, and locale-aware formatting.
- Modernize the weight chart header and axes to rely on tokens and shared formatting helpers.
- Add regression coverage around the new formatting utilities to guard against future localization regressions.

## Implementation Summary
- `WeightStatsComponents.swift` now reuses `WeightManager.formattedDisplayWeight` for average and delta values, removes redundant number formatter state, and converts accessibility copy to localized units.
- `WeightChartView.swift` adopts DS typography/colors, annotates the goal line with localized weight text, and routes axis labels through `WeightChartViewModel.axisLabel(for:)` so unit abbreviations follow `AppSettings.weightUnit`.
- `WeightChartViewModel` exposes localized helper methods (`formattedWeight`, `formattedWeightValue`, `axisLabel`, `goalLineAccessibilityLabel`) consumed by the view and new tests.
- Added `WeightChartViewModelTests` cases validating axis label/unit coupling across imperial/metric locales and ensuring entry formatting delegates to `WeightManager`.
- Nov 5 update: chart annotations/Y-axis labels now reuse the helper for unit abbreviations and the view leans on `Theme.ColorToken.primary` instead of legacy asset catalog colors to stay aligned with the design system.

## Validation
- ✅ Command‑B in Xcode (local) — succeeded after refactor.
- 🔄 Command‑U on physical device — please rerun to confirm chart annotations and VoiceOver labels (sandbox cannot execute device tests).
- 📋 New unit tests: `testAxisLabel_AppendsLocalizedUnitForImperial/Metric`, `testFormattedWeightForEntry_UsesWeightFormatter`.

## Follow-ups & Recommendations
1. Perform on-device smoke with device locale toggled to a metric region (e.g., UK) to verify the new axis labels and stat cards render expected units.
2. Run VoiceOver and Dynamic Type checks on the chart detail drawer to confirm the new typography tokens remain accessible.
3. Slice 3C still calls for chart zoom research and stats surface refinements; queue multi-touch zoom evaluation after refactor wraps.
4. Once notifications slice (3D) completes, revisit chart formatting helpers for possible extraction into a shared metric formatter to avoid subtle drift across components.

## Zoom Interaction Plan (Research Notes – Nov 4, 2025)

- **References:** Apple Human Interface Guidelines – Gestures & Data Visualization (Oct 2025), WWDC23 “Design dynamic charts”, Apple Health/Activity app interactions, Whoop & Oura weight/HR charts.
- **Gestures to Support:**
  1. Pinch-to-zoom (in/out) with rubber-banded min/max bounds tied to the current time range.
  2. Two-finger double-tap to reset zoom to the default window.
  3. Horizontal drag (pan) only when zoomed in; snaps back when reaching range limits.
- **Accessibility Equivalents:**
  - Add VoiceOver custom rotor actions (“Zoom In”, “Zoom Out”, “Reset Zoom”) that call the same domain-scaling logic.
  - Announce the current date range after each adjustment using the new `chartAccessibilitySummary`.
- **Implementation Notes:**
  - Store zoom state in `WeightChartView` using `@State`, while `WeightChartViewModel` provides clamping helpers.
  - Clamp zoom domain to no less than 3 data points and no more than the original time range.
  - Analytics: emit events when users zoom/reset to inform design tuning.
  - Testing plan: gesture smoke on device (pinch, double-tap), VoiceOver rotor verification, ensure Command‑U still passes with new state transitions.

## Zoom Interaction Implementation (Nov 4, 2025)

- Introduced stateless `zoomedDomain`/`pannedDomain` helpers in `WeightChartViewModel` with accompanying tests covering clamp logic.
- Bound `WeightChartView` to a `visibleDomain`-driven `.chartXScale(domain:)`, moved magnification/drag gestures into `chartOverlay`, and mirrored the controls via VoiceOver accessibility actions.
- Chart axis/selection code moved into a reusable `chartContent` helper so the presentation stays identical while gestures operate on the rendered view.
- On-device validation: run Command‑U, pinch/pan on a real device, double-tap reset, and exercise VoiceOver rotor actions (“Zoom In/Out”, “Reset Zoom”).

## Test Plan for Rich
1. Build the project (Command‑B).
2. Run full suite on device (Command‑U); capture any failures tied to `WeightChartViewModelTests`.
3. Open Control Center → Weight Tracker:
   - Verify 7/30-day change cards show localized units.
   - Confirm chart axis labels and goal annotation adopt current unit.
   - Tap a data point and ensure the detail callout shows localized weight and retains capsule styling.
