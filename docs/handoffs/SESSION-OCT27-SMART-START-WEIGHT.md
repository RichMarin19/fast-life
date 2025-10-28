## 🎯 NEW FEATURE: Smart Start Weight Selection (October 27, 2025)

**Status:** 🔄 IN PROGRESS - Design + Implementation

### User Request

**Problem:** Current first-time setup asks for "Current Weight" but users want to track from a historical starting point.

**Solution:** Smart start weight selection with HealthKit integration

### Feature Requirements

**1. Rename Field:** "Current Weight" → "Start Weight"
- Represents weight at **beginning of journey** (not necessarily today)
- Conceptually different from current weight (which is entered separately later)

**2. Add Date Picker for Start Weight**
- Users can select **when** they were at that start weight
- Example: "I was 185 lbs on October 1st, 2025"
- Creates historical baseline for tracking progress from specific point in time

**3. Smart HealthKit Selection (Preferred Path)**
- Check if user has weight data in HealthKit
- If available: Show **picker/list** of historical weight entries from HealthKit
- User browses and selects: "Oct 1, 2025 - 185 lbs" ← picks as start weight
- Automatically fills both weight AND date from HealthKit history

**4. Manual Entry Fallback**
- If no HealthKit authorization OR no historical data
- Fall back to manual entry:
  - Text field for "Start Weight"
  - Date picker for "Start Date"

### Why This Is Brilliant UX

1. **Faster:** No typing if they have HealthKit data
2. **Accurate:** Uses exact values from their scale/HealthKit
3. **Better UX:** "Pick from your history" vs "remember and type"
4. **User Choice:** Start from any point in their journey (New Year's, diet start date, etc.)

### Implementation Plan

**File to Modify:**
- `FirstTimeWeightSetupView.swift` - First-time setup screen

**Architecture:**
```swift
// 1. Check HealthKit for historical data
// 2. If data exists: Show scrollable list/picker of date + weight pairs
// 3. If no data: Show manual entry fields (weight + date)
// 4. Either way: User ends up with Start Weight + Start Date
```

**UI Flow:**

**Option A: HealthKit Data Available**
```
┌─────────────────────────────────┐
│  Select Your Start Weight       │
├─────────────────────────────────┤
│  Pick from your HealthKit data: │
│                                 │
│  ○ Oct 1, 2025 - 185.0 lbs     │
│  ● Sept 15, 2025 - 187.2 lbs  │ ← Selected
│  ○ Sept 1, 2025 - 190.5 lbs   │
│  ○ Aug 20, 2025 - 192.0 lbs   │
│                                 │
│  [Or Enter Manually]            │
└─────────────────────────────────┘
```

**Option B: No HealthKit Data**
```
┌─────────────────────────────────┐
│  Enter Your Start Weight        │
├─────────────────────────────────┤
│  Start Weight:                  │
│  [185.0________] lbs           │
│                                 │
│  Start Date:                    │
│  [Sept 15, 2025 ▼]             │
│                                 │
│  [Get Started]                  │
└─────────────────────────────────┘
```

### Technical Details

**1. Check for HealthKit Data:**
```swift
// Check if user has historical weight entries
let hasHealthKitData = HealthKitManager.shared.isWeightAuthorized() &&
                       !weightManager.weightEntries.isEmpty
```

**2. Load Historical Entries (if available):**
```swift
// Fetch last 90 days of weight entries for selection
let threeMonthsAgo = Calendar.current.date(byAdding: .day, value: -90, to: Date())!
let historicalEntries = weightManager.weightEntries.filter { $0.date >= threeMonthsAgo }
```

**3. Display as Picker/List:**
```swift
// Show scrollable list with date + weight
List(historicalEntries, id: \.id) { entry in
    HStack {
        Text(entry.date.formatted(date: .abbreviated, time: .omitted))
        Spacer()
        Text("\(String(format: "%.1f", entry.weight)) lbs")
    }
    .onTapGesture {
        selectedStartWeight = entry.weight
        selectedStartDate = entry.date
    }
}
```

**4. Save Start Weight + Date:**
```swift
// Store in UserDefaults for future reference
@AppStorage("startWeight") private var startWeight: Double = 0
@AppStorage("startDate") private var startDate: Date = Date()
```

### Success Criteria

1. ✅ User can select start weight from HealthKit history
2. ✅ User can manually enter start weight + date if no HealthKit data
3. ✅ Both weight AND date are captured
4. ✅ Start weight is conceptually separate from current weight
5. ✅ UI is clean, intuitive, and fast

### Testing Plan

**Test Case 1: HealthKit Available**
1. User has 100+ weight entries in HealthKit
2. Open first-time setup → See list of historical entries
3. Tap entry from 30 days ago → Weight + date filled in
4. Continue → Verify values saved correctly

**Test Case 2: No HealthKit Data**
1. User has no HealthKit entries (or denied permission)
2. Open first-time setup → See manual entry form
3. Enter weight + select date manually
4. Continue → Verify values saved correctly

**Test Case 3: Switch Between Modes**
1. User has HealthKit data
2. See picker, then tap "Or Enter Manually" button
3. Switch to manual mode → Enter custom values
4. Verify can switch back to picker mode

---

**Last Updated:** October 27, 2025 | **Version:** 2.3.0 Build 12 | **Current Phase:** Phase 8.4 - Smart Start Weight Feature
