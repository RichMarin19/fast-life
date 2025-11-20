# Weight Tracker Audit – Follow-Up (November 3, 2025)

## Summary
An external review flagged a new regression in the locale-aware start-weight flow and recommended additional guardrails before resuming major refactors. Overall GA score dipped to **8.0/10** (from 8.2) until we patch comma-locale persistence.

## Critical Regression
- `saveStartWeight()` still uses `Double(startWeightString)`, so comma decimals (e.g. “82,5”) fail validation. This breaks the single-source-of-truth promise for international users. **Action:** reuse the locale-aware NumberFormatter in the save path.

## Good
- Locale-aware typing holds mid-edit; tests cover comma decimals (`WeightControlCenterViewModelTests`).
- Goal-completion math clamps at 100%, keeping celebration UI visible (`WeightManager.progressPercentage`).
- Heavy logging moved behind `#if DEBUG`, keeping production telemetry clean.

## Bad
- Locale parsing isn’t plumbed through the save path (see regression above).
- Start-weight formatting instantiates a new NumberFormatter on every keystroke; consider caching per view model per Apple guidance.

## Ugly
- Missing regression test that exercises `saveStartWeight()` with comma decimals. Add one to keep the bug from resurfacing.

## Recommended Next Steps
1. Apply the locale-aware formatter in `saveStartWeight()`.
2. Add a regression test for saving comma-based start weight.
3. Consider caching the NumberFormatter for performance.
4. Rerun device QA before slicing large files.
