# Universal Standardization Architecture

## 🎯 CORE MANDATE

**"Use the same standardized approach with everything we do going forward!"**

This document defines the UNIVERSAL architecture pattern for ALL features, components, and functionality in FastLIFe app. Every new feature must follow this pattern. No exceptions.

---

## 📐 THE TWO-LEVEL ARCHITECTURE

### **Level 1: Universal Containers (IDENTICAL everywhere)**

**Rule**: Container = Behavior/Chrome/Layout (Same for all instances)

**Examples**:
- **DSCard**: All tracker cards use this container
  - Provides: Padding, background, shadow, corners, header, eye-slash, expand/collapse, reorder
  - Same code whether it's Weight, Fasting, Hydration, Sleep, or Mood tracker

- **DSButton**: All buttons use this container
  - Provides: Styling, haptics, loading states, disabled states
  - Same code for "Add Weight", "Start Fast", "Log Water", etc.

- **DSTextField**: All text inputs use this container
  - Provides: Styling, validation, error states, keyboard types
  - Same code for weight input, water amount, mood notes, etc.

### **Level 2: Custom Content (UNIQUE per use case)**

**Rule**: Content = Data/Logic/Presentation (Custom per feature)

**Examples**:
- **CurrentWeightCard**: Shows weight number, motivation banner, goal badge
- **MilestoneRingCard**: Shows circular progress ring, milestone dots
- **WeightChartView**: Shows line chart with weight trend data
- **FastingTimer**: Shows countdown timer, fasting stage
- **HydrationGoal**: Shows water glasses filled today

### **Level 3: Reusable Components (STANDARDIZED building blocks)**

**Rule**: Components = UI elements used across multiple custom contents

**Examples**:
- **DSProgressRing**: Circular progress indicator → Used in Milestone Card, Fasting Timer, Hydration Goal
- **DSStatDisplay**: Number + label pair → Used in Stats Card, Summary views
- **DSBadge**: Pill-shaped label → Used for goals, achievements, tags
- **DSBanner**: Message banner → Used for motivation, tips, alerts
- **DSChartElement**: Axis, grid, data points → Used in all chart views

---

## 🏗️ ARCHITECTURE PATTERN

```
┌──────────────────────────────────────────────────────────┐
│ LEVEL 1: UNIVERSAL CONTAINER                             │
│ (Same code everywhere)                                   │
│                                                          │
│ DSCard / DSButton / DSTextField / etc.                  │
│ ├─ Styling (colors, fonts, spacing)                     │
│ ├─ Behaviors (haptics, animations, states)              │
│ └─ Layout (padding, alignment, sizing)                  │
│                                                          │
│   ┌──────────────────────────────────────────────────┐  │
│   │ LEVEL 2: CUSTOM CONTENT                          │  │
│   │ (Unique per feature)                             │  │
│   │                                                  │  │
│   │ CurrentWeightCard / FastingTimer / etc.         │  │
│   │ ├─ Business logic (calculations, state)         │  │
│   │ ├─ Data presentation (what to show)             │  │
│   │ └─ Feature-specific layout                      │  │
│   │                                                  │  │
│   │   Uses LEVEL 3: REUSABLE COMPONENTS:            │  │
│   │   ├─ DSProgressRing                             │  │
│   │   ├─ DSStatDisplay                              │  │
│   │   ├─ DSBadge                                    │  │
│   │   ├─ DSBanner                                   │  │
│   │   └─ DSChartElement                             │  │
│   └──────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

---

## 📋 UNIVERSAL DESIGN SYSTEM STRUCTURE

```
Core/DesignSystem/
├── Tokens/
│   ├── DSSpacing.swift          ✅ All spacing values (SINGLE SOURCE OF TRUTH)
│   ├── DSColors.swift           ✅ All color tokens (SINGLE SOURCE OF TRUTH)
│   ├── DSTypography.swift       ✅ All text styles (SINGLE SOURCE OF TRUTH)
│   └── DSAnimation.swift        🔜 All animation curves/timings
│
├── Containers/ (Level 1 - Universal)
│   ├── DSCard.swift             ✅ Universal card container
│   ├── DSCardHeader.swift       ✅ Card header with controls
│   ├── DSButton.swift           🔜 Universal button
│   ├── DSTextField.swift        🔜 Universal text input
│   └── DSSheet.swift            🔜 Universal modal sheet
│
├── Components/ (Level 3 - Reusable)
│   ├── DSProgressRing.swift     ✅ Circular/linear progress (Phase v1.2d)
│   ├── DSBanner.swift           ✅ Message banner (Phase v1.2e)
│   ├── DSStatDisplay.swift      🔜 Number + label display
│   ├── DSBadge.swift            🔜 Pill-shaped label
│   ├── DSChartElement.swift     🔜 Chart building blocks
│   ├── DSMilestoneDots.swift    🔜 Milestone progress dots
│   ├── DSEmptyState.swift       🔜 Empty state view
│   └── DSLoadingState.swift     🔜 Loading spinner
│
└── Utilities/
    ├── DSHaptics.swift          🔜 Haptic feedback patterns
    ├── DSFormatter.swift        🔜 Number/date formatting
    ├── DSValidator.swift        🔜 Input validation
    └── DSAccessibility.swift    🔜 VoiceOver labels
```

---

## 🎯 RULES FOR ALL FUTURE DEVELOPMENT

### **Rule 1: Container Uniformity**
✅ **DO**: All instances of the same type use the SAME universal container
❌ **DON'T**: Create custom containers for specific use cases

**Example**:
```swift
// ✅ CORRECT: All cards use DSCard
DSCard(cardType: .currentWeight, cardManager: cardManager) { ... }
DSCard(cardType: .milestone, cardManager: cardManager) { ... }
DSCard(cardType: .chart, cardManager: cardManager) { ... }

// ❌ WRONG: Custom container per card
CustomWeightCardWrapper { ... }
MilestoneCardContainer { ... }
ChartCardBox { ... }
```

### **Rule 2: Content Flexibility**
✅ **DO**: Custom content components for unique features
❌ **DON'T**: Try to force all content to look identical

**Example**:
```swift
// ✅ CORRECT: Each card has unique content
DSCard(cardType: .currentWeight) {
    CurrentWeightCard(...)  // Shows weight number + motivation
}

DSCard(cardType: .chart) {
    WeightChartView(...)  // Shows line chart
}

// ❌ WRONG: Generic content that doesn't fit use case
DSCard(cardType: .currentWeight) {
    GenericDataDisplay(...)  // Too generic, loses feature value
}
```

### **Rule 3: Component Extraction**
✅ **DO**: Extract reusable components when you see duplication (3+ uses)
❌ **DON'T**: Duplicate UI code across files

**Example**:
```swift
// ❌ WRONG: Duplicated progress ring code in 3 files
// CurrentWeightCard.swift - lines 252-291 (circular progress ring)
// MilestoneRingCard.swift - lines 45-78 (circular progress ring)
// FastingTimer.swift - lines 120-155 (circular progress ring)

// ✅ CORRECT: Extract to DSProgressRing component
DSProgressRing(
    percentage: 0.65,
    strokeWidth: 12,
    colors: [DSColors.accentPrimary, DSColors.accentSuccess]
)
// Now used in all 3 places
```

### **Rule 4: Design Token Usage**
✅ **DO**: Use design tokens (DSSpacing, DSColors, DSTypography) for ALL styling
❌ **DON'T**: Hardcode values in components

**Example**:
```swift
// ✅ CORRECT: Design tokens
.padding(DSSpacing.cardPadding)
.foregroundColor(DSColors.textPrimary)
.font(DSTypography.cardTitle)

// ❌ WRONG: Hardcoded values
.padding(16)
.foregroundColor(Color(red: 0.05, green: 0.1, blue: 0.16))
.font(.system(size: 16, weight: .semibold))
```

### **Rule 5: Single Source of Truth**
✅ **DO**: Central manager for all state (TrackerCardManager, WeightManager, etc.)
❌ **DON'T**: Scattered @State variables and UserDefaults keys

**Example**:
```swift
// ✅ CORRECT: Centralized visibility management
if cardManager.isCardVisible(.milestone) { ... }

// ❌ WRONG: Custom state per card
@State private var showMilestoneCard = false
@State private var showChartCard = true
@State private var showStatsCard = false
```

---

## 🚀 MIGRATION STRATEGY

### **Phase 1: Cards (Current Week)**
- [x] Current Weight Card → DSCard ✅ DONE
- [ ] Milestone Card → DSCard (NEXT)
- [ ] Chart Card → DSCard
- [ ] Stats Card → DSCard
- [ ] History Card → DSCard

### **Phase 2: Component Extraction**
Extract reusable components as we encounter duplication:
- [x] CircularProgressRing → DSProgressRing ✅ DONE (Phase v1.2d)
- [x] MotivationBanner → DSBanner ✅ DONE (Phase v1.2e)
- [ ] GoalBadge → DSBadge
- [ ] Stat displays → DSStatDisplay
- [ ] Milestone dots → DSMilestoneDots

### **Phase 3: Universal Containers**
Build remaining universal containers:
- [ ] DSButton (all buttons)
- [ ] DSTextField (all inputs)
- [ ] DSSheet (all modals)

### **Phase 4: Behavioral Systems**
Add automatic behaviors:
- [ ] DSHaptics (auto haptic feedback)
- [ ] DSAnimation (consistent transitions)
- [ ] DSAccessibility (VoiceOver labels)

### **Phase 5: Apply to All Trackers**
Replicate pattern across all 5 trackers:
- [ ] Weight Tracker (in progress)
- [ ] Fasting Tracker
- [ ] Hydration Tracker
- [ ] Sleep Tracker
- [ ] Mood Tracker

---

## 📊 SUCCESS METRICS

### **Code Quality**:
- ✅ Every UI element uses a Design System component
- ✅ Zero hardcoded spacing/colors/fonts in feature code
- ✅ No duplicated UI code (DRY principle)

### **Consistency**:
- ✅ All cards use DSCard container
- ✅ All buttons use DSButton container
- ✅ All inputs use DSTextField container
- ✅ All charts use DSChartElement building blocks

### **Maintainability**:
- ✅ Change design token → All instances update automatically
- ✅ Fix bug in component → All usages benefit
- ✅ Add new feature → Compose existing components

### **Developer Experience**:
- ✅ New developer understands patterns quickly
- ✅ Adding new card takes 10 minutes (just wrap in DSCard)
- ✅ No need to ask "how do I style this?" (use DS components)

---

## 🎓 LEARNING FROM INDUSTRY LEADERS

### **Apple Health**:
- Universal card containers with custom content
- Consistent padding, shadows, corners across all cards
- Reusable components (stat displays, progress rings, badges)

### **Spotify**:
- Universal list items with custom content
- Consistent typography scale across all text
- Reusable components (play buttons, album art, badges)

### **Airbnb**:
- Universal listing cards with custom content
- Design token system for colors/spacing/typography
- Reusable components (image carousels, rating stars, badges)

### **What We Learn**:
1. **Containers are uniform** (same shell everywhere)
2. **Content is flexible** (unique per feature)
3. **Components are reusable** (building blocks)
4. **Tokens are centralized** (single source of truth)

---

## 📝 DEVELOPMENT WORKFLOW

### **When Adding New Feature**:

1. **Identify the container**: Card? Button? Input field? Sheet?
2. **Use universal container**: `DSCard`, `DSButton`, `DSTextField`, etc.
3. **Create custom content**: Build feature-specific logic/presentation
4. **Compose reusable components**: Use `DSProgressRing`, `DSBadge`, etc.
5. **Use design tokens**: `DSSpacing`, `DSColors`, `DSTypography` for all styling
6. **Test across trackers**: Does pattern work for Weight, Fasting, Hydration?

### **When Refactoring Existing Code**:

1. **Identify duplication**: Same UI code in 2+ files?
2. **Extract to component**: Create `DSComponent` in Design System
3. **Replace all instances**: Update all files to use new component
4. **Test thoroughly**: Verify all instances work correctly
5. **Document pattern**: Update this file with learnings

---

## 🔒 MANDATES (NEVER VIOLATE)

### **1. Simple Method First**
- Start with simplest solution
- Add complexity only when needed
- One layer at a time

### **2. Follow Industry Leaders**
- Apple Health, Spotify, Airbnb patterns
- Official tech stack documentation (Apple HIG, SwiftUI docs)
- Design token systems (Figma, Material Design)

### **3. Never Change Working Code**
- If feature works, don't refactor until necessary
- Only extract to component when duplication appears
- Test exhaustively after any changes

### **4. Confirm, Don't Assume**
- Review handoff.md docs for pitfalls
- Ask user before major architectural decisions
- Document all patterns in this file

### **5. Build for Scaling**
- All features must work across 5 trackers
- Single source of truth for all styling
- Easy troubleshooting (one place to fix bugs)

### **6. Clean, Uniform, Luxurious**
- Consistent visual experience everywhere
- No visual inconsistencies (padding, colors, fonts)
- Luxury feel maintained across all features

---

## 🎯 CURRENT STATUS

### **Completed**:
- [x] Design System foundation (DSSpacing, DSColors, DSTypography)
- [x] DSCard universal container
- [x] DSCardHeader component
- [x] TrackerCardManager centralized state
- [x] Current Weight Card migrated to DSCard ✅
- [x] DSProgressRing component (Phase v1.2d) ✅
- [x] DSBanner component (Phase v1.2e) ✅
- [x] CircularTrendRingCard refactored to use DSProgressRing ✅
- [x] MilestoneRingCard refactored to use DSProgressRing ✅
- [x] ProgressBanner, ReflectionNudge, RecapRow, DidYouKnowBanner refactored to use DSBanner ✅

### **In Progress**:
- [ ] Planning Phase v1.3 priorities (see STANDARDIZATION-ROADMAP-v1.3.md)

### **Next Up**:
- [ ] Chart Card → DSCard
- [ ] Stats Card → DSCard
- [ ] History Card → DSCard
- [ ] Extract reusable components (DSProgressRing, DSBanner, DSBadge)

---

## 📞 QUESTIONS BEFORE BUILDING

Before starting ANY new component/feature, ask:

1. **Is there a universal container for this?** (DSCard, DSButton, etc.)
   - Yes → Use it
   - No → Should we build one? (ask user if 3+ similar instances exist)

2. **Is this content unique or reusable?**
   - Unique → Custom content component
   - Reusable → Extract to DSComponent

3. **Does this follow the pattern?**
   - Universal container ✓
   - Custom content ✓
   - Design tokens ✓
   - Centralized state ✓

4. **Will this work across all 5 trackers?**
   - Yes → Proceed
   - No → Rethink approach

---

**Last Updated**: 2025-10-21 (Phase v1.2d + v1.2e completed)
**Status**: ACTIVE - All future development must follow this architecture
**Owner**: Rich Marin (Product Owner)
**Implementer**: Claude Code (AI Development Lead)

---

**END OF DOCUMENT**
