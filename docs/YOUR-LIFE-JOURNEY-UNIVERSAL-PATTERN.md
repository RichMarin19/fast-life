# Your LIFe Journey - Universal Pattern Architecture

**Owner:** Rich Marin (Product Owner)
**Implementer:** Claude Code (AI Development Lead)
**Date:** October 21, 2025
**Status:** ACTIVE - Apply to ALL 5 trackers
**Purpose:** Define universal reusable pattern for "Your LIFe Journey" across all trackers

---

## 🎯 CORE MANDATE

**"Your LIFe Journey" will be used for EVERY tracker, adapted for each specific tracker type."**

This document defines the UNIVERSAL pattern for implementing "Your LIFe Journey" progress visualization across all 5 trackers:
- ✅ Weight Tracker (IMPLEMENTED - reference)
- 🔜 Fasting Tracker
- 🔜 Hydration Tracker
- 🔜 Sleep Tracker
- 🔜 Mood Tracker

---

## 📐 THE UNIVERSAL PATTERN

### **Core Philosophy**

"Your LIFe Journey" is a **behavioral progress narrative** that:
1. Visualizes trends over 7-day and 30-day periods
2. Adapts messaging based on trend state (improving/regressing/flat)
3. Provides motivational coaching, educational tips, and reflection prompts
4. Uses consistent luxury UI (adaptive mood gradients, circular rings, banners)
5. Respects user control (granular opt-out, master toggles)

### **Industry Standards**

Follows patterns from:
- **Apple Health:** Progress rings, trend cards, motivational messages
- **MyFitnessPal:** Behavioral coaching, educational tips, progress stories
- **Strava:** Adaptive messaging, celebration of wins, trend analysis

---

## 🏗️ ARCHITECTURE LAYERS

```
┌─────────────────────────────────────────────────────────┐
│ YOUR LIFE JOURNEY (Universal View Structure)           │
├─────────────────────────────────────────────────────────┤
│                                                         │
│ LAYER 1: ADAPTIVE BACKGROUND                           │
│ ├─ Deep navy gradient (3-stop) - base canvas          │
│ └─ Adaptive mood overlay (12-18% opacity)             │
│    └─ Changes color based on 7-day trend state        │
│                                                         │
│ LAYER 2: HEADER                                        │
│ ├─ Title: "Your LIFe Journey" (luxury gradient)       │
│ └─ Subtitle: Motivational tagline (tracker-specific)  │
│                                                         │
│ LAYER 3: COACH BAR (DSCoachBar)                       │
│ └─ State-driven micro-copy (improving/regressing/flat)│
│                                                         │
│ LAYER 4: STACKED CONTENT (Narrative Flow)             │
│ ├─ 7-Day Trend Ring (CircularTrendRingCard)          │
│ ├─ Motivational Banner (ProgressBanner + DSBanner)    │
│ ├─ 30-Day Trend Ring (CircularTrendRingCard)         │
│ ├─ Reflection Nudge (ReflectionNudge + DSBanner)      │
│ ├─ Recap Row (RecapRow + DSBanner)                    │
│ └─ Did You Know Banner (DidYouKnowBanner + DSBanner)  │
│                                                         │
│ LAYER 5: FOOTER                                        │
│ └─ Celebration message (optional, based on entries)   │
│                                                         │
│ LAYER 6: TOOLBAR                                       │
│ ├─ Left: "Don't show again" (luxury opt-out button)   │
│ └─ Right: "Done" button                               │
└─────────────────────────────────────────────────────────┘
```

---

## 📦 REUSABLE COMPONENTS (Design System)

### **Level 1: Universal Containers**
- `DSCard` - Universal card container (all cards)
- `DSBanner` - Universal banner container (motivational, educational, reflection)

### **Level 3: Reusable Building Blocks**
- `DSCoachBar` - Motivational header bar (accent background + white text + icon)
- `DSProgressRing` - Circular progress indicator (Apple Watch Activity Rings pattern)

### **Custom Journey Components (Reusable Across Trackers)**
- `CircularTrendRingCard` - 7d/30d trend visualization with circular ring
- `ProgressBanner` - Motivational message banner (state-driven text)
- `ReflectionNudge` - Behavioral prompt for micro-planning
- `RecapRow` - 3-metric summary row (Net Δ, Streak, Entries)
- `DidYouKnowBanner` - Educational tip banner
- `LightCard` - Light surface container (ice/ivory/mint) with hide button

---

## 🔄 TRACKER-SPECIFIC ADAPTATIONS

### **Weight Tracker (REFERENCE IMPLEMENTATION)**

**File:** `WeightComponents.swift` → `WeightTrendsView`

**Trend Metric:** Weight change (lbs)
**Trend States:**
- Improving: Δ < -0.2 (loss)
- Regressing: Δ > +0.2 (gain)
- Flat: |Δ| ≤ 0.2

**Subtitle:** "Progress you can feel — one choice at a time."

**Coach Bar Messages:**
- Improving: "Progress in motion — your consistency shows!"
- Regressing: "Weight gain is feedback, not failure — hydrate and sleep strong!"
- Flat: "Balance is mastery in motion — keep showing up!"

**Banner Messages:**
- Improving: "Small wins compound. Keep stacking the days!"
- Regressing: "Course‑correct today. One choice changes the trend!"
- Flat: "Consistency is power. Nudge your routine by 1%!"

**Recap Row Metrics:**
- Net Δ: 30-day weight change
- Best Streak: Days with entries
- Total Entries: Count

**Did You Know Tips:**
- "Drinking water before meals can reduce calorie intake."
- "Sleep loss increases hunger hormones; protect your 7–8 hours."
- "Protein at your first meal improves satiety for the day."
- "Consistent weigh-ins help track trends, not daily fluctuations."
- "Strength training preserves muscle during weight loss."

---

### **Fasting Tracker (TO BE IMPLEMENTED)**

**Trend Metric:** Fasting completion rate (%)
**Trend States:**
- Improving: Completion rate increasing
- Regressing: Completion rate decreasing
- Flat: Completion rate stable

**Subtitle:** "Every fast builds your metabolic strength — one window at a time."

**Coach Bar Messages:**
- Improving: "Your fasting rhythm is strong — metabolic magic in motion!"
- Regressing: "Missed fasts are feedback, not failure — start fresh today!"
- Flat: "Steady fasting = steady progress — you're building discipline!"

**Banner Messages:**
- Improving: "Consistency compounds. Keep honoring your fasting window!"
- Regressing: "Reset today. One clean fast changes the trend!"
- Flat: "Metabolic flexibility grows with every fast — keep showing up!"

**Recap Row Metrics:**
- Net Completion: 30-day completion rate
- Best Streak: Consecutive completed fasts
- Total Fasts: Count

**Did You Know Tips:**
- "16:8 fasting can improve insulin sensitivity over time."
- "Hydration during fasting helps reduce hunger signals."
- "Breaking your fast with protein stabilizes blood sugar."
- "Fasting windows longer than 12 hours activate autophagy."
- "Electrolytes (salt, potassium, magnesium) support longer fasts."

---

### **Hydration Tracker (TO BE IMPLEMENTED)**

**Trend Metric:** Daily water intake (oz)
**Trend States:**
- Improving: Intake increasing toward goal
- Regressing: Intake decreasing from goal
- Flat: Intake stable

**Subtitle:** "Every sip fuels your cells — one glass at a time."

**Coach Bar Messages:**
- Improving: "Hydration on point — your cells are thriving!"
- Regressing: "Dehydration is feedback, not failure — sip strong today!"
- Flat: "Steady hydration = steady energy — you're doing great!"

**Banner Messages:**
- Improving: "Hydration compounds. Keep filling those glasses!"
- Regressing: "Refill today. One glass changes the trend!"
- Flat: "Every sip counts. Keep your hydration steady!"

**Recap Row Metrics:**
- Net Intake: 30-day average intake
- Best Streak: Days hitting hydration goal
- Total Glasses: Count

**Did You Know Tips:**
- "Drinking water before meals can reduce calorie intake."
- "Mild dehydration (1-2%) impairs cognitive performance."
- "Hydration needs increase with exercise and hot weather."
- "Urine color (pale yellow) is a simple hydration check."
- "Electrolytes (sodium, potassium) help retain hydration."

---

### **Sleep Tracker (TO BE IMPLEMENTED)**

**Trend Metric:** Sleep quality/duration (hours)
**Trend States:**
- Improving: Quality/duration increasing
- Regressing: Quality/duration decreasing
- Flat: Quality/duration stable

**Subtitle:** "Every night builds your recovery — one rest at a time."

**Coach Bar Messages:**
- Improving: "Sleep quality rising — your recovery is strong!"
- Regressing: "Poor sleep is feedback, not failure — protect tonight!"
- Flat: "Steady sleep = steady performance — keep it up!"

**Banner Messages:**
- Improving: "Rest compounds. Keep honoring your sleep window!"
- Regressing: "Reset tonight. One good sleep changes the trend!"
- Flat: "Consistent sleep = consistent energy. You're on track!"

**Recap Row Metrics:**
- Net Quality: 30-day average sleep score
- Best Streak: Nights hitting sleep goal (7-8 hours)
- Total Nights: Count

**Did You Know Tips:**
- "7-8 hours of sleep optimizes cognitive and metabolic health."
- "Blue light before bed suppresses melatonin production."
- "Room temperature (65-68°F) supports deeper sleep."
- "Consistent sleep/wake times regulate circadian rhythm."
- "REM sleep (20-25% of total) is critical for memory."

---

### **Mood Tracker (TO BE IMPLEMENTED)**

**Trend Metric:** Mood stability score (1-10 scale)
**Trend States:**
- Improving: Stability increasing (less variance)
- Regressing: Stability decreasing (more variance)
- Flat: Stability steady

**Subtitle:** "Every check-in builds your awareness — one moment at a time."

**Coach Bar Messages:**
- Improving: "Mood stability rising — your awareness is growing!"
- Regressing: "Mood swings are feedback, not failure — breathe and reset!"
- Flat: "Steady mood = strong foundation — keep checking in!"

**Banner Messages:**
- Improving: "Awareness compounds. Keep tracking your emotional patterns!"
- Regressing: "Reset today. One mindful moment changes the trend!"
- Flat: "Emotional stability is strength. Keep showing up!"

**Recap Row Metrics:**
- Net Stability: 30-day mood stability score
- Best Streak: Days with mood check-ins
- Total Entries: Count

**Did You Know Tips:**
- "Daily mood tracking improves emotional awareness over time."
- "Sleep, hydration, and exercise directly impact mood stability."
- "Gratitude journaling (3 items daily) boosts mood."
- "Mood variance is normal; patterns reveal what to adjust."
- "Breathing exercises (4-7-8) calm the nervous system instantly."

---

## 🎨 VISUAL CONSISTENCY (All Trackers)

### **Adaptive Mood Overlay**

Changes color based on 7-day trend state:

**Improving (Teal → Blue):**
```swift
LinearGradient(
    colors: [
        Theme.ColorToken.moodImprovingStart.opacity(0.22),  // Teal
        Theme.ColorToken.moodImprovingEnd.opacity(0.16)     // Blue
    ],
    startPoint: .top,
    endPoint: .bottom
)
```

**Regressing (Coral → Peach):**
```swift
LinearGradient(
    colors: [
        Theme.ColorToken.moodRegressingStart.opacity(0.22),  // Coral
        Theme.ColorToken.moodRegressingEnd.opacity(0.16)     // Peach
    ],
    startPoint: .top,
    endPoint: .bottom
)
```

**Flat (Gold → Light Gold):**
```swift
LinearGradient(
    colors: [
        Theme.ColorToken.moodStableStart.opacity(0.18),  // Gold
        Theme.ColorToken.moodStableEnd.opacity(0.12)     // Light gold
    ],
    startPoint: .top,
    endPoint: .bottom
)
```

### **Circular Trend Ring Gradients**

**Improving (Teal → Blue):**
```swift
LinearGradient(
    colors: [Color(hex: "22D1A3"), Color(hex: "2B86C5")],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

**Regressing (Coral → Rose):**
```swift
LinearGradient(
    colors: [Color(hex: "E47A6E"), Color(hex: "D63A3A")],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

**Flat (Gold → Amber):**
```swift
LinearGradient(
    colors: [Color(hex: "EEC36A"), Color(hex: "DFA53F")],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

### **Typography Standards**

**Title:** "Your LIFe Journey"
- Font: SF Pro Rounded 34pt, weight .bold
- Gradient: Theme.ColorToken.accentInfo → accentPrimary
- Alignment: Center

**Subtitle:** Tracker-specific tagline
- Font: SF Pro Display 15pt, weight .regular, italic
- Color: .white
- Alignment: Center

**Coach Bar:**
- Font: SF Pro Rounded 21pt, weight .semibold
- Color: .white
- Icon: 18pt, weight .semibold

**Banner Text:**
- Font: SF Pro Rounded 18pt, weight .semibold
- Color: Theme.ColorToken.textPrimary (on white/mint/ice surfaces)

---

## 🔧 IMPLEMENTATION CHECKLIST

### **For Each Tracker:**

1. **Create Trend Logic**
   - [ ] Define trend metric (weight, fasting %, oz, hours, mood score)
   - [ ] Define trend states (improving/regressing/flat thresholds)
   - [ ] Implement `calculateDelta(days: Int)` function
   - [ ] Implement `trendState(for delta: Double)` function

2. **Create Adaptive Messaging**
   - [ ] Coach Bar messages (3: improving/regressing/flat)
   - [ ] Banner messages (3: improving/regressing/flat)
   - [ ] Did You Know tips (5-10 tracker-specific educational tips)
   - [ ] Subtitle tagline (tracker-specific motivational phrase)

3. **Create Recap Row Metrics**
   - [ ] Metric 1: Net delta (30-day trend)
   - [ ] Metric 2: Best streak (days/nights/fasts with goal met)
   - [ ] Metric 3: Total entries count

4. **Implement View Structure**
   - [ ] Adaptive background (navy gradient + mood overlay)
   - [ ] Header (title + subtitle)
   - [ ] Coach Bar (DSCoachBar with state-driven text)
   - [ ] 7-Day Trend Ring (CircularTrendRingCard)
   - [ ] Motivational Banner (ProgressBanner + DSBanner)
   - [ ] 30-Day Trend Ring (CircularTrendRingCard)
   - [ ] Reflection Nudge (ReflectionNudge + DSBanner)
   - [ ] Recap Row (RecapRow + DSBanner)
   - [ ] Did You Know Banner (DidYouKnowBanner + DSBanner)
   - [ ] Footer celebration message
   - [ ] Toolbar (opt-out button + done button)

5. **Implement Visibility System**
   - [ ] ContentOptOutManager integration (granular opt-out)
   - [ ] ProgressStoryCardManager integration (master toggles)
   - [ ] Content IDs for each card (tracker-specific prefixes)

6. **Implement Animations**
   - [ ] Staggered fade-in (0.4s delays: 0.05, 0.1, 0.2, 0.3, 0.35, 0.4, 0.5, 0.6)
   - [ ] Mood background micro-drift (5s ease-in-out repeat)
   - [ ] Ring sweep animation (1.2s ease-out)
   - [ ] Win halo animation (0.9s ease-out, improving state only)
   - [ ] Respect `reduceMotion` accessibility setting

7. **Test & Verify**
   - [ ] All 3 trend states render correctly (improving/regressing/flat)
   - [ ] Mood overlay adapts based on 7-day trend
   - [ ] Coach Bar messages adapt based on 7-day trend
   - [ ] Banner messages adapt based on 7-day trend
   - [ ] Recap Row calculates metrics correctly
   - [ ] Did You Know tips rotate randomly
   - [ ] Opt-out buttons work (individual + global)
   - [ ] Master toggles work (ProgressStoryCardManager)
   - [ ] Animations respect Reduce Motion
   - [ ] Build succeeds (0 errors, 0 warnings)

---

## 📊 SUCCESS METRICS

### **Per Tracker:**
- ✅ "Your LIFe Journey" implemented with universal pattern
- ✅ All reusable components used (DSCoachBar, DSBanner, DSProgressRing)
- ✅ Adaptive messaging adapts to 3 trend states
- ✅ Adaptive mood overlay changes based on 7-day trend
- ✅ Recap Row metrics calculate correctly
- ✅ Opt-out system works (individual + global)
- ✅ Build succeeds (0 errors, 0 warnings)

### **Overall:**
- ✅ 5 trackers share same "Your LIFe Journey" pattern
- ✅ Single source of truth for all components (Design System)
- ✅ Consistent luxury UI across all trackers
- ✅ Easy to add new tracker (just adapt messaging + metric)

---

## 🎓 LESSONS LEARNED (Weight Tracker Implementation)

### **What Worked Well:**
1. ✅ Adaptive mood overlay creates emotional connection
2. ✅ State-driven messaging (improving/regressing/flat) feels personalized
3. ✅ Circular progress rings provide instant visual feedback
4. ✅ Staggered animations create smooth narrative flow
5. ✅ Granular opt-out + master toggles respect user control
6. ✅ Design System components (DSCoachBar, DSBanner, DSProgressRing) eliminate duplication

### **Watch Out For:**
1. ⚠️ Trend thresholds must be tracker-specific (0.2 lbs ≠ 2 oz ≠ 2 hours)
2. ⚠️ Did You Know tips must avoid medical claims (educational, not prescriptive)
3. ⚠️ Messaging must be fasting-friendly (avoid "breakfast/lunch/dinner")
4. ⚠️ Mood overlay opacity must be subtle (12-22%, not overpowering)
5. ⚠️ Animations must respect Reduce Motion (accessibility first)

---

## 📞 QUESTIONS BEFORE IMPLEMENTING NEW TRACKER

1. **Trend Metric:** What metric defines progress? (weight, %, oz, hours, score)
2. **Trend Thresholds:** What values define improving/regressing/flat?
3. **Recap Metrics:** What 3 metrics summarize 30-day performance?
4. **Coach Bar Messages:** What 3 motivational messages fit each trend state?
5. **Banner Messages:** What 3 action-oriented messages fit each trend state?
6. **Did You Know Tips:** What 5-10 educational tips are relevant and safe?
7. **Subtitle Tagline:** What motivational phrase captures this tracker's purpose?

---

## 🔒 MANDATES (NEVER VIOLATE)

### **1. Universal Pattern First**
- Use "Your LIFe Journey" pattern for ALL trackers
- Don't invent custom progress views
- Adapt messaging, not structure

### **2. Reusable Components**
- Always use DSCoachBar, DSBanner, DSProgressRing
- Don't duplicate code across trackers
- Single source of truth in Design System

### **3. Adaptive Messaging**
- All messaging adapts to trend state (improving/regressing/flat)
- Don't use static messages
- Behavioral psychology = user engagement

### **4. Visual Consistency**
- Navy gradient base + adaptive mood overlay
- Circular progress rings (Apple Watch pattern)
- Luxury gradient title "Your LIFe Journey"
- Same typography, spacing, animations

### **5. User Control**
- Granular opt-out (per card)
- Master toggles (per tracker)
- "Don't show again" global opt-out
- Restore via Manage My Experience

### **6. Accessibility**
- Respect Reduce Motion
- 44×44pt tap targets (Apple HIG)
- VoiceOver labels on all interactive elements
- Sufficient color contrast (white text on accent)

---

## 🎯 CURRENT STATUS

### **Completed:**
- [x] Weight Tracker "Your LIFe Journey" (REFERENCE IMPLEMENTATION)
- [x] DSCoachBar component (Phase v1.3)
- [x] DSBanner component (Phase v1.2e)
- [x] DSProgressRing component (Phase v1.2d)
- [x] Universal pattern architecture documented

### **Next Up:**
- [ ] Fasting Tracker "Your LIFe Journey"
- [ ] Hydration Tracker "Your LIFe Journey"
- [ ] Sleep Tracker "Your LIFe Journey"
- [ ] Mood Tracker "Your LIFe Journey"

---

**Last Updated:** 2025-10-21 (Phase v1.3)
**Status:** ACTIVE - Apply to all 5 trackers
**Owner:** Rich Marin (Product Owner)
**Implementer:** Claude Code (AI Development Lead)

---

**END OF DOCUMENT**
