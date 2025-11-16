# Post-Crash Recovery Notes – 2025-11-13

> **Context:** Fast LIFe repo was restored to the 2025‑11‑01 backup after the project file corrupted on Nov 13. This document captures actionable references from 11/1–11/13 markdown files, automation opportunities, and crash-prevention steps so we can rebuild faster without re-inventing Phases 2–3 work.

## 1. Recoverable Documentation (11/1–11/13)

| Source | Highlights we can reuse now |
| --- | --- |
| `WEIGHT_TRACKER_ENTERPRISE_AUDIT_2025-11-05/06/07/08.md` | Detailed scoring rubric for enterprise readiness, DI gaps, measurement-system propagation, telemetry checklist, and access to AppLogger privacy tests. Provides ready-made acceptance criteria for Phases 1–3. |
| `SESSION-RECAP-2025-11-04/05.md` | Step-by-step logs of DI changes (Control Center, Progress Story), plus the measurement-system verification plan QA followed. |
| `SLICE3B-STATUS-2025-11-05.md` | Enumerates Progress Story localization, DI, and telemetry tasks with owners, making it easier to reapply. |
| `CRASHLYTICS_WEIGHT_METRIC_LOGS_2025-11-11.json` | Evidence that Crashlytics REST endpoints return 404s for custom logs; use this as proof we must export via console UI. |
| `SESSION-PREFERENCES.md` | Guardrails (Command‑U on device, no `xcodebuild test` locally, AppLogger privacy rules) remained up to date and should continue governing the recovery work. |

## 2. Automation & Script Opportunities

1. **Singleton & UserDefaults Lint Script**  
   - Add an `npm`/Swift script that runs `rg` for `.shared` and `UserDefaults.standard` inside `FastingTracker/UI` and fails CI if new instances appear outside approved files.  
   - Hook into a pre-commit or Fastlane lane to catch regressions before they land.

2. **WeightDependencies Scaffolding Script**  
   - Parameterize the DI bundle (e.g., `scripts/generate-weight-dependencies.swift`) to auto-create `.live/.preview` factories for new trackers. This prevents manual copy/paste errors when cloning patterns.

3. **Crashlytics Evidence Helper**  
   - Document a small shell script (run on Rich’s machine) that opens the saved `issuesQuery` URL and reminds the operator to export CSV + screenshot. Even though the export is manual, automation can handle file naming and storage paths in `docs/handoffs/reports/`.

4. **Telemetry Sink Tests**  
   - Build a fake telemetry sink and a CLI harness to run `swift test` for metrics redaction, ensuring each tracker inherits the same coverage automatically.

## 3. Crash Analysis & Prevention

**Incident Summary (Nov 13)**  
- Manual edits near `FastLIFe.xcodeproj/project.pbxproj` plus Crashlytics script changes corrupted large sections of the project file, leaving Xcode unable to open/build. Recovery required `git reset --hard` to the last known-good commit (11/1 backup).

**Root Causes**
1. **Direct project.pbxproj editing without Xcode**: increases risk of merge conflicts and broken references.  
2. **Crashlytics automation attempts**: Lack of official REST support for custom log filters (confirmed by `CRASHLYTICS_WEIGHT_METRIC_LOGS_2025-11-11.json`), leading to dead-end scripts and potential file churn.  
3. **Missing guardrails**: No pre-commit hook to detect modifications to Xcode project file or Crashlytics scripts without review.

**Prevention**
- **Lock down project files**: Use git attributes/pre-commit hooks to require Xcode-generated diffs (e.g., fail if `project.pbxproj` changes outside approved scripts).  
- **Respect Firebase guidance**: Only use the console UI for Crashlytics custom log exports; document this in `docs/runbooks/OBSERVABILITY_RUNBOOK.md` to prevent future REST experiments.  
- **Automated backups**: Schedule nightly `git tag backup-YYYY-MM-DD` or artifact export so we can roll back without losing 12+ days of work.  
- **Change reviews**: Require peer review for any script touching Crashlytics, Xcode build settings, or DI scaffolding to catch risky edits early.

## 4. Next Actions
1. Follow the phased recovery plan (`WEIGHT_TRACKER_NORTH_STAR_PLAN_2025-11-13.md`), leveraging the documentation above.  
2. Implement the lint scripts/pre-commit checks to block `.shared` and `UserDefaults.standard` regressions.  
3. Update `docs/runbooks/OBSERVABILITY_RUNBOOK.md` with the console-only Crashlytics workflow and the manual export script instructions.  
4. Once Phases 1–3 are restored, schedule a new enterprise audit and record prevention steps in HANDOFF §3 to memorialize the Nov 13 incident.
