# Fast LIFe - Fasting & Hydration Tracker

> Intermittent fasting timer with hydration tracking, weight management, and HealthKit integration

## 📱 Current Version
**2.0.0** (Build 13) - October 6, 2025

## ✨ Features

- ⏱️ **Intermittent Fasting Timer**
  - Customizable fasting goals (12h, 16h, 18h, 20h, 24h+)
  - Real-time countdown with visual progress
  - Goal completion notifications
  - Streak tracking with flame icons

- 💧 **Hydration Tracking**
  - Track water, coffee, and tea intake
  - Visual progress ring with daily goal
  - Historical calendar view with flame/X indicators
  - Detailed charts and statistics

- ⚖️ **Weight Tracking**
  - Manual weight entry
  - HealthKit bidirectional sync
  - BMI and body fat percentage
  - Visual charts and trend analysis

- 📊 **Insights & History**
  - Calendar views for fasting and hydration
  - Performance charts and statistics
  - Lifetime totals and averages
  - Goal achievement tracking

## 🛠 Tech Stack

- **Language:** Swift 5.x
- **Framework:** SwiftUI (100% native)
- **Minimum iOS:** 16.0
- **Target:** iPhone & iPad
- **Dependencies:** None (zero external libraries)
- **Backend:** Local storage with UserDefaults + HealthKit

## 📂 Project Structure

```
FastingTracker/
├── Models/
│   ├── FastingSession.swift       # Fasting session data model
│   ├── DrinkEntry.swift           # Hydration entry model
│   └── WeightEntry.swift          # Weight data model
├── Managers/
│   ├── FastingManager.swift       # Fasting logic & state
│   ├── HydrationManager.swift     # Hydration tracking logic
│   ├── WeightManager.swift        # Weight tracking logic
│   ├── HealthKitManager.swift     # HealthKit integration
│   └── NotificationManager.swift  # Local notifications
├── Views/
│   ├── ContentView.swift          # Main tab view
│   ├── HistoryView.swift          # Fasting history & calendar
│   ├── HydrationHistoryView.swift # Hydration history & calendar
│   ├── HydrationTrackingView.swift# Hydration main view
│   ├── WeightTrackingView.swift   # Weight tracking view
│   ├── InsightsView.swift         # Analytics dashboard
│   └── AdvancedView.swift         # Settings & preferences
├── Extensions/
│   └── ArrayExtensions.swift      # Shared utilities
├── Assets.xcassets/               # App icons & images
├── Info.plist                     # App configuration
└── FastingTracker.entitlements    # HealthKit permissions
```

## ⚠️ Known Issues & Pitfalls

### 🔥 CRITICAL: Array.chunked Extension

**Problem:** HydrationHistoryView requires `Array.chunked(into:)` extension for calendar grid layout

**Location:** `HydrationHistoryView.swift` lines 937-943

**History:**
- Originally embedded in HydrationHistoryView.swift
- Removed in commit `e7af659` causing ViewBuilder error
- Restored in commit `cc322ec` (v1.1.1)

**⚠️ DO NOT REMOVE THIS EXTENSION** - It will break the calendar rendering!

```swift
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
```

### 🚨 SwiftUI ViewBuilder Limitations

**Issue:** `@ViewBuilder` cannot contain statement-level code

**Symptoms:**
- Error: "Closure containing control flow statement cannot be used with result builder"
- Happens with `let` declarations at function scope

**Solutions:**
1. Remove `@ViewBuilder` and add explicit `return`
2. Move `let` statements inline
3. Use computed properties without `@ViewBuilder`

**Example:**
```swift
// ❌ BROKEN
@ViewBuilder
private var myView: some View {
    let data = processData()  // Error!
    ForEach(data) { ... }
}

// ✅ FIXED
private var myView: some View {
    let data = processData()
    return ForEach(data) { ... }
}
```

### 🩺 HealthKit Requirements

**Setup:**
1. Add capabilities in Xcode: Signing & Capabilities → HealthKit
2. Required Info.plist keys:
   - `NSHealthShareUsageDescription` - Read access explanation
   - `NSHealthUpdateUsageDescription` - Write access explanation
3. User must grant permissions on first launch
4. **Physical device required** - HealthKit doesn't work on simulator

**Data Types Used:**
- Weight (HKQuantityType.bodyMass)
- BMI (HKQuantityType.bodyMassIndex)
- Body Fat Percentage (HKQuantityType.bodyFatPercentage)

### 📅 Calendar Date Truncation Bug

**Issue:** Day numbers showing "..." instead of full number (e.g., "20" → "...")

**Cause:** Font size mismatch - using `.subheadline` was too large for cell

**Fix:** Changed to `.system(size: 12, weight: .medium)`

**Location:** `HydrationDayView` line 751, `CalendarDayView` line 1194

## 🚀 Development Setup

### Prerequisites
```bash
- Xcode 15.0 or later
- macOS Sonoma or later
- iOS 16.0+ device/simulator
- Apple Developer account (for HealthKit testing)
```

### Build & Run
```bash
# Clone repository
git clone https://github.com/RichMarin19/fast-life.git
cd fast-life

# Open in Xcode
open FastingTracker.xcodeproj

# Or use CLI
./run.sh  # Builds and launches in simulator
```

### Testing HealthKit Features
- **Requires physical iOS device**
- Go to Settings → Health → Data Access & Devices → Fast LIFe
- Grant read/write permissions for Weight, BMI, Body Fat

## 🐛 Bug Fix Log

### v1.1.2 (October 2, 2025)
- ✨ **Enhanced:** Custom goal input UX
  - Added keyboard toolbar with "Done" button to dismiss keyboard
  - User can now access "Save" button after entering custom goal
  - Added `@FocusState` for proper keyboard management

- 🎨 **Improved:** Goal button visual styling
  - Increased goal display font size (36pt) for better readability
  - Added subtle borders to unselected buttons (30% opacity)
  - Improved spacing and modern corner radius (8px)
  - Enhanced TextField with proper padding and background

- 🐛 **Fixed:** Custom goal default value bug
  - Custom goal now defaults to "0" instead of showing previous preset value
  - Big display properly resets when entering custom mode
  - Preset buttons clear custom text to prevent stale data
  - Files: `HistoryView.swift`, `HydrationHistoryView.swift`

### v1.1.1 (October 2, 2025)
- 🐛 **Fixed:** Calendar date truncation (HydrationHistoryView)
  - Changed font from `.subheadline` to `.system(size: 12)`
  - Dates now display correctly without "..." truncation

- 🎨 **Fixed:** Visual consistency between Fasting and Hydration calendars
  - Goal Met: Orange flame 🔥 (was cyan circle)
  - Partial/Incomplete: Red X ❌ (was orange circle)
  - Updated legend to match

- 🔧 **Fixed:** ViewBuilder error in HydrationHistoryView
  - Restored `Array.chunked` extension
  - Removed obsolete backgroundColor/indicatorColor properties

### v1.1.0 (October 1, 2025)
- ✨ Added Hydration History with calendar view
- ✨ Added Weight Tracking with HealthKit sync
- ✨ Added Insights tab with analytics
- 🔧 Fixed timer display issues
- 🔧 Fixed Insights tab layout

### v1.0.0 (September 30, 2025)
- 🎉 Initial release
- ⏱️ Fasting timer with customizable goals
- 📊 Basic history view
- 🔔 Notifications

## 📋 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.1.2 | Oct 2, 2025 | Custom goal UX improvements, keyboard toolbar, visual styling enhancements |
| 1.1.1 | Oct 2, 2025 | Calendar visual fixes, date truncation bug fix |
| 1.1.0 | Oct 1, 2025 | Hydration History, Weight Tracking, Insights |
| 1.0.0 | Sep 30, 2025 | Initial release with fasting timer |

## 🎨 Design Decisions

### Calendar Visual Language
- **Orange Flame** 🔥 = Goal achieved/met
- **Red X** ❌ = Incomplete/partial progress
- **Gray circle** ⚪ = No data
- **Blue border** = Today's date

### Color Palette
- Primary: Blue (#007AFF)
- Success: Orange (#FF9500)
- Warning: Red (#FF3B30)
- Neutral: Gray system colors
- Hydration: Cyan/Blue tones

### Data Persistence
- **UserDefaults** for app settings and preferences
- **JSON encoding** for fasting sessions, drinks, weight entries
- **HealthKit** as source of truth for health data

## 🔒 Privacy & Data

- All data stored locally on device
- HealthKit data synced with user's Health app
- No analytics or tracking
- No external servers or APIs
- No personal data collected

## 📝 Code Conventions

### Swift Style
- **SwiftUI** over UIKit (100% SwiftUI)
- **ObservableObject** + **@Published** for state management
- **MARK:** comments for code organization
- **Explicit types** where clarity needed
- **Guard statements** for early returns

### File Organization
```swift
// MARK: - Main View
// MARK: - Subviews
// MARK: - Helper Methods
// MARK: - Data Models
```

### Naming
- **Views:** `*View.swift` (e.g., ContentView, HistoryView)
- **Managers:** `*Manager.swift` (e.g., FastingManager)
- **Models:** Descriptive nouns (e.g., FastingSession, DrinkEntry)

## 🤝 Contributing

This is a personal project, but if you're extending it:

1. **Branch naming:** `feature/your-feature` or `bugfix/issue-description`
2. **Test on device** before committing
3. **Update version** in Info.plist (follow semantic versioning)
4. **Document changes** in this README
5. **Commit messages:** Use conventional commits format

## 📄 License

**Private - All Rights Reserved**

© 2025 Rich Marin

## 👤 Author

**Rich Marin**
- GitHub: [@RichMarin19](https://github.com/RichMarin19)
- Repository: [fast-life](https://github.com/RichMarin19/fast-life)

---

## 🤖 Development Notes

This project is developed with AI assistance (Claude Code). Key learnings:

1. **SwiftUI Result Builders** - @ViewBuilder has strict limitations on statements
2. **HealthKit Integration** - Requires entitlements, physical device, user permissions
3. **Calendar Layout** - Grid layout needs careful sizing to prevent truncation
4. **State Management** - ObservableObject pattern works well for this scale

**Last Updated:** October 2, 2025
**Maintained By:** Rich Marin with AI-Assisted Development

---

💡 **For Developers/AI:** Read the "Known Issues & Pitfalls" section carefully before making changes!
