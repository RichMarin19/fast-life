# Fast LIFe - Development Handoff Documentation

## Critical UI Rules - NEVER VIOLATE

### ❌ NEVER ACCEPTABLE: UI Element Overlapping

**Rule:** UI elements (buttons, text, page indicators, etc.) must NEVER overlap or cover each other under ANY circumstances.

**Why This Matters:**
- Overlapping UI breaks usability and looks unprofessional
- Users cannot interact with covered elements
- Creates frustration and poor user experience

**Historical Issue (January 2025):**
- **Problem:** Keyboard toolbar added to Fasting Goal and Hydration Goal pages
- **Result:** Toolbar increased keyboard height by ~44pt, compressed view, caused Back/Next buttons to overlap page indicator dots
- **Root Cause:** Added `.toolbar { ... }` modifier without adjusting `.padding(.bottom, 110)` to accommodate extra height
- **Fix:** Removed toolbar, restored original layout with proper spacing

**Testing Protocol:**
1. Test ALL screen sizes (iPhone SE, standard, Pro Max)
2. Test with keyboard open AND closed
3. Test ALL navigation paths (forward and backward)
4. Verify NO elements overlap in ANY state

**Reference:** Apple Human Interface Guidelines - Layout
> "Ensure sufficient space between interactive elements to prevent accidental taps and maintain visual clarity"
> https://developer.apple.com/design/human-interface-guidelines/layout

---

## Page Indicator Dots - CRITICAL SOLUTION

### ⚠️ MUST USE CORRECT IMPLEMENTATION

**The Problem (January 2025):**
- Page indicator dots not showing on onboarding TabView
- Dots were rendering but **INVISIBLE** - same color as white background
- Wasted 2+ hours debugging with wrong syntax

**The CORRECT Solution (NEVER CHANGE THIS):**

```swift
// In OnboardingView body:
TabView(selection: $currentPage) {
    // ... pages ...
}
.tabViewStyle(.page(indexDisplayMode: .always))  // Shows dots, .always keeps them visible

// In OnboardingView init:
init(isOnboardingComplete: Binding<Bool>) {
    self._isOnboardingComplete = isOnboardingComplete

    // CRITICAL: Set page indicator colors to be VISIBLE
    UIPageControl.appearance().currentPageIndicatorTintColor = UIColor.systemBlue  // Active dot
    UIPageControl.appearance().pageIndicatorTintColor = UIColor.gray.withAlphaComponent(0.3)  // Inactive dots
}
```

**Why Each Part Matters:**
1. `.tabViewStyle(.page(indexDisplayMode: .always))` - Shows page indicators, keeps them visible with keyboard
2. `UIPageControl.appearance()` - Sets colors so dots are VISIBLE against white background
3. `.systemBlue` - Active dot matches app theme
4. `.gray.withAlphaComponent(0.3)` - Inactive dots are light gray (visible but subtle)

**What DOESN'T Work:**
- ❌ `.tabViewStyle(.page)` alone - dots default to invisible colors
- ❌ `.indexViewStyle()` - this is for Lists, NOT TabView
- ❌ `.automatic` instead of `.always` - dots disappear with keyboard
- ❌ Two separate modifiers - syntax error, not how SwiftUI works

**Testing:**
1. All 7 pages must show dots at bottom
2. Current page dot must be blue and visible
3. Inactive dots must be light gray and visible
4. Dots must stay visible even when keyboard appears

**References:**
- TabView Page Style: https://developer.apple.com/documentation/swiftui/pagetabviewstyle
- UIPageControl: https://developer.apple.com/documentation/uikit/uipagecontrol

---

## Onboarding Flow Rules

### Auto-Focus Behavior (Pages 2-5)

**Required Behavior:**
- **Page 2 (Current Weight):** Cursor defaults to text field, keyboard opens immediately
- **Page 3 (Goal Weight):** Cursor defaults to text field, keyboard opens immediately
- **Page 4 (Fasting Goal):** Cursor defaults to manual entry field, keyboard stays open
- **Page 5 (Hydration Goal):** Cursor defaults to manual entry field, keyboard stays open
- **Page 6 (HealthKit Sync):** Keyboard dismisses

**Implementation:**
```swift
.onAppear {
    isFocused = true  // Activates auto-focus
}
```

**Why This Matters:**
- Users expect to type immediately without tapping fields
- Maintains smooth onboarding flow
- Reduces friction in data entry

**Reference:** Apple HIG - Onboarding
> "Minimize user effort during onboarding by anticipating needs"
> https://developer.apple.com/design/human-interface-guidelines/onboarding

---

## Keyboard Management Rules

### When to Dismiss Keyboard

**DO Dismiss Keyboard:**
- ✅ When navigating BACK from data entry page to non-data page (e.g., Current Weight → Welcome)
- ✅ When reaching HealthKit Sync page (end of data entry flow)

**DO NOT Dismiss Keyboard:**
- ❌ When navigating FORWARD between data entry pages (Pages 2→3→4→5)
- ❌ On every button press (creates jarring UX)

**Implementation:**
```swift
// Back button on Page 2 (Current Weight) ONLY
Button(action: {
    dismissKeyboard()  // Dismiss before going back to Welcome
    currentPage = 0
})
```

**Why This Matters:**
- Keyboard persisting through data entry pages = smooth flow
- Keyboard covering non-data pages = bad UX
- Balance between convenience and clarity

**Reference:** Apple HIG - Text Fields
> "Dismiss the keyboard when users navigate away from text input"
> https://developer.apple.com/design/human-interface-guidelines/text-fields

---

## DO NOT Change What Works

**Critical Rule:** If a feature is working correctly and the user hasn't reported issues, DO NOT modify it.

**Checklist Before Making Changes:**
1. ✅ Is there a reported bug or user request?
2. ✅ Will this change affect other working features?
3. ✅ Have I tested the change on all device sizes?
4. ✅ Have I tested all navigation paths?
5. ✅ Have I verified NO UI overlapping?

**When In Doubt:** Ask the user before making changes.

---

## Layout Padding Reference

### Onboarding Pages Bottom Padding

**Pages with 40pt bottom padding:**
- Welcome page (no keyboard)
- Current Weight page (keyboard + minimal content above buttons)
- Goal Weight page (keyboard + minimal content above buttons)

**Pages with 110pt bottom padding:**
- Fasting Goal page (keyboard + picker wheel + manual entry)
- Hydration Goal page (keyboard + picker wheel + manual entry)

**Why Different Padding:**
- Pages with more content above buttons need more bottom padding
- 110pt padding ensures buttons stay above page indicator dots even with keyboard open
- **DO NOT reduce this padding** without testing for overlay issues

---

## Version History

**v1.2.0 (January 2025):**
- Documented UI overlay prohibition rule
- Documented onboarding auto-focus requirements
- Documented keyboard management rules

---

## Questions?

If you need to make changes that might affect layout, keyboard behavior, or onboarding flow:
1. Document proposed changes
2. Test on multiple device sizes
3. Verify no UI overlapping
4. Get user approval before committing
