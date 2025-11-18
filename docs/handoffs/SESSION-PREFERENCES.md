# Session Preferences

**Developer:** Rich Marin
**Project:** Fast LIFe - Enterprise Health Tracking Platform
**Last Updated:** 2025-10-28

---

## Communication Style

### What Works Best:
- **Direct and honest feedback** - "My dev team is shitting the bed" → I hear you, let's fix it
- **Action-oriented** - Less talk, more execution
- **Context-aware** - Review handoffs before proceeding
- **Strategic planning** - Plan first, discuss, then execute

### Response Format:
- Clear, structured plans with priorities
- Code changes with explanations
- Direct answers without fluff
- Concrete next steps

---

## Work Style

### Planning:
1. **Review context** - Check HANDOFF.md before starting; if a session recap is referenced (e.g., `docs/handoffs/reports/SESSION-RECAP-*.md`), read it immediately after compaction to regain full context.
2. **Create plan** - Document what will change and why
3. **Discuss first** - Get approval before executing
4. **Execute systematically** - Follow the plan, track progress

### Code Changes:
- **No surprise changes** - Always document what's changing
- **Test before commit** - Ensure builds succeed
- **Track progress** - Use TodoWrite for multi-step tasks
- **Clear communication** - Explain technical decisions

---

## Context Retrieval

- **Always read `docs/handoffs/HANDOFF.md` (latest entry) and any session recap or gameplan that file references before coding.**
- After compaction, follow the breadcrumb called out at the top of HANDOFF (currently `WEIGHT_TRACKER_NORTH_STAR_GAMEPLAN_2025-11-17.md`) so the next session resumes on the right slice.
- If HANDOFF references a QA playbook, audit, or runbook, skim those immediately so recommendations stay aligned with the latest decision record.

## Core Principles
1. **Protect working functionality** – Do not regress existing device-tested scenarios.
2. **Follow enterprise patterns** – SwiftUI MVVM + dependency injection (`WeightDependencies`) instead of `.shared`.
3. **Test and document** – Command‑U and targeted suites must pass; capture What/How/Expected/Actual notes in HANDOFF after every significant step.
4. **Prioritize infrastructure** – Improve architecture, accessibility, privacy, and observability before introducing new product features.

---

## Emergency Protocols

### When Things Break:
1. **Immediate triage** - What's broken? What's the impact?
2. **Fast analysis** - Don't change code, understand the problem first
3. **Clear plan** - Document fix approach in HANDOFF.md
4. **Get approval** - Discuss before executing
5. **Fix systematically** - Track with TodoWrite, test thoroughly

### Current Emergency:
**Firebase/Crashlytics freeze issue** - Dev team experiencing app freeze
- Root cause: Firebase initialization blocking main thread + UserDefaults corruption
- Status: Analysis complete, fix plan needed
- Next: Create comprehensive fix plan in HANDOFF.md

---

## Preferences Summary

✅ **DO:**
- Review HANDOFF.md before starting work
- Create clear, actionable plans
- Track progress with TodoWrite for complex tasks
- Test changes before considering them complete
- Update HANDOFF.md after major changes
- Be direct and honest about problems

❌ **DON'T:**
- Make surprise code changes without discussion
- Skip planning for complex fixes
- Ignore existing documentation
- Rush into execution without context
- Leave broken builds

---

**Remember:** We're transforming Fast LIFe from 3.5/10 to 8.5/10. Every change should move us closer to enterprise-grade quality.
