# Sprint Plan (2-week focus)

> **Single source of truth** for scope, acceptance criteria, and decisions.
> Repo-only workflow. No Slack/Kanban. The AI Dev reads this first.

## Sprint (dates)
- Start: 2025-10-11
- End:   TBD (set +14d)
- Goal (one sentence): Ship **default start tracker routing** and **Combined Setup onboarding**, while starting structural cleanup (linting + file splits), so first-time users get a fast win and the codebase stays maintainable.

## Top 3 deliverables (owners)
1) Default tracker routing (AppSettings + TabView selection) — Owner: AI Dev
2) Combined Setup onboarding (HealthKit + Units + Notifications) — Owner: AI Dev
3) Structural cleanup kickoff (SwiftFormat/SwiftLint + split files >400 LOC) — Owner: AI Dev

## Tickets + acceptance (max 3 bullets each)

- [T0] Phase 0 setup — SwiftFormat + SwiftLint ✅ **DONE**
  - [x] Add config files; Xcode Run Script Phase formats on build (or CI job ready but optional)
  - [x] One baseline formatting commit on main branch
  - [x] Lint passes on PR (no new warnings) - *SourceKit workaround documented*

- [T1] Folder structure & file splits (Phase 1 start)
  - [ ] Create target folders: App, Core/{Models,Managers,Persistence,Logging}, Features/*, UI/{Theme,Components}, Onboarding, Testing
  - [ ] Move legacy `*_old.swift` to `/Legacy` (excluded from target); ensure build green
  - [ ] No view/manager file > 400 LOC (or extracted subviews/helpers)

- [T2] Default tracker routing (Phase 2a)
  - [ ] `AppSettings.defaultTracker` persisted; TabView selects it at **cold start**
  - [ ] Setting survives relaunch & device reboot; add a minimal unit test for routing
  - [ ] Demo: change default → kill app → relaunch → lands on chosen tab

- [T3] “Make this default start screen” (per‑tracker settings)
  - [ ] Button updates `AppSettings.defaultTracker` with haptic/toast confirmation
  - [ ] Accessible label/value present; Dynamic Type supported
  - [ ] Demo: switch default across two trackers and relaunch to verify

- [T4] Combined Setup onboarding (Phase 2b)
  - [ ] One screen, one primary **Continue** CTA; inline validation for units + notifications
  - [ ] HealthKit/notification prompts only **after** Continue; Insights preview visible before prompts
  - [ ] Analytics events: `onboarding_started`, `onboarding_completed` (include units & permission flags)

- [T5] PR checklist adoption (quality gate)
  - [ ] Every PR uses the template with the same 3 acceptance bullets from this file
  - [ ] No force unwraps/casts; `.onChange` uses 2 params; long modifier chains split
  - [ ] New UI has a11y labels; note manual QA steps in PR

## Decisions (one‑liners; newest on top)
- 2025-10-11 — Adopt 4‑phase approach; start with Phase 0/1 + Phase 2a/2b; then layout changes — Owner: Rich
- 2025-10-11 — Repo‑only workflow (no Slack/Kanban); AI Dev follows SPRINT_PLAN.md — Owner: Rich
- 2025-10-11 — Use PR checklist as gate immediately — Owner: Rich

## Risks (G/Y/R)
- Onboarding scope creep — **Y** — Keep to one screen + Continue CTA; defer extras
- File moves causing merge pain — **G** — Do early (T1) and in a single PR
- HealthKit prompts timing — **G** — Trigger only after Continue (T4)