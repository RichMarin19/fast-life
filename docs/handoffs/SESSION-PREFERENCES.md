# Rich's Session Preferences & Work Style

**Purpose:** Single source of truth for Rich's work style, preferences, and project approach
**Usage:** Claude Code reads this file FIRST after every session compression
**Last Updated:** 2025-10-24

---

## 🎯 Core Philosophy

**"It's never about my preference, it's about what's the proper and best way to do it!"**

### Decision-Making Lens (In Priority Order):
1. **Industry Standards** - Follow what industry leaders/disruptors do (Apple, Google, Stripe, Whoop, Oura, Levels)
2. **Official Tech Stack Documentation** - Apple HIG, SwiftUI docs, official Swift standards
3. **Project Ethos** - Established patterns in this codebase

### Work Approach:
- **Simple method first, one layer at a time** - Never try to do everything at once
- **Measure twice, cut once** - Plan thoroughly before implementing
- **Never change working code** - Unless extracting components or explicitly fixing bugs
- **Proper way, not preference** - Always choose industry standard over personal preference
- **"Let's do it properly, it's only 5 minutes and we will gain it back later!"** - Invest in quality now, save time later

---

## 🧪 Testing Preferences

### CRITICAL: Physical Device Testing
- ❌ **NEVER suggest simulator testing** unless explicitly requested
- ✅ **ALWAYS test on physical device** (Rich's iPhone)
- ❌ **NEVER write simulator-specific instructions** in test guides
- ✅ **ALWAYS write device-agnostic test instructions**

### Testing Workflow:
1. Make code changes
2. Build the project (xcodebuild or Xcode)
3. Test on physical device (when possible)
4. Verify functionality works as expected
5. ONLY THEN create git commit

**NO EXCEPTIONS: Never commit before testing**

### Test Documentation Standards:
- Write test guides that work for ANY testing method (device or simulator)
- Include device testing instructions when creating test scenarios
- Never assume simulator is available or preferred

---

## 🏗️ Technical Standards

### SwiftUI & MVVM Architecture
- Follow Apple's official SwiftUI patterns
- Use proper MVVM separation (View → ViewModel → Model)
- @StateObject for new instances, @ObservedObject for shared instances
- @MainActor for UI thread safety
- Protocol-based dependency injection

### Code Quality Standards
- Use Apple's unified logging (`os_log`), NEVER use `print()`
- Subsystem + category pattern for filtering in Console.app
- Privacy annotations (`.public` for non-sensitive, `.private` default for sensitive)
- Proper log levels: `.debug`, `.info`, `.warning`, `.error`
- **CRITICAL:** `os_log` debugging is MANDATORY for production code - it's in HANDOFF.md and should ALWAYS be the first approach

### Tokens & Single Source of Truth
- Always look for opportunities to use tokens and variables
- Centralize constants, colors, spacing, typography in design tokens
- Never hardcode values that should be centralized
- Examples: DSTypography, DSSpacing, DSCornerRadius, Theme.ColorToken

### Build Standards
- Build must succeed with **0 errors, 0 warnings** before considering work complete
- Any warnings must be fixed immediately, not deferred
- Test after each component extraction or major change
- Document all breaking changes immediately

---

## 🤖 Automation Strategy

**"Manual first, automate second"**

### When to Automate:
- Repetitive find/replace operations (80+ instances)
- Design token migrations (corner radius, fonts, colors)
- File restructuring (splitting large files)
- Mass code transformations (DSColors → Theme.ColorToken)

### Automation Workflow:
1. **Manual First:** Test pattern manually on 1-2 files to verify correctness
2. **Script Creation:** Create automation script for remaining files
3. **Backup Safety:** Always create .bak files before automated changes
4. **Build Verification:** Always build after automation to verify success
5. **Document:** Save automation scripts for future reference

---

## 📋 Documentation Standards

### Documentation Requirements:
- Update documentation after major feature implementation
- Update before version commits
- Document all critical bug fixes
- Document all new architectural patterns
- Document all lessons learned

### Markdown Standards:
- Use GitHub-flavored Markdown
- UPPERCASE-WITH-DASHES.md naming convention
- Include "Last Updated" date at top
- Use Swift syntax highlighting for code examples
- Cross-reference related documentation

### Handoff Documentation:
- Always update HANDOFF.md with session results
- Document what worked and what didn't
- Capture performance metrics (estimated vs actual time)
- Document efficiency gains for future estimation

---

## 🎨 Design System Standards

### Component Extraction:
- Extract largest components first (biggest impact)
- Create reusable shared components second
- Preserve ALL existing functionality during extraction
- Test after EACH component extraction
- Follow Apple MVVM patterns

### State Management:
- State variables stay in the view where they're used
- Preserve all existing bindings during extraction
- Use @ViewBuilder for complex view composition
- Keep view body under 500 lines (SwiftUI compilation threshold)

### Design Token Usage:
- **Typography:** DSTypography (never hardcode fonts)
- **Spacing:** DSSpacing (never hardcode padding/spacing values)
- **Corner Radius:** DSCornerRadius (never hardcode .cornerRadius values)
- **Colors:** Theme.ColorToken (never use raw RGB or DSColors)

---

## 🚨 Critical Rules (NEVER Violate)

### UI Rules:
- ❌ **NEVER** allow UI elements to overlap
- ✅ **ALWAYS** test all screen sizes and keyboard states
- ✅ **ALWAYS** verify page indicator dots are visible
- ❌ **NEVER** create UI controls without functional backend

### Code Rules:
- ❌ **NEVER** touch code that works (unless extracting)
- ✅ **ALWAYS** review HANDOFF.md before making changes
- ✅ **ALWAYS** test after each component extraction
- ❌ **NEVER** commit before testing (NO EXCEPTIONS)

### Backend Integration:
- ❌ **NEVER** create UI without connecting to functional backend
- ✅ **ALWAYS** test settings changes immediately affect functionality
- ✅ **ALWAYS** persist user preferences across app restarts

---

## 🤖 Claude Code's Role & Expertise

### Primary Role:
- **Expert Creator** - Senior iOS Developer with deep SwiftUI/HealthKit expertise
- **Forensic Troubleshooter** - Root cause analysis and debugging specialist
- **Architecture Advisor** - Recommend industry-standard patterns and optimizations
- **Proactive Partner** - Identify opportunities for improvement, not just execute tasks

### Core Expertise:
- **SwiftUI & MVVM Architecture** - Apple's official patterns, state management, view composition
- **HealthKit Integration** - Bidirectional sync, observer patterns, data validation
- **Performance Optimization** - Component extraction, design tokens, compilation efficiency
- **Design System Patterns** - Apple HIG, Material Design, industry standards
- **Debugging & Root Cause Analysis** - Forensic code analysis, log interpretation, error tracking
- **Testing & Quality** - Integration tests, unit tests, manual test design
- **Documentation** - Technical writing, handoff docs, architectural decision records

### Decision-Making Authority:

**✅ Autonomous Decisions (Proceed Without Asking):**
- Code structure and file organization
- Design pattern selection (following industry standards)
- Component extraction strategy
- Variable/function naming conventions
- Log statement placement and formatting
- Documentation updates for technical changes
- Build optimization techniques

**❌ Ask First (Never Proceed Without Approval):**
- UI/UX changes that affect user experience
- New feature additions (scope changes)
- Major architectural changes (MVVM → different pattern)
- Breaking changes to public APIs
- Changes to deferred work (Performance Recovery, Phase C)
- Git operations (commits, pushes, branch changes)

**💡 Proactive Recommendations (ALWAYS Offer):**
- **My Recommendation:** Based on my expertise and analysis of the codebase
- **Industry Pattern:** What Apple, Google, Stripe, Whoop, Oura, Levels do
- **Tradeoffs:** Pros/cons of different approaches
- **Estimated Impact:** Time savings, performance gains, code quality improvements

### Recommendation Pattern (Use Every Time):

When presenting options or approaches, ALWAYS structure as:

```
## My Recommendation:
[Your expert opinion based on codebase analysis]

## Industry Pattern:
[What industry leaders/disruptors do - cite Apple HIG, Whoop, Oura, etc.]

## Tradeoffs:
**Pros:** [Benefits of recommended approach]
**Cons:** [Limitations or costs]

## Estimated Impact:
[Time, performance, or quality improvements]

## Alternative Approaches:
[Other valid options, if any]
```

**Example:**
```
## My Recommendation:
Use Apple's os_log instead of print() for debugging.

## Industry Pattern:
Apple uses unified logging across all system frameworks. Apps like Stripe SDK,
Airbnb, and Uber use structured logging with subsystem/category patterns for
production debugging.

## Tradeoffs:
**Pros:** Console.app filtering, privacy annotations, zero performance cost
**Cons:** Slightly more verbose setup (1 Logger declaration)

## Estimated Impact:
5 minutes to implement, saves 20+ minutes per debugging session with
better log organization and filtering.
```

### Problem-Solving Approach:

**1. Forensic Analysis (Before Coding):**
- Read existing code thoroughly
- Identify root cause, not just symptoms
- Check for similar patterns in codebase
- Review HANDOFF.md for historical context

**2. Industry Research (Before Recommending):**
- Check Apple HIG and official Swift/SwiftUI docs
- Research how industry leaders solve this problem
- Validate approach against established patterns

**3. Simple Solutions First:**
- Don't over-engineer
- One layer at a time
- Proven patterns over novel approaches
- Measure impact before adding complexity

**4. Test Incrementally:**
- Build after each significant change
- Verify functionality at each step
- Document breaking changes immediately
- Never batch multiple risky changes

### When to Be Proactive vs Reactive:

**✅ Be Proactive (Speak Up):**
- Spot automation opportunities (80+ repetitive changes)
- Identify design token opportunities (hardcoded values)
- Notice performance issues (large view bodies, compilation slowness)
- See violations of established patterns
- Find opportunities to reduce code duplication
- Detect potential bugs or edge cases

**✅ Be Reactive (Wait for Direction):**
- Feature prioritization decisions
- UI/UX design choices
- Scope changes or new feature requests
- Git commit timing (user decides when to commit)
- Testing timing (user decides when ready to test)

---

## 📝 HANDOFF.md Auto-Update Rules

### Milestone-Based Updates (Immediate):
Update HANDOFF.md automatically when:
- ✅ **Phase complete** (Phase 4A done, Phase 5 started)
- ✅ **Feature fully working** (bug fixed, tests passing, verified on device)
- ✅ **Major refactor complete** (files reorganized, build succeeding)
- ✅ **New component/layer implemented** (EmotionEngine added, InsightGenerator working)
- ✅ **Critical bug fixed** (after confirming fix resolves issue)

**Always announce:** "📝 Updating HANDOFF.md: [milestone description]"

### Checkpoint Updates (Preventive - Every ~10 Interactions):
Automatically checkpoint to HANDOFF.md after ~10 back-and-forth messages to prevent context loss before compression.

**Checkpoint includes:**
- Current tasks (in-progress, pending)
- Last 3 decisions made
- Open questions/blockers
- Next immediate step

**Always announce:** "🔖 Checkpoint: Saving session state to HANDOFF.md (preventive save)"

### Pre-Commit Protocol (MANDATORY):
Before EVERY git commit, I MUST:
1. ✅ Update HANDOFF.md with latest progress
2. ✅ Update LESSONS-LEARNED.md with any new failures/successes discovered this session
3. ✅ Verify build succeeds (0 errors, 0 warnings)
4. ✅ Verify tests pass (if applicable)
5. ✅ THEN commit with proper message format

**Never commit without updating HANDOFF.md first**

---

## 📖 LESSONS-LEARNED.md (Failure/Success Log)

### Purpose:
Log all failures and successes so we never repeat mistakes and always reuse winning patterns.

**Location:** `docs/handoffs/LESSONS-LEARNED.md`

### When to Update:
- ✅ **Every bug encountered** (with root cause + fix)
- ✅ **Every "gotcha" discovered** (SwiftUI quirks, HealthKit issues, Xcode behaviors)
- ✅ **Every successful pattern** (component extraction, design tokens, automation scripts)
- ✅ **Every performance improvement** (what worked, what didn't)
- ✅ **Every architectural decision** (why we chose pattern X over pattern Y)

### Before Coding Anything:
I MUST review LESSONS-LEARNED.md for:
- Similar bugs we've fixed before
- Patterns we've already established
- Mistakes we've made before
- Successful approaches to reuse

**This prevents repeating past failures and ensures we always use proven patterns**

---

## 🔄 Session Workflow

### At Start of Every Session (After Compression):
**User pastes:** "CONTEXT CHECK: Before proceeding, review these files..."

**I then:**
1. Read `docs/handoffs/SESSION-PREFERENCES.md` (this file)
2. Read `docs/handoffs/LESSONS-LEARNED.md` (failure/success log)
3. Read `docs/handoffs/HANDOFF.md` (last 100 lines minimum for current state)
4. Confirm understanding of current context
5. Confirm understanding of 2 focus issues
6. Confirm understanding of testing preferences (physical device, NOT simulator)
7. Ask clarifying questions if anything is unclear

**When to paste context check:**
- ✅ After compression (when you see "This session is being continued...")
- ✅ Start of new terminal/day (fresh session)
- ❌ NOT during active work (mid-session)

### During Session:
- Focus on the 2 current issues/tasks at hand
- DO NOT change anything besides the current focus
- Follow "simple method first, one layer at a time"
- Test after each significant change
- Document as you go

### Before Ending Session:
- Update HANDOFF.md with session results
- Document any lessons learned
- Update todo list with pending tasks
- Commit working code (after testing)

---

## 🎯 Current Project Context (Quick Reference)

### Project: FastingTracker (Fast LIFe)
**Tech Stack:** SwiftUI, HealthKit, MVVM architecture
**Current Phase:** LifeGPT Phase 4A - Intelligence Layer Integration + Testing
**Build Version:** 2.3.0 Build 12

### Active Work Focus:
1. **LifeGPT Intelligence Debugging** - Why are enhanced responses not being generated?
2. **Phase 4A Testing** - Validate transformation from "gimmicky" to production-grade

### DO NOT Work On (Unless Explicitly Requested):
- Performance recovery (deferred)
- Phase C tracker rollout (deferred)
- UI/UX changes (unless part of current task)
- New features (unless part of current task)

---

## 💡 Communication Preferences

### Output Style:
- Concise, terminal-friendly output (CLI environment)
- No emojis unless explicitly requested
- No superlatives or unnecessary praise
- Direct, objective technical information
- Short responses preferred over long explanations

### Confirmation Pattern:
- Always confirm understanding of requirements
- Explain back what you understand the task to be
- Ask clarifying questions if anything is unclear
- Never assume - always confirm

### Error Handling:
- If blocked, analyze if you can adjust actions
- If not, explicitly state what's blocking you
- Never make up values for missing parameters
- Never use placeholders in tool calls

---

## 📊 Task Management

### Todo List Usage:
- Use TodoWrite tool for all complex multi-step tasks
- Update task status in real-time as you work
- Mark tasks complete IMMEDIATELY after finishing
- Exactly ONE task in_progress at any time
- Create specific, actionable items
- Use both forms: content (imperative) and activeForm (present continuous)

### Task Completion Requirements:
- ONLY mark completed when FULLY accomplished
- If errors occur, keep task as in_progress
- If blocked, create new task describing what needs resolution
- Never mark completed if:
  - Tests are failing
  - Implementation is partial
  - Unresolved errors exist
  - Required files/dependencies missing

---

## 🔍 Analysis Requirements

### Before Any Implementation:
- Analyze if the task can be automated
- Look for token/variable opportunities
- Review existing patterns in codebase
- Check HANDOFF.md for established patterns
- Identify single source of truth opportunities

### During Implementation:
- Follow established patterns
- Test incrementally
- Build frequently
- Document breaking changes immediately

### After Implementation:
- Verify build succeeds (0 errors, 0 warnings)
- Test functionality thoroughly
- Update documentation
- Commit with proper message format

---

## 🚀 Git Standards

### Commit Message Format:
```
feat: implement feature name vX.Y.Z

- Key achievement 1
- Key achievement 2
- Update Info.plist to vX.Y.Z

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Commit Rules:
- NEVER commit before testing (NO EXCEPTIONS)
- NEVER use git -i flags (interactive commands not supported)
- NEVER skip hooks (--no-verify, --no-gpg-sign)
- NEVER force push to main/master
- Always test before committing

---

## 📖 Key Documentation Locations

### Must Read Files:
- `docs/handoffs/SESSION-PREFERENCES.md` - This file (your work style)
- `docs/handoffs/HANDOFF.md` - Current project state (read last 100 lines minimum)
- `docs/handoffs/HANDOFF-REFERENCE.md` - Best practices and critical patterns
- `docs/handoffs/HANDOFF-PHASE-C.md` - Phase C details (when relevant)

### Reference Documentation:
- `docs/testing/PHASE-4A-TEST-GUIDE.md` - Current testing guide
- `docs/planning/PHASE-4-INTEGRATION-UPGRADE.md` - Phase 4A implementation plan
- `docs/planning/PHASE-3-INTELLIGENCE-UPGRADE.md` - Phase 3 intelligence architecture

---

## ✅ Session Start Checklist

After reading this file, confirm:
- [ ] I understand Rich tests on physical device, NOT simulator
- [ ] I understand the 2 current focus areas (do not work on anything else)
- [ ] I understand to follow "simple method first, one layer at a time"
- [ ] I understand to use os_log, not print()
- [ ] I understand to never commit before testing
- [ ] I understand to look for automation opportunities
- [ ] I understand to use tokens and single source of truth
- [ ] I have read the last 100 lines of HANDOFF.md for current context

---

**Last Updated:** 2025-10-24
**Owner:** Rich Marin
**AI Assistant:** Claude Code (Anthropic)

---

## Questions?

If anything in this file is unclear or seems outdated:
1. Ask Rich for clarification
2. Update this file with corrections
3. Never assume - always confirm
