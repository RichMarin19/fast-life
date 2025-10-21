# ReadMeFirst: FastLIFe App - Developer Guide

**Last Updated**: 2025-10-21
**Version**: 1.3
**Status**: ACTIVE - All development must follow these standards

---

## 🎯 PURPOSE

This document is your **single source of truth** for:
- Where all universal/global settings code lives
- Standard Operating Procedures (S.O.P.) for development
- Industry patterns we follow
- How to add new features correctly

**Before writing ANY code, read this file.**

---

## 📋 MASTER GAMEPLAN: PHASE TRACKING

**CRITICAL RULE:** Always update this section BEFORE and AFTER any work.

### Current Phase: v1.3 (Standardization & Card Migration)

**Phase Versioning Rules:**
- ✅ Sequential only: v1.3a → v1.3b → v1.3c ... → v1.3z → v1.4a
- ❌ NEVER skip phases or jump versions
- ✅ Update this gameplan EVERY TIME a phase completes

---

### ✅ COMPLETED PHASES (v1.3 Series)

| Phase | Name | Status | Commit | Date |
|-------|------|--------|--------|------|
| v1.3 | DSCoachBar Extraction | ✅ DONE | `253ba5a` | Oct 21, 2025 |
| v1.3b | Milestone Card → DSCard | ✅ DONE | `b4f50c1` | Oct 21, 2025 |
| v1.3c | DSCard Surface Parameter | ✅ DONE | (in v1.3b) | Oct 21, 2025 |
| v1.3d | Ice Color (Progress Story) | ✅ DONE | `3b665d7` | Oct 21, 2025 |
| v1.3e | Ice Color (App-Wide) | ✅ DONE | `e135bfa` | Oct 21, 2025 |
| v1.3f | Chart Card → DSCard | ✅ DONE | `f700866` | Oct 21, 2025 |

---

### ⚠️ MISLABELED COMMITS (Fix in future)

| Commit | Wrong Label | Should Be | What It Contains |
|--------|-------------|-----------|------------------|
| `f700866` | "Phase v1.4" | v1.3f | Typography + Color Context System |

**Note:** This commit exists and is functional, but was incorrectly labeled. Work is complete, just needs proper phase number in documentation.

---

### 🔄 PENDING PHASES (v1.3 Series)

| Phase | Name | Priority | Est. Time | Status |
|-------|------|----------|-----------|--------|
| v1.3g | Stats Card → DSCard | MEDIUM | 1.5 hrs | ⏸️ PENDING |
| v1.3h | History Card → DSCard | MEDIUM | 1.5 hrs | ⏸️ PENDING |
| v1.3i | Current Weight Card → DSCard | MEDIUM | 1.5 hrs | ⏸️ PENDING |
| v1.3j | Typography Migration (Weight Tracker) | LOW | 3-4 hrs | ⏸️ PENDING |

---

### 📊 PHASE COMPLETION CHECKLIST (Use this for EVERY phase)

When starting a new phase:
- [ ] Read STANDARDIZATION-ROADMAP-v1.3.md to understand the task
- [ ] Update this MASTER GAMEPLAN with phase name and status = IN PROGRESS
- [ ] Create todo list with specific tasks
- [ ] Verify build succeeds before starting (0 errors baseline)

When completing a phase:
- [ ] Test build succeeds (0 errors, 0 warnings)
- [ ] Test functionality works (manual verification)
- [ ] Update STANDARDIZATION-ROADMAP-v1.3.md with results
- [ ] Update this MASTER GAMEPLAN with status = DONE and commit hash
- [ ] Create git commit with proper phase number (e.g., "Phase v1.3g: ...")
- [ ] Document what's next in this MASTER GAMEPLAN

---

### 🎯 WHAT TO DO NEXT

**Current Status:** Phase v1.3f COMPLETE ✅ (6 phases done)

**Next Recommended Action:** Phase v1.3g (Stats Card → DSCard)

**Before starting v1.3g:**
1. Update this MASTER GAMEPLAN with v1.3g status = IN PROGRESS
2. Read STANDARDIZATION-ROADMAP-v1.3.md section on Stats Card migration
3. Follow the Phase Completion Checklist above
4. Update this section when done

---

## 📂 PROJECT STRUCTURE

### Core Architecture Locations

```
FastingTracker/
├── Core/
│   ├── DesignSystem/           ⭐ ALL DESIGN SYSTEM CODE HERE
│   │   ├── DSCard.swift         → Universal card container
│   │   ├── DSCardHeader.swift   → Card header with controls
│   │   ├── DSProgressRing.swift → Circular progress rings
│   │   ├── DSBanner.swift       → Message banners
│   │   ├── DSCoachBar.swift     → Motivational headers
│   │   ├── DSSpacing.swift      → All spacing tokens
│   │   ├── DSTypography.swift   → All text styles
│   │   └── DSColors.swift       → All color tokens
│   │
│   └── Managers/               ⭐ ALL GLOBAL MANAGERS HERE
│       ├── WeightManager.swift
│       ├── FastingManager.swift
│       ├── HydrationManager.swift
│       ├── SleepManager.swift
│       ├── MoodManager.swift
│       ├── HealthKitManager.swift
│       └── NotificationManager.swift
│
├── Theme.swift                 ⭐ GLOBAL THEME TOKENS HERE
├── TrackerCardManager.swift    ⭐ CARD STATE MANAGEMENT HERE
├── ProgressStoryCardManager.swift
└── [Tracker Views]             → WeightTrackingView.swift, etc.
```

---

## 🎨 DESIGN SYSTEM: SINGLE SOURCE OF TRUTH

### Where Universal Settings Live

| What You Need | File Location | What It Does |
|---------------|---------------|--------------|
| **Spacing values** | `Core/DesignSystem/DSSpacing.swift` | All padding, margins, gaps |
| **Colors** | `Theme.swift` → `Theme.ColorToken` | All app colors (hex codes) |
| **Text styles** | `Core/DesignSystem/DSTypography.swift` | All font sizes/weights |
| **Card container** | `Core/DesignSystem/DSCard.swift` | Universal card wrapper |
| **Progress rings** | `Core/DesignSystem/DSProgressRing.swift` | Circular progress indicators |
| **Banners** | `Core/DesignSystem/DSBanner.swift` | Message/alert banners |
| **Coach bars** | `Core/DesignSystem/DSCoachBar.swift` | Motivational headers |
| **Card visibility** | `TrackerCardManager.swift` | Show/hide cards, reordering |
| **Data managers** | `Core/Managers/*.swift` | Weight, Fasting, Hydration, etc. |

---

## 📐 THE UNIVERSAL ARCHITECTURE PATTERN

### Three-Level System

```
┌─────────────────────────────────────────────────────────┐
│ LEVEL 1: UNIVERSAL CONTAINERS (Same everywhere)         │
│ ├─ DSCard         → All cards use this                 │
│ ├─ DSButton       → All buttons use this (future)      │
│ └─ DSTextField    → All text inputs use this (future)  │
└─────────────────────────────────────────────────────────┘
           │
           ├─ Wraps ↓
           │
┌─────────────────────────────────────────────────────────┐
│ LEVEL 2: CUSTOM CONTENT (Unique per feature)           │
│ ├─ CurrentWeightCard   → Weight number + motivation    │
│ ├─ MilestoneRingCard   → Progress ring + milestones    │
│ ├─ WeightChartView     → Line chart                    │
│ └─ FastingTimer        → Countdown timer               │
└─────────────────────────────────────────────────────────┘
           │
           ├─ Uses ↓
           │
┌─────────────────────────────────────────────────────────┐
│ LEVEL 3: REUSABLE COMPONENTS (Building blocks)         │
│ ├─ DSProgressRing  → Used in multiple cards            │
│ ├─ DSBanner        → Used in multiple views            │
│ ├─ DSCoachBar      → Used in multiple trackers         │
│ └─ DSBadge         → Used everywhere (future)          │
└─────────────────────────────────────────────────────────┘
```

---

## 🛠️ STANDARD OPERATING PROCEDURES (S.O.P.)

### How to Add a New Card

**Example**: Adding "Sleep Quality Card" to Sleep Tracker

1. **Define card type** in `TrackerCardType` enum (if needed)
   ```swift
   // In TrackerCardManager.swift
   enum TrackerCardType: String, CaseIterable, Codable {
       case sleepQuality
       // ...
   }
   ```

2. **Create custom content** (Level 2)
   ```swift
   // SleepQualityCard.swift
   struct SleepQualityCard: View {
       let sleepManager: SleepManager

       var body: some View {
           // PURE CONTENT - No .padding(), .background(), .shadow()
           // DSCard provides all styling
           VStack(spacing: DSSpacing.cardElementSpacing) {
               Text("Sleep Quality")
                   .font(DSTypography.displayM)
                   .foregroundColor(Theme.ColorToken.textPrimary)

               DSProgressRing(  // ← Use Level 3 component
                   progress: sleepManager.sleepQuality,
                   progressColor: Theme.ColorToken.accentPrimary
               )
           }
       }
   }
   ```

3. **Wrap in DSCard** (Level 1)
   ```swift
   // In SleepTrackingView.swift
   DSCard(
       cardType: .sleepQuality,
       cardManager: cardManager
   ) {
       SleepQualityCard(sleepManager: sleepManager)
   }
   ```

**DONE!** DSCard automatically provides:
- ✅ Standard padding (16pt)
- ✅ Background color (white)
- ✅ Corner radius (16pt)
- ✅ Shadow
- ✅ Eye-slash dismiss button
- ✅ Expand/collapse (if enabled)
- ✅ Drag-to-reorder (if enabled)

---

### How to Use Design Tokens

**NEVER hardcode values!** Always use design tokens.

#### Spacing

```swift
// ❌ WRONG
.padding(16)
VStack(spacing: 12) { ... }

// ✅ CORRECT
.padding(DSSpacing.cardPadding)
VStack(spacing: DSSpacing.cardElementSpacing) { ... }
```

**Available spacing tokens** (in `DSSpacing.swift`):
- `cardPadding` = 16pt
- `cardSectionSpacing` = 20pt
- `cardElementSpacing` = 12pt
- `cardSmallSpacing` = 8pt
- `cardExtraSmallSpacing` = 4pt
- `screenEdgePadding` = 20pt
- `cardVerticalSpacing` = 16pt

#### Colors

```swift
// ❌ WRONG
.foregroundColor(Color(red: 0.1, green: 0.7, blue: 0.6))
.background(Color(hex: "#1ABC9C"))

// ✅ CORRECT
.foregroundColor(Theme.ColorToken.accentPrimary)
.background(Theme.ColorToken.card)
```

**Available color tokens** (in `Theme.swift`):
- **Text**: `textPrimary`, `textSecondary`, `textOnDark`
- **Backgrounds**: `card`, `cardAlt`, `cardOnDark`, `bgDeepStart`, `bgDeepMid`, `bgDeepEnd`
- **Surfaces**: `surfaceIce`, `surfaceIvory`, `surfaceMint`
- **Accents**: `accentPrimary`, `accentGold`, `accentInfo`, `accentCoral`
- **States**: `stateSuccess`, `stateWarning`, `stateError`
- **UI Elements**: `dividerDark`, `dividerOnDark`, `shadowCard`, `shadowCardOnDark`

#### Typography

```swift
// ❌ WRONG
.font(.system(size: 48, weight: .bold))
Text("Title").font(.system(size: 16, weight: .semibold))

// ✅ CORRECT
.font(DSTypography.displayXL)
Text("Title").font(DSTypography.cardTitle)
```

**Available typography tokens** (in `DSTypography.swift`):
- **Display**: `displayXL` (48pt), `displayL` (36pt), `displayM` (24pt), `displayS` (20pt)
- **Card**: `cardTitle` (16pt), `cardSubtitle` (14pt), `cardBody` (15pt), `cardCaption` (13pt)
- **Stats**: `statValueLarge` (32pt), `statValueMedium` (24pt), `statValueSmall` (18pt), `statLabel` (12pt)
- **Buttons**: `buttonPrimary` (16pt), `buttonSecondary` (15pt)
- **Lists**: `listTitle` (16pt), `listSubtitle` (14pt), `listCaption` (12pt)

---

### How to Use Reusable Components (Level 3)

#### DSProgressRing - Circular Progress Indicator

```swift
// Simple usage
DSProgressRing(
    progress: 0.65,  // 0.0 - 1.0
    progressColor: Theme.ColorToken.accentPrimary
)

// Advanced usage
DSProgressRing(
    progress: 0.65,
    size: 200,  // diameter in points
    strokeWidth: 18,
    progressGradient: LinearGradient(
        colors: [Color(hex: "22D1A3"), Color(hex: "2B86C5")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    ),
    glowIntensity: 0.30,
    enableGlow: true,
    enableHalo: false
)
```

**When to use**: Weight milestones, fasting progress, hydration goals, sleep quality

#### DSBanner - Message/Alert Banners

```swift
DSBanner(
    text: "You're making great progress!",
    icon: "star.fill",
    backgroundColor: Theme.ColorToken.accentInfo,
    onDismiss: { /* handle dismiss */ }
)
```

**When to use**: Progress messages, tips, warnings, alerts

#### DSCoachBar - Motivational Headers

```swift
DSCoachBar(
    text: "Progress in motion — your consistency shows!",
    icon: "sparkles",
    backgroundColor: Theme.ColorToken.accentInfo,
    onHide: { /* handle hide */ }
)
```

**When to use**: Behavioral anchors, motivational messages, journey moments

---

### How to Manage Card Visibility

**All card visibility is managed by `TrackerCardManager.shared`**

```swift
// Check if card is visible
if cardManager.isCardVisible(.milestone) {
    // Show card
}

// Hide a card
cardManager.hideCard(.milestone)

// Show a card
cardManager.showCard(.milestone)

// Get all visible cards in order
let visibleCards = cardManager.getVisibleCardsInOrder()

// Reorder cards (drag-and-drop)
cardManager.reorderCards(from: sourceIndex, to: destinationIndex)

// Check expansion state
if cardManager.isCardExpanded(.chart) {
    // Card is expanded
}

// Toggle expansion
cardManager.toggleCardExpansion(.chart)
```

**IMPORTANT**: Never create custom `@State` variables for card visibility. Always use `TrackerCardManager`.

---

### How to Access Data Managers

**All tracker data is managed by singleton managers in `Core/Managers/`**

```swift
// Weight data
@ObservedObject private var weightManager = WeightManager.shared

// Fasting data
@ObservedObject private var fastingManager = FastingManager.shared

// Hydration data
@ObservedObject private var hydrationManager = HydrationManager.shared

// Sleep data
@ObservedObject private var sleepManager = SleepManager.shared

// Mood data
@ObservedObject private var moodManager = MoodManager.shared

// HealthKit integration
@ObservedObject private var healthKitManager = HealthKitManager.shared
```

**Usage example**:
```swift
struct WeightTrackingView: View {
    @EnvironmentObject var weightManager: WeightManager

    var body: some View {
        // Access weight data
        if let latestWeight = weightManager.latestWeight {
            Text("\(latestWeight.weight, specifier: "%.1f") lb")
        }
    }
}
```

---

## 🏆 INDUSTRY STANDARDS WE FOLLOW

### Apple HIG (Human Interface Guidelines)

**Reference**: https://developer.apple.com/design/human-interface-guidelines/

✅ **Minimum tap targets**: 44×44pt (defined in `Theme.TapTarget.minimum`)
✅ **Padding**: 16pt standard (8pt grid system)
✅ **Corner radius**: 16pt for cards, 12pt for chips, 8pt for buttons
✅ **Accessibility**: VoiceOver support, Reduce Motion respect, Dynamic Type
✅ **Color contrast**: WCAG AA compliant (4.5:1 minimum)

### Apple Health App Patterns

✅ **Card-based dashboard**: Scrollable vertical cards
✅ **Card visibility controls**: Eye-slash dismiss button
✅ **Drag-to-reorder**: Long-press and drag cards
✅ **Progress rings**: Circular indicators (like Activity Rings)
✅ **Motivational messaging**: Behavioral anchors and journey moments

### Spotify App Patterns

✅ **Consistent list items**: Universal container with custom content
✅ **Typography scale**: Hierarchical text styles
✅ **Reusable components**: Play buttons, badges, etc.

### Airbnb App Patterns

✅ **Design token system**: Centralized colors/spacing/typography
✅ **Component library**: Building blocks for features
✅ **Single source of truth**: One place to change styles globally

---

## 🚫 RULES (NEVER VIOLATE)

### Rule 1: Simple Method First
- ✅ Start with simplest solution
- ✅ Add complexity only when needed
- ✅ One layer at a time
- ❌ Don't over-engineer

### Rule 2: Follow Industry Leaders
- ✅ Apple HIG compliance
- ✅ SwiftUI best practices
- ✅ Design system patterns
- ❌ Don't invent custom patterns without reason

### Rule 3: Never Change Working Code
- ✅ If feature works, don't refactor until necessary
- ✅ Only extract components when duplication appears (3+ uses)
- ✅ Test exhaustively after any changes
- ❌ Don't refactor for the sake of refactoring

### Rule 4: Confirm, Don't Assume
- ✅ Review handoff docs for pitfalls
- ✅ Ask before major architectural decisions
- ✅ Document all patterns
- ❌ Don't assume you know the right approach

### Rule 5: Use Design Tokens
- ✅ All spacing from `DSSpacing`
- ✅ All colors from `Theme.ColorToken`
- ✅ All typography from `DSTypography`
- ❌ Never hardcode values in components

### Rule 6: Single Source of Truth
- ✅ Central manager for all state
- ✅ One place to change settings
- ✅ Easy troubleshooting
- ❌ No scattered @State variables

---

## 🎯 CODE EXAMPLES

### Example 1: Adding a New Card (Complete)

```swift
// 1. Define card type (if new)
enum TrackerCardType: String, CaseIterable, Codable {
    case currentWeight
    case milestone
    case chart
    case stats
    case myNewCard  // ← New card type
}

// 2. Create custom content (Level 2)
struct MyNewCard: View {
    @ObservedObject var weightManager: WeightManager

    var body: some View {
        // PURE CONTENT - No styling!
        VStack(spacing: DSSpacing.cardElementSpacing) {
            Text("My New Feature")
                .font(DSTypography.displayM)
                .foregroundColor(Theme.ColorToken.textPrimary)

            // Use Level 3 components
            DSProgressRing(
                progress: weightManager.progress,
                progressColor: Theme.ColorToken.accentPrimary
            )

            Text("Additional info")
                .font(DSTypography.cardBody)
                .foregroundColor(Theme.ColorToken.textSecondary)
        }
    }
}

// 3. Wrap in DSCard (Level 1)
// In WeightTrackingView.swift
DSCard(
    cardType: .myNewCard,
    title: "My New Feature",
    cardManager: cardManager
) {
    MyNewCard(weightManager: weightManager)
}
```

### Example 2: Using Design Tokens

```swift
// ❌ BEFORE (hardcoded values)
VStack(spacing: 12) {
    Text("Title")
        .font(.system(size: 48, weight: .bold))
        .foregroundColor(Color(hex: "#0E1B2A"))
        .padding(16)

    Text("Subtitle")
        .font(.system(size: 14, weight: .regular))
        .foregroundColor(Color(hex: "#475569"))
}

// ✅ AFTER (design tokens)
VStack(spacing: DSSpacing.cardElementSpacing) {
    Text("Title")
        .font(DSTypography.displayXL)
        .foregroundColor(Theme.ColorToken.textPrimary)
        .padding(DSSpacing.cardPadding)

    Text("Subtitle")
        .font(DSTypography.cardSubtitle)
        .foregroundColor(Theme.ColorToken.textSecondary)
}
```

### Example 3: Card Visibility Management

```swift
// ❌ BEFORE (scattered state)
@State private var showMilestoneCard = false
@State private var showChartCard = true
@State private var showStatsCard = false

// Save to UserDefaults manually
UserDefaults.standard.set(showMilestoneCard, forKey: "showMilestoneCard")

// ✅ AFTER (centralized manager)
@ObservedObject private var cardManager = TrackerCardManager.shared

// Check visibility
if cardManager.isCardVisible(.milestone) {
    DSCard(cardType: .milestone, cardManager: cardManager) { ... }
}

// Hide card (automatic persistence)
cardManager.hideCard(.milestone)
```

---

## 📚 LEARNING RESOURCES

### Essential Reading

1. **UNIVERSAL_STANDARDIZATION_ARCHITECTURE.md** - Core architecture pattern
2. **NORTH-STAR-STRATEGY.md** - Phase C strategy (visual polish)
3. **STANDARDIZATION-ROADMAP-v1.3.md** - Current roadmap priorities
4. **HANDOFF-PHASE-JOURNEY-v1.2.md** - Project history and context
5. **PROJECT-STATUS.md** - Current state verification

### Design System Documentation

- `Core/DesignSystem/DSCard.swift` - Card container pattern
- `Core/DesignSystem/DSProgressRing.swift` - Progress ring usage
- `Core/DesignSystem/DSBanner.swift` - Banner usage
- `Core/DesignSystem/DSCoachBar.swift` - Coach bar usage

### Apple Documentation

- [Apple HIG](https://developer.apple.com/design/human-interface-guidelines/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Accessibility Guidelines](https://developer.apple.com/accessibility/)

---

## 🔍 TROUBLESHOOTING

### "Where do I change X?"

| What to Change | File Location |
|----------------|---------------|
| Card padding | `DSSpacing.swift` → `cardPadding` |
| Text color | `Theme.swift` → `Theme.ColorToken.textPrimary` |
| Font size | `DSTypography.swift` → appropriate token |
| Card visibility | `TrackerCardManager.swift` → visibility methods |
| Weight data | `Core/Managers/WeightManager.swift` |
| HealthKit sync | `Core/Managers/HealthKitManager.swift` |

### "This card looks different from others"

**Check**:
1. Is it wrapped in `DSCard`? (should be!)
2. Does content have styling? (shouldn't have `.padding()`, `.background()`, `.shadow()`)
3. Are design tokens used? (no hardcoded values!)

### "I need to duplicate this code"

**STOP! Extract to Level 3 component instead:**
1. If code appears 3+ times → Create `DSComponent` in `Core/DesignSystem/`
2. Use design tokens for all styling
3. Document parameters clearly
4. Add preview for testing

---

## ✅ CHECKLIST BEFORE COMMITTING CODE

- [ ] All spacing uses `DSSpacing.*` tokens
- [ ] All colors use `Theme.ColorToken.*` tokens
- [ ] All typography uses `DSTypography.*` tokens
- [ ] All cards wrapped in `DSCard`
- [ ] No hardcoded values in components
- [ ] Card visibility uses `TrackerCardManager`
- [ ] Data access uses manager singletons
- [ ] Code follows three-level architecture
- [ ] No duplicated UI code
- [ ] Accessibility labels added
- [ ] Reduce Motion respected
- [ ] Preview added for SwiftUI views

---

## 🎓 QUICK START

**New to the project?**

1. Read this file (you're here!)
2. Read `UNIVERSAL_STANDARDIZATION_ARCHITECTURE.md`
3. Look at `WeightTrackingView.swift` (reference implementation)
4. Study `DSCard.swift` (universal container pattern)
5. Review `Theme.swift` (design tokens)
6. Follow the S.O.P. above when adding features

**Ready to code?**

- Always use design tokens
- Always wrap cards in `DSCard`
- Always use `TrackerCardManager` for visibility
- Always extract duplicated code to components
- Always test on device + simulator
- Always ask before major changes

---

## 📞 QUESTIONS?

**Before asking, check**:
1. Is it documented in this file?
2. Is there an example in the codebase?
3. Does Apple HIG cover it?

**Still stuck?**
- Review handoff docs (`HANDOFF*.md`)
- Check project status (`PROJECT-STATUS.md`)
- Review roadmap (`STANDARDIZATION-ROADMAP-v1.3.md`)

---

**Last Updated**: 2025-10-21
**Owner**: Rich Marin (Product Owner)
**Maintainer**: Claude Code (AI Development Lead)

**This is a living document. Update it when patterns change.**

---

**END OF GUIDE**
