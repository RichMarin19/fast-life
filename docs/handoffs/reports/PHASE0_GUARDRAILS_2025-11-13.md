# Phase 0 Guardrails – November 13, 2025

> **Goal:** Prevent regressions while we rebuild the lost Nov 11–13 work, and ensure future edits follow Apple/Firebase enterprise guidance.

## 1. Singleton & UserDefaults Lint

- Script: `scripts/guardrails/check_singletons.sh`
- Baselines: `scripts/guardrails/baseline/shared_usage.txt`, `.../userdefaults_usage.txt`
- Behaviour: Runs `rg` across `FastingTracker/UI` + `FastingTracker/Core/ViewModels`, compares output to the baseline, and fails if new `.shared` or `UserDefaults.standard` references appear.
- Usage:
  ```bash
  cd Desktop/FastingTracker
  bash scripts/guardrails/check_singletons.sh
  ```
- Update the baseline only when intentionally removing/adding references (e.g., after Phase 1 cleanup).

## 2. Xcode Project File Guard

- Script: `scripts/guardrails/check_pbxproj_changes.sh`
- Behaviour: Inspects staged changes for `.pbxproj` edits. Fails unless the engineer sets `ALLOW_PBXPROJ=1` (forcing documentation + review).
- Usage:
  ```bash
  cd Desktop/FastingTracker
  git add ...
  bash scripts/guardrails/check_pbxproj_changes.sh   # fails if pbxproj staged without ALLOW_PBXPROJ
  ```
- Recommended to wire into a local git hook (`.git/hooks/pre-commit`) so pbxproj edits are deliberate.

## 3. Recommended Workflow

1. Run both guardrail scripts before committing.
2. If `check_singletons.sh` fails, fix the offending files or update the baseline after review.
3. If `check_pbxproj_changes.sh` fails, either remove the staged project-file change or set `ALLOW_PBXPROJ=1` (after documenting the reason in `HANDOFF.md`).

These guardrails complete Phase 0 of the North Star recovery plan and align with industry best practices (no accidental singleton creep, no unreviewed `.pbxproj` edits).
