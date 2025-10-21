# Fast LIFe — *Your LIFe Journey*
### Phase v1.2 – Full Build Handoff (Developer, Design, QA)

**Owner:** Product & UX (Rich Marin)
**Audience:** Senior iOS Developer (SwiftUI), UI/UX Designer, QA Engineer
**Purpose:** Deliver a unified technical and creative blueprint to finalize “Your LIFe Journey” — transforming it from functional to emotionally sticky, premium, and aligned with Apple’s HIG and behavioral design best practices.

---

## A) What’s Already Right (Keep As-Is)
- Adaptive background tied to 7‑day trend ✅
- Light card surfaces (ice / ivory / mint) ✅
- Circular trend ring with ambient glow ✅
- Behavioral micro‑copy and tags ✅
- Per‑card opt‑out (eye menu, persistent) ✅
- Reduce Motion compliance ✅

---

## B) Gaps vs. Intent (From Screenshots)
1. **Coach Bar** – Copy is good but underpowered visually.
2. **Ring Glow** – Ambient glow is faint on light surfaces.
3. **Emotion Indicator** – Slightly undersized for legibility.
4. **Background Mood** – Coral overlay too muted; emotion should register subconsciously within 1s.
5. **Top Controls** – Need accessibility labels + HIG touch targets.
6. **Narrative Rhythm** – Missing subtle “ownership” micro‑interactions.
7. **Vertical Spacing** – Slightly cramped; needs more breathing room.

---

## C) Visual & Motion Tweaks (Implementation‑Ready)
### 1. Coach Bar — Emotional Anchor
**Goal:** The Coach Bar should act as the user’s “encouraging voice.”

**Specs:**
- Background: `surface.mint` (0.6 blur)
- Padding: 12pt vertical, 16pt horizontal
- Font: `.system(size: 16, weight: .semibold)`
- Color: `#334155` (AA on mint)
- Icon: `sparkles` or `heart.text.square`, 18‑20pt, `accent.infoBlue`
- Corners: 14pt radius, stroke `stroke.light` (1pt), shadow `shadow.card` (radius 8)
- Placement: Directly beneath “Your LIFe Journey” title

**SwiftUI Stub:**
```swift
CoachBar(text: coachLine(for: state7), icon: "sparkles")
    .padding(.horizontal, 16)
```
---

### 2. Trend Ring Glow (Visual Strength)
**Goal:** Enhance visibility of glow while retaining luxury restraint.
- Shadow: `accent.opacity(0.40)`, radius 20, y: 7
- Add inner halo: 180×180 circle, `accent.opacity(0.08)`, blur radius 14
- Skip halo on Reduce Motion

**SwiftUI:**
```swift
Circle()
  .trim(from: 0, to: progress)
  .stroke(style: StrokeStyle(lineWidth: 16, lineCap: .round))
  .fill(LinearGradient(colors: [accent.opacity(0.9), accent.opacity(0.6)],
        startPoint: .leading, endPoint: .trailing))
  .rotationEffect(.degrees(-90))
  .shadow(color: accent.opacity(0.40), radius: 20, x: 0, y: 7)
  .overlay(Circle().stroke(accent.opacity(0.10), lineWidth: 1).blur(radius: 6))
```
---

### 3. Emotion Indicator (Icon + Label)
- Icon: 20pt, Label: `.system(size: 14, weight: .semibold)`
- Always pair color + icon for color‑blind clarity

| State | Icon | Label |
|-------|------|--------|
| improving | `checkmark.seal` | “trend down” |
| regressing | `arrow.up.right.circle` | “trend up” |
| stable | `pause.circle` | “holding steady” |

---

### 4. Background Mood Intensity
**Goal:** Background must subtly express emotional feedback.
- **Improving/Regressing:** top 0.22 opacity, bottom 0.16
- **Stable:** top 0.18, bottom 0.12
- Crossfade animation 0.6s; micro‑drift ±8pt, disabled on Reduce Motion

---

### 5. Top Controls
**Goal:** Meet Apple’s Human Interface Guidelines.
- Touch area ≥ 44×44pt
- Accessibility labels: “Hide journey cards”, “Done – close journey”
- SF Symbol: `eye.slash`, 17pt, frosted/navy background capsule
- Shadow radius 6; inset padding 12×12

---

### 6. Layout & Spacing
- Major block spacing: 20pt (was 16pt)
- Internal card padding: 16pt, plus 12pt above micro‑copy lines

---

## D) Sticky Ownership Hooks (Behavioral Science)
### 1. Win Micro‑Moments
- When trend = improving, show one‑time **“win halo”**: outer glow expands + fades in 0.9s
- Haptic `.light` once (skip Reduce Motion)
- Copy override once per open: “You earned today’s win.”

**SwiftUI:**
```swift
@State private var halo = false
Circle()
  .stroke(accent.opacity(0.15), lineWidth: 8)
  .scaleEffect(halo ? 1.12 : 1.0)
  .opacity(halo ? 0.0 : 1.0)
  .animation(.easeOut(duration: 0.9), value: halo)
  .onAppear { if isImproving && !reduceMotion { halo = true; impact(.light) } }
```
---

### 2. Subtle Streak Cue
- Recap row: `flame.fill` + `{streak}-day streak`
- New best streak → small badge dot + haptic `.success`

### 3. Reflection Nudge
Below 30‑day card, rotate one line at random:
- “One small habit to try this week?”
- “What helped most on your best day?”
- “Pick tomorrow’s anchor: sleep / steps / water.”

Tap → triggers micro‑plan Coach prompt (stub now, functional later).

### 4. Personalization
Optional title: “{FirstName}’s LIFe Journey” (opt‑in only, Me → Preferences).
Default: “Your LIFe Journey”.

---

## E) Copy Refinements (Empathetic, Precise)
**7‑Day:**
- Improving → “Small wins compound — keep stacking days.”
- Regressing → “Small upticks are data — today is your pivot.”
- Stable → “Consistency is power — nudge the routine by 1%.”

**30‑Day:**
- Improving → “Momentum building this month.”
- Regressing → “Let’s course‑correct this week.”
- Stable → “Holding steady — great platform for a push.”

> Stored in `BehavioralCopy.plist` for real‑time iteration without app rebuilds.

---

## F) Accessibility (HIG)
- Touch targets ≥ 44×44pt
- Dynamic Type: Titles scale to XL gracefully
- Contrast AA or higher on all surfaces
- VoiceOver examples:
  “Trend down 1.2 pounds in 7 days. Tip: small wins compound.”
  “Trend up 0.8 pounds — small upticks are data, not defeat.”

---

## G) QA Checklist (Acceptance Criteria)
1. Background mood transitions within 600ms; drift paused on Reduce Motion.
2. Coach Bar under title; 16pt semibold font; AA contrast verified.
3. Glow visible on all light cards; halo performs 1.0→1.12→1.0 pulse.
4. Emotion indicator icon 20pt, label 14pt, no truncation.
5. Layout spacing correct (20pt blocks, 12pt internal gap).
6. Win halo + haptic trigger only once per open.
7. Streak badge triggers only on new best streak; haptic `.success`.
8. Per‑card opt‑out persists; “Show again” visible when hidden.
9. 44×44 controls pass accessibility inspector.
10. 60fps frame budget; no lag or jank in scroll view.

---

## H) SwiftUI Implementation Notes
- Avoid nested `GeometryReader` or heavy blurs in scroll.
- Use `.matchedGeometryEffect` for card animations (lighter than scale effects).
- Use `.accessibilityLabel` for icon‑only buttons.
- Offload `trendState()` computation to `@MainActor` if used in multiple async views.
- Wrap CoachBar in `@ViewBuilder` for reuse across trackers.

---

## I) Rollout Plan
1. **Feature flag:** `journeyV12Polish` for staging.
2. **QA duration:** 3 days internal + beta test cohort.
3. **Metrics to track:**
   - Dwell time lift ≥ 8%
   - Opt‑out < 5% on 7‑day card
   - New streak engagements ↑ 10%
4. If metrics hold, merge into `release/1.2.0` branch for production rollout.

---

**Tone:** Calm • Encouraging • Luxurious • Human
**Mantra:** *Show up → Feel seen → Keep going.*

---

## J) Implementation Results & Lessons Learned

### ✅ COMPLETED (Phase v1.2a - Coach Bar Polish)

**Date:** October 21, 2025
**Status:** ✅ BUILD SUCCEEDED | 0 errors, 0 warnings | Functionality verified

#### 1. Coach Bar Implementation
**Goal:** Transform Coach Bar from functional to emotionally sticky premium component.

**Changes Made:**
- ✅ Background: Changed from `surface.mint` → `Theme.ColorToken.accentInfo` (royal blue)
- ✅ Text & Icon: Changed from `textPrimary` → `.white` for better visibility
- ✅ Hide Functionality: Added ZStack overlay with `eye.slash` button (44×44pt HIG compliant)
- ✅ Dual Visibility System: Integrated with both ProgressStoryCardManager + ContentOptOutManager
- ✅ Restore Functionality: Added `.coachBar` case to ProgressStoryCardType enum

**Files Modified:**
- `FastingTracker/UI/Components/WeightComponents.swift` (lines 1003-1056, 684-702)
- `FastingTracker/WeightControlCenterView.swift` (line 80)
- `FastingTracker/Theme.swift` (color token definitions)

**Design Iterations:**
1. **Initial Implementation:** Mint background + textPrimary → Low visual prominence
2. **User Feedback:** "Container color great, padding changed, subtitle lost"
3. **Final Solution:**
   - Kept accent background (perfect visual prominence)
   - Restored original padding (removed `.alignment` parameter)
   - Changed subtitle to white (excellent gradient visibility)

#### 2. Subtitle Enhancement
**Problem:** Gray italic subtitle (`textSecondary`) was lost on dark teal gradient background.

**Solution:** Changed to `.white` for maximum contrast and readability.
- **Before:** `Theme.ColorToken.textSecondary` (#475569 slate gray)
- **After:** `.white` (#FFFFFF)
- **Result:** Subtitle "Progress you can feel — one choice at a time." is now clearly readable

#### 3. Control Center Integration
**Problem:** Restore button didn't bring Coach Bar back after hiding.

**Root Cause:** Coach Bar only used ContentOptOutManager, not ProgressStoryCardManager (master toggle system).

**Solution:** Implemented dual manager pattern (matching 7-Day, Banner, etc.):
```swift
// Visibility check (BOTH managers)
if progressStoryCardManager.isCardVisible(.coachBar) &&
   !optOutManager.isContentOptedOut(id: contentID_CoachBar)

// Hide callback (uses ProgressStoryCardManager)
progressStoryCardManager.hideCard(.coachBar)
```

**Result:** ✅ Hide → Control Center → Restore now works perfectly

#### 4. Key Lessons Learned

**Lesson 1: Frame Alignment Side Effects**
- Adding `.frame(maxWidth: .infinity, alignment: .leading)` affected internal padding distribution
- **Fix:** Use `.frame(maxWidth: .infinity)` without alignment parameter for better padding control
- **Takeaway:** Alignment parameters can have unexpected side effects on internal spacing

**Lesson 2: Color Tokens Must Match Surface Context**
- `textSecondary` is designed for light surfaces, not dark gradients
- **Fix:** Use contextual colors (`.white` or `textOnDark` tokens) for gradient backgrounds
- **Takeaway:** Always verify color tokens against actual background context

**Lesson 3: Dual Visibility System Pattern**
- Cards need BOTH ProgressStoryCardManager (master) + ContentOptOutManager (individual)
- **Fix:** Follow exact pattern used by other cards (7-Day, Banner, Recap, etc.)
- **Takeaway:** When adding new cards, use existing cards as reference implementation

**Lesson 4: ZStack Overlay Pattern for Hide Buttons**
- VStack with eye.slash creates extra vertical space
- **Fix:** Use ZStack with `.topTrailing` alignment for clean overlay
- **Takeaway:** ZStack overlay pattern prevents layout inflation

### 📊 QA Results (Coach Bar)
| Criteria | Status | Notes |
|----------|--------|-------|
| Visual Prominence | ✅ PASS | Accent background stands out perfectly |
| Font Size (21pt) | ✅ PASS | Legible and balanced |
| Padding | ✅ PASS | Restored to original design |
| Subtitle Visibility | ✅ PASS | White text excellent on gradient |
| Hide Functionality | ✅ PASS | eye.slash button works, 44×44pt |
| Restore Functionality | ✅ PASS | Control Center restore works |
| 60fps Performance | ✅ PASS | No jank or lag |
| Build Status | ✅ PASS | 0 errors, 0 warnings |

### ✅ COMPLETED (Phase v1.2b - Sticky Ownership Hooks)

**Date:** October 21, 2025
**Status:** ✅ BUILD SUCCEEDED | 0 errors, 0 warnings | Functionality verified

#### 1. Win Halo Animation (Section D.1)
**Goal:** Celebrate weight loss achievements with expanding glow animation.

**Implementation:**
- Outer glow expands from 1.0 → 1.12 scale over 0.9s
- Opacity fades from 1.0 → 0.0 simultaneously
- Only triggers when trend = improving (weight loss)
- Haptic `.light` feedback on trigger
- Respects Reduce Motion (skips animation when enabled)
- One-time animation per view appearance

**Files Modified:**
- `FastingTracker/UI/Components/WeightComponents.swift` (lines 1114-1116, 1230-1239, 1327-1336)

**Code Pattern:**
```swift
@State private var showWinHalo = false
@Environment(\.accessibilityReduceMotion) var reduceMotion

// In ZStack before background ring
if state == .improving && !reduceMotion {
    Circle()
        .stroke(accentColor.opacity(0.15), lineWidth: 8)
        .frame(width: 180, height: 180)
        .scaleEffect(showWinHalo ? 1.12 : 1.0)
        .opacity(showWinHalo ? 0.0 : 1.0)
        .animation(.easeOut(duration: 0.9), value: showWinHalo)
}

// In .onAppear
if state == .improving && !reduceMotion {
    showWinHalo = true
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
}
```

**Result:** ✅ Win moment animation provides positive reinforcement for weight loss

---

#### 2. Streak Badge System (Section D.2)
**Goal:** Celebrate new best streaks with badge dot and haptic feedback.

**Implementation:**
- Badge dot (8pt circle) appears when current streak > saved best
- Green color (`stateSuccess`) for positive reinforcement
- Spring animation (scale 0.5 → 1.0, opacity 0.0 → 1.0)
- Haptic `.success` feedback (stronger than `.light`)
- Persistent storage via `@AppStorage` prevents repeated triggers
- Changed flame icon from outline to `.fill` for visual strength

**Files Modified:**
- `FastingTracker/UI/Components/WeightComponents.swift` (lines 1425-1526)

**Code Pattern:**
```swift
@AppStorage("weight_tracker_best_streak") private var savedBestStreak: Int = 0
@State private var showNewBestBadge = false

private var isNewBest: Bool {
    return bestStreak > savedBestStreak && bestStreak > 0
}

// Badge dot overlay on flame icon
if isNewBest {
    Circle()
        .fill(Theme.ColorToken.stateSuccess)
        .frame(width: 8, height: 8)
        .offset(x: 6, y: -4)
        .opacity(showNewBestBadge ? 1.0 : 0.0)
        .scaleEffect(showNewBestBadge ? 1.0 : 0.5)
        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showNewBestBadge)
}

// In .onAppear
if isNewBest {
    savedBestStreak = bestStreak
    showNewBestBadge = true
    UINotificationFeedbackGenerator().notificationOccurred(.success)
}
```

**Result:** ✅ Badge celebrates new best streaks, persists across app launches

---

#### 3. Reflection Nudge Component (Section D.3)
**Goal:** Encourage micro-planning with random behavioral prompts.

**Implementation:**
- New card component below 30-day card
- Random selection from 3 prompts per spec D.3
- Sparkle icon + italic text for gentle tone
- Chevron disclosure indicator for tappability
- Tap triggers stub handler (medium haptic)
- Individual opt-out only (no master toggle)
- Ivory surface with 14pt corners, 1pt stroke, 6pt shadow

**Files Modified:**
- `FastingTracker/UI/Components/WeightComponents.swift` (lines 1528-1597, 768-793)

**Prompts:**
1. "One small habit to try this week?"
2. "What helped most on your best day?"
3. "Pick tomorrow's anchor: sleep / steps / water."

**Code Pattern:**
```swift
struct ReflectionNudge: View {
    let onHide: () -> Void
    let onTap: () -> Void

    private var reflectionPrompt: String {
        let prompts = [
            "One small habit to try this week?",
            "What helped most on your best day?",
            "Pick tomorrow's anchor: sleep / steps / water."
        ]
        return prompts.randomElement() ?? prompts[0]
    }
    // ... UI implementation
}
```

**Integration:**
- Positioned below 30-day card
- Staggered animation (0.35s delay)
- ContentOptOutManager for individual opt-out
- Category: `.behavioralNudges`

**Result:** ✅ Reflection prompts encourage micro-planning, tap stub ready for future Coach integration

---

### 📊 QA Results (Phase v1.2b)
| Criteria | Status | Notes |
|----------|--------|-------|
| Win Halo Animation | ✅ PASS | Triggers only on improving, 0.9s duration |
| Win Halo Reduce Motion | ✅ PASS | Skips animation when enabled |
| Win Halo Haptic | ✅ PASS | Light haptic on trigger |
| Streak Badge Logic | ✅ PASS | Shows only on NEW best streak |
| Streak Badge Persistence | ✅ PASS | @AppStorage prevents repeated triggers |
| Streak Badge Haptic | ✅ PASS | Success haptic on new best |
| Reflection Prompts | ✅ PASS | 3 prompts rotate randomly |
| Reflection Tappable | ✅ PASS | Tap stub works, medium haptic |
| Reflection Hide | ✅ PASS | eye.slash hides card, 44×44pt |
| Build Status | ✅ PASS | 0 errors, 0 warnings |

---

### ✅ COMPLETED (Phase v1.2c - Universal Standardization)

**Date:** October 21, 2025
**Status:** ✅ BUILD SUCCEEDED | 0 errors, 0 warnings | Functionality verified
**Goal:** Standardize card functionality and visual hierarchy per Universal Architecture pattern.
**Priority:** HIGH - Foundation for scaling across all 5 trackers

#### Implementation Summary

**1. Visual Hierarchy Standardization ✅**
- Changed Reflection Nudge surface from `surfaceIvory` → `surfaceIce`
- Coach Bar remains sole hero element (accent background)
- All other cards now use neutral surfaces (ice/mint pattern)
- Result: Clear visual hierarchy within 1-second scan

**2. Reflection Nudge Functional Standardization ✅**
- Added `.reflection` case to `ProgressStoryCardType` enum
- Upgraded to dual visibility system (ProgressStoryCardManager + ContentOptOutManager)
- Hide callback now uses `progressStoryCardManager.hideCard(.reflection)`
- Result: Control Center integration works perfectly (hide → restore functionality)

**Files Modified:**
- `FastingTracker/UI/Components/WeightComponents.swift` (line 1613, lines 768-790)
- `FastingTracker/WeightControlCenterView.swift` (lines 79-113)

**Key Changes:**
```swift
// Visual Hierarchy - Reflection Nudge surface
.fill(Theme.ColorToken.surfaceIce)  // Changed from surfaceIvory

// Functional Standardization - Dual manager pattern
if progressStoryCardManager.isCardVisible(.reflection) &&
   !optOutManager.isContentOptedOut(id: contentID_ReflectionNudge) {
    // ...
}

// Hide callback uses ProgressStoryCardManager
progressStoryCardManager.hideCard(.reflection)
```

**QA Results:**
| Criteria | Status | Notes |
|----------|--------|-------|
| Visual Hierarchy | ✅ PASS | Coach Bar hero, others background |
| Reflection Surface | ✅ PASS | surfaceIce matches surrounding cards |
| Dual Manager Check | ✅ PASS | Both managers checked correctly |
| Hide Functionality | ✅ PASS | eye.slash works, 44×44pt |
| Control Center Restore | ✅ PASS | "Show again" restores card |
| Build Status | ✅ PASS | 0 errors, 0 warnings |

---

### 🚧 PENDING (Phase v1.2d - Additional Enhancements)

**Goal:** User control over streak goals and card order customization.

**Priority:** MEDIUM/LOW - Nice-to-have features after core standardization

---

## K) Phase v1.2c Specifications (Universal Standardization) - COMPLETED

### 1. Visual Hierarchy Standardization

**Problem:**
Too many visual styles competing for attention. Users need one clear hero element, with all other cards acting as neutral background.

**Goal:**
Establish clear visual hierarchy where Coach Bar is the emotional anchor, and all other cards are standardized background elements.

**Specs:**

#### Coach Bar (HERO - Keep As-Is)
- ✅ Accent background (`accentInfo` royal blue gradient)
- ✅ White text for prominence
- ✅ Stands out as attention-grabber
- ✅ "Encouraging voice" - emotional anchor
- **Status:** Already implemented correctly, no changes needed

#### All Other Cards (BACKGROUND - Standardize)
- Consistent surface treatment (ice/mint pattern, NO ivory exceptions)
- Reduced visual competition
- Neutral, calm appearance
- Focus on content over chrome
- Maintain functionality, simplify styling

**Changes Required:**

1. **Reflection Nudge Surface**
   - **Current:** `surfaceIvory` (stands out too much)
   - **Target:** Match surrounding cards (ice/mint pattern)
   - **Reason:** Should be background, not competing hero element

2. **7-Day & 30-Day Cards**
   - **Current:** Already standardized (ice/mint surfaces)
   - **Target:** Keep as-is ✅
   - **Reason:** Correct background treatment

3. **Circular Trend Ring**
   - **Current:** State-based gradient colors (improving/regressing/stable)
   - **Target:** Keep as-is ✅
   - **Reason:** State communication is functional, not decorative

**Industry Pattern:**
- **Apple Health:** Hero stat card + neutral supporting cards
- **Strava:** Activity header (hero) + neutral activity cards below
- **Duolingo:** Daily goal (hero) + neutral streak/XP cards

**SwiftUI Implementation:**
```swift
// Reflection Nudge - Change surface to match other cards
.background(
    RoundedRectangle(cornerRadius: 14, style: .continuous)
        .fill(Theme.ColorToken.surfaceIce)  // Changed from surfaceIvory
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.ColorToken.strokeLight, lineWidth: 1)
        )
        .shadow(color: Theme.ColorToken.shadowCard, radius: 6, x: 0, y: 3)
)
```

**QA Criteria:**
- Coach Bar remains most prominent element
- Reflection Nudge blends with surrounding cards
- No competing visual styles
- Hierarchy clear within 1 second of viewing

---

### 2. Reflection Nudge Functional Standardization

**Problem:**
Reflection Nudge is a NEW card but doesn't follow standard card patterns:
- Uses ContentOptOutManager only (no ProgressStoryCardManager master toggle)
- Custom container instead of universal pattern
- Different surface treatment

**Goal:**
Standardize Reflection Nudge to match functional capabilities of other Progress Story cards.

**Specs:**

#### Dual Visibility System
**Pattern from 7-Day, 30-Day, Banner, Recap cards:**
```swift
// BOTH managers checked
if progressStoryCardManager.isCardVisible(.reflection) &&
   !optOutManager.isContentOptedOut(id: contentID_ReflectionNudge) {
    // Show card
}

// Hide callback uses ProgressStoryCardManager
progressStoryCardManager.hideCard(.reflection)
```

**Changes Required:**

1. **Add `.reflection` case to ProgressStoryCardType enum**
   - Location: `FastingTracker/Core/Managers/ProgressStoryCardManager.swift`
   - Enables master toggle in Control Center

2. **Update visibility check in WeightTrendsView**
   - Add dual manager check (currently only checks ContentOptOutManager)
   - Matches pattern used by all other cards

3. **Update hide callback**
   - Use `progressStoryCardManager.hideCard(.reflection)`
   - Enables "Show again" in Control Center

4. **Keep existing features:**
   - ✅ Random prompts
   - ✅ Tap stub for future Coach integration
   - ✅ eye.slash hide button
   - ✅ Staggered animation
   - ✅ Accessibility labels

**Industry Pattern:**
- **iOS Home Screen:** All widgets have universal remove/add capability
- **Apple Health:** All cards share same show/hide pattern
- **Spotify:** All playlist cards have consistent controls

**SwiftUI Implementation:**
```swift
// Updated visibility check
if progressStoryCardManager.isCardVisible(.reflection) &&
   !optOutManager.isContentOptedOut(id: contentID_ReflectionNudge) {
    ReflectionNudge(
        onHide: {
            withAnimation(.easeInOut(duration: 0.25)) {
                // Use ProgressStoryCardManager (master toggle)
                progressStoryCardManager.hideCard(.reflection)
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        },
        onTap: { /* ... */ }
    )
}
```

**QA Criteria:**
- Hide button works (eye.slash)
- Control Center shows "Reflection Prompts" in hidden cards list
- "Show again" restores card
- Behavior matches 7-Day, 30-Day, Banner, Recap cards

---

### 3. Movable/Reorderable Cards (DSCard Layer 5)

**Problem:**
Users cannot customize card order. Fixed order doesn't match individual preferences.

**Goal:**
Activate DSCard Layer 5 (`canReorder`) to enable drag-to-reorder functionality.

**Current Architecture:**
```swift
// DSCard.swift - Lines 83-84
canExpand: Bool = false,  // Layer 4: Not yet implemented
canReorder: Bool = false,  // Layer 5: Not yet implemented
```

**Specs:**

#### Universal Container Approach (DO NOT REBUILD)
- ✅ DSCard already has `canReorder: Bool` parameter
- ✅ DSCardHeader will provide drag handles (line 19 comment)
- 🔜 Activate existing architecture, don't create custom solution
- 🔜 One implementation used everywhere (universal pattern)

#### Drag Handle Design
**Per Apple HIG:**
- SF Symbol: `line.3.horizontal` (standard drag handle)
- Position: Left side of card header (before title)
- Size: 20pt icon
- Color: `textTertiary` (subtle, not competing with content)
- Touch area: 44×44pt minimum
- Haptic: `.medium` feedback on drag start/end

#### Reorder Persistence
```swift
// Store card order in UserDefaults
@AppStorage("progress_story_card_order") private var cardOrder: [String] = [
    "coachBar",
    "7day",
    "30day",
    "banner",
    "reflection",
    "recap"
]
```

#### SwiftUI Implementation
```swift
// Enable reorder for cards (NOT Coach Bar - it stays at top)
DSCard(
    cardType: .sevenDay,
    canReorder: true,  // Activate Layer 5
    content: { /* ... */ }
)

// Coach Bar stays fixed at top (canReorder: false)
```

**Industry Patterns:**

1. **iOS Home Screen** (Gold Standard):
   - Long press → wiggle mode → drag to reorder
   - Haptic feedback on pickup and drop
   - Visual indication (wiggle animation on Reduce Motion OFF)

2. **Apple Health - Summary Tab**:
   - Edit button → reorder mode
   - Drag handles appear on left
   - Order persists across app launches

3. **Spotify - Playlist Edit**:
   - Edit mode reveals drag handles
   - Drag to reorder tracks
   - Changes save automatically

**Recommended Approach:**
Follow **Apple Health pattern** (simpler than iOS wiggle mode):
- Edit button in Progress Story header (next to Done button)
- Tap Edit → drag handles appear
- Drag cards to reorder
- Tap Done → save order
- Order persists via @AppStorage

**Phase Strategy:**
This is **Layer 5** (comes after Layer 4 expand/collapse). Since Layer 4 is not yet implemented, consider:
- **Option A:** Skip Layer 4, implement Layer 5 first (if more valuable)
- **Option B:** Implement Layer 4 first, then Layer 5 (as designed)
- **Recommendation:** Confirm with user which is priority

**QA Criteria:**
- Edit button reveals drag handles
- Cards reorder smoothly (no jank)
- Order persists across app launches
- Coach Bar stays fixed at top (not reorderable)
- Haptic feedback on drag start/end
- 44×44pt touch targets
- Works across all 5 trackers

---

### 4. Streak Goals User Control

**Problem:**
Streak goals are hardcoded. Users have different targets and motivations.

**Goal:**
Allow users to set custom streak goals in Control Center, following industry patterns.

**Current Behavior:**
- App tracks current streak automatically
- Badge appears when current streak > saved best streak
- No user-defined goals (only compares to personal best)

**Target Behavior:**
- Users set their own streak goals (7-day, 30-day, etc.)
- Badge/celebration when goal is reached or beaten
- Goals stored in UserDefaults, editable in Control Center

**Specs:**

#### Control Center Integration

**Option A: Dedicated Goals Card** (Recommended)
```
┌─────────────────────────────────────┐
│ Goals & Streaks                  ⓘ  │
├─────────────────────────────────────┤
│ Current Streak: 12 days              │
│ Best Streak: 18 days                 │
│                                      │
│ Streak Goals:                        │
│   ┌─────────────────┐                │
│   │ 7-day streak  ✓ │ (achieved)    │
│   │ 14-day streak   │ (2 days to go)│
│   │ 30-day streak   │ (18 days to go)│
│   └─────────────────┘                │
│                                      │
│ [Customize Goals]                    │
└─────────────────────────────────────┘
```

**Option B: Settings Section**
Add to existing "Your LIFe Journey Settings" section:
```
Journey Visibility
  ├─ Show Coach Bar          [toggle]
  ├─ Show 7-Day Card         [toggle]
  ├─ Show 30-Day Card        [toggle]
  └─ ... etc

Streak Goals
  ├─ 7-Day Goal              [stepper: 7 days]
  ├─ 14-Day Goal             [stepper: 14 days]
  └─ 30-Day Goal             [stepper: 30 days]
```

**Recommendation:** Option B (simpler, uses existing Settings section)

#### Goal Storage
```swift
@AppStorage("weight_streak_goal_7day") private var goal7Day: Int = 7
@AppStorage("weight_streak_goal_14day") private var goal14Day: Int = 14
@AppStorage("weight_streak_goal_30day") private var goal30Day: Int = 30
```

#### Goal Achievement Celebration
```swift
// Check if any goal was just achieved
func checkGoalAchievement(currentStreak: Int) {
    if currentStreak == goal7Day && !achieved7Day {
        // Show celebration (badge dot + haptic .success)
        achieved7Day = true
    }
    if currentStreak == goal14Day && !achieved14Day {
        // Show celebration
        achieved14Day = true
    }
    // ... etc
}
```

**Industry Patterns:**

1. **Apple Fitness+ - Move Goals**:
   - Users set daily calorie goal
   - Rings show progress toward goal
   - Celebration when goal is reached
   - Edit goal in Settings

2. **Strava - Challenges**:
   - Users join challenges (weekly, monthly)
   - Progress tracked toward goal
   - Badge awarded on completion
   - Self-set goals + platform challenges

3. **Duolingo - Daily Goal**:
   - Users set XP goal (Casual/Regular/Serious/Intense)
   - Progress bar shows daily progress
   - Celebration when goal is reached
   - Edit goal in Profile settings

**SwiftUI Implementation:**
```swift
// In Control Center Settings
Section(header: Text("Streak Goals")) {
    Stepper("7-Day Goal: \(goal7Day) days", value: $goal7Day, in: 1...100)
    Stepper("14-Day Goal: \(goal14Day) days", value: $goal14Day, in: 1...100)
    Stepper("30-Day Goal: \(goal30Day) days", value: $goal30Day, in: 1...100)
}
.font(.system(size: 15))
.foregroundColor(Theme.ColorToken.textPrimary)
```

**Badge Logic Update:**
```swift
// Current: Badge shows on new BEST streak
private var isNewBest: Bool {
    return bestStreak > savedBestStreak && bestStreak > 0
}

// Future: ALSO show when goal is achieved
private var hasAchievedGoal: Bool {
    return currentStreak >= goal7Day ||
           currentStreak >= goal14Day ||
           currentStreak >= goal30Day
}

private var shouldShowBadge: Bool {
    return isNewBest || hasAchievedGoal
}
```

**QA Criteria:**
- Users can edit streak goals in Control Center
- Goals persist across app launches
- Badge appears when goal is reached
- Success haptic on goal achievement
- Default goals: 7, 14, 30 days
- Goals editable from 1-100 days (reasonable range)

---

### 📋 Phase v1.2c Implementation Checklist

**1. Visual Hierarchy (Est: 15 min)**
- [ ] Change Reflection Nudge surface from `surfaceIvory` → `surfaceIce`
- [ ] Verify Coach Bar remains most prominent element
- [ ] Test visual hierarchy (1-second scan test)

**2. Reflection Nudge Standardization (Est: 30 min)**
- [ ] Add `.reflection` case to ProgressStoryCardType enum
- [ ] Update visibility check to dual manager pattern
- [ ] Update hide callback to use ProgressStoryCardManager
- [ ] Verify Control Center integration (hide → show again)

**3. Movable Cards - Layer 5 (Est: 2-3 hours)**
- [ ] **Confirm priority:** Layer 4 (expand) vs Layer 5 (reorder) first?
- [ ] Add Edit button to Progress Story header
- [ ] Implement drag handles in DSCardHeader
- [ ] Add card order persistence (@AppStorage)
- [ ] Implement drag-to-reorder logic
- [ ] Lock Coach Bar at top (not reorderable)
- [ ] Test across all 5 trackers

**4. Streak Goals Control (Est: 1-2 hours)**
- [ ] Add Streak Goals section to Control Center
- [ ] Implement goal storage (@AppStorage)
- [ ] Add goal achievement detection logic
- [ ] Update badge logic (new best OR goal achieved)
- [ ] Add goal celebration (haptic + visual)
- [ ] Test edge cases (changing goals, multiple achievements)

**Total Estimate:** 4-6 hours development time

---

### 🎯 Priority Order (Recommended)

**HIGH Priority (Do First):**
1. Visual Hierarchy (15 min) - Quick win, big UX impact
2. Reflection Nudge Standardization (30 min) - Foundation compliance

**MEDIUM Priority (Do Next):**
3. Streak Goals Control (1-2 hours) - High user value, moderate complexity

**LOW Priority (Future Phase):**
4. Movable Cards Layer 5 (2-3 hours) - Nice-to-have, complex implementation

**Rationale:**
- Visual hierarchy fixes immediate "too busy" problem
- Functional standardization ensures consistent patterns
- Streak goals add user value without high complexity
- Movable cards can wait for proper Layer 4+5 rollout

---

**Strategy Reminders:**
- ✅ Simple method first, one layer at a time
- ✅ Use existing DSCard architecture (don't rebuild)
- ✅ Follow industry leaders (Apple Health, Strava, iOS patterns)
- ✅ Confirm before implementing (this doc = confirmation step)
- ✅ Review handoff docs for pitfalls
- ✅ Never change working code

---

**Implementation Status:** 60% Complete (Coach Bar ✅ | Win Halo ✅ | Streak Badge ✅ | Reflection ✅ | Standardization 🚧)
