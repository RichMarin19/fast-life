# Fast LIFe - iOS Health Tracking App

> **"Track Your Life, Fast." - Intermittent Fasting • Hydration • Sleep • Mood • Weight**

**Version:** 2.3.0 (Build 12) | **Status:** Production Ready | **Phase:** C - UI/UX Enhancement

---

## 🚀 Quick Start (30 Minutes to Productivity)

**New Developer? Start here:**

1. **Project Overview** (5 min) - Read sections below
2. **[HANDOFF.md](./HANDOFF.md)** (10 min) - Current status & navigation
3. **[HANDOFF-PHASE-C.md](./HANDOFF-PHASE-C.md)** (10 min) - Current work details
4. **[WeightTrackingView.swift](./FastingTracker/WeightTrackingView.swift)** (5 min) - Gold standard code (257 LOC)

**✅ You're ready to contribute!**

---

## 📚 Documentation Map (10 Files)

### Start Here
- **README.md** ← You are here (onboarding)
- **[HANDOFF.md](./HANDOFF.md)** - Main index, current status

### Active Work
- **[HANDOFF-PHASE-C.md](./HANDOFF-PHASE-C.md)** - Phase C details (UI/UX + Code refactoring)
- **[NORTH-STAR-STRATEGY.md](./NORTH-STAR-STRATEGY.md)** - Weight Tracker as UI/UX template
- **[TRACKER-AUDIT.md](./TRACKER-AUDIT.md)** - Current assessment (7.2/10 overall)

### Standards & Guides
- **[CODE-QUALITY-STANDARDS.md](./CODE-QUALITY-STANDARDS.md)** - LOC policy (400 trigger, 250-300 target)
- **[SCORING-CRITERIA.md](./SCORING-CRITERIA.md)** - Evaluation framework (1-10 scale)
- **[HANDOFF-REFERENCE.md](./HANDOFF-REFERENCE.md)** - Best practices & patterns

### History & Process
- **[HANDOFF-HISTORICAL.md](./HANDOFF-HISTORICAL.md)** - Completed phases archive
- **[GITHUB-SYNC-STRATEGY.md](./GITHUB-SYNC-STRATEGY.md)** - Repository sync procedures

**Reading Order:** README → HANDOFF → HANDOFF-PHASE-C (25 minutes total)

---

## 🎯 Current Status

**Overall Score:** 7.2/10 (Very Good - Production Ready)

| Dimension | Score | Status |
|-----------|-------|--------|
| Code Quality | 8.5/10 | ✅ Excellent |
| Documentation | 9.0/10 | ✅ Exceptional |
| UI/UX | 6.5/10 | ⚠️ Needs Polish |
| Customer Experience | 7.5/10 | ✅ Very Good |
| CI/TestFlight | 4.0/10 | ⚠️ Needs Setup |

**Current Focus:** Phase C - UI/UX Enhancement (Week 1-3)

---

## 🏗️ Architecture

**Pattern:** MVVM (Model-View-ViewModel)

```
Views (SwiftUI)          → WeightTrackingView, ContentView (≤300 LOC)
    ↓ @ObservedObject
Managers (Business)      → WeightManager, FastingManager (@Published)
    ↓ Codable
Models (Data)            → WeightEntry, FastingSession (structs)
```

**Key Patterns:**
- Component extraction (90% LOC reduction achieved on Weight tracker)
- TrackerScreenShell (reusable header/settings pattern)
- HealthKit bidirectional sync (deletion sync - exceeds industry standards)
- Behavioral notifications (Phase B complete)

---

## 📊 Tracker Status

| Tracker | LOC | Target | Status | Phase C Priority |
|---------|-----|--------|--------|------------------|
| Weight | 257 | 300 | ✅ GOLD STANDARD | Use as North Star |
| Mood | 97 | 300 | ✅ OPTIMAL | Maintain excellence |
| Sleep | 304 | 300 | ⚠️ +4 LOC | C.1 - LOW RISK |
| Hydration | 584 | 300 | ❌ -284 LOC | C.2 - MEDIUM RISK |
| Fasting | 652 | 300 | ❌ -352 LOC | C.3 - HIGH RISK |

**Policy:** 400 LOC = mandatory refactor | 250-300 LOC = optimal

---

## 🛠️ Development Setup

**Prerequisites:**
- Xcode 16.2+
- macOS 14.0+ (Sonoma)
- iOS 17.0+ deployment target

**Setup:**
```bash
open FastingTracker.xcodeproj
# Build: Cmd+B (Expected: ✅ 0 errors, 0 warnings)
# Run: Cmd+R (App launches with onboarding)
```

**Dependencies:** None (SwiftUI Charts, HealthKit built-in)

---

## 🎯 Phase C: Current Work

### Phase C.1 - UI/UX North Star (Week 1-2)
**Goal:** Consistent visual design across all trackers

**North Star:** Weight Tracker (best current state)

**Tasks:**
- Polish Weight tracker visual design
- Document patterns (colors, spacing, typography)
- Apply TrackerScreenShell to all trackers
- Standardize settings gear icon
- Add empty states

**Result:** All trackers look like one cohesive app

### Phase C.2 - Code Refactoring (Week 2-3)
**Goal:** All trackers ≤300 LOC

**Rollout:** Sleep (304→300) → Hydration (584→300) → Fasting (652→300)

**Result:** Clean code + beautiful UI

---

## 🤝 Contributing

**Before Changes:**
1. Read [HANDOFF.md](./HANDOFF.md)
2. Read [HANDOFF-REFERENCE.md](./HANDOFF-REFERENCE.md) (patterns & pitfalls)
3. Review [CODE-QUALITY-STANDARDS.md](./CODE-QUALITY-STANDARDS.md)

**Code Standards:**
- Files ≤400 LOC (preferably ≤300)
- MVVM architecture
- 0 errors, 0 warnings
- Test all screen sizes

**Commit Format:**
```
<type>(<scope>): <subject>

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
```

---

## 🏆 Achievements

- ✅ Weight: 90% LOC reduction (2,561→257)
- ✅ Mood: 80% LOC reduction (488→97)
- ✅ Documentation: 9.0/10 (Industry-leading)
- ✅ HealthKit: Bidirectional sync with deletion
- ✅ Build: 0 errors, 0 warnings

---

**Last Updated:** October 16, 2025
**Next Milestone:** Phase C.1 completion (UI/UX polish)
