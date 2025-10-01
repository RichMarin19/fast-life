# Streak Calendar Feature 🔥

## Visual Design

The History tab now displays a **calendar-style streak visualization** showing the last 28 days (4 weeks) of your fasting activity.

## Calendar Layout

```
🔥 Streak Calendar                           5 days

S   M   T   W   T   F   S
┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐
│1│ │2│ │3│ │4│ │5│ │6│ │7│
│🔥│ │🔥│ │X│ │ │ │🔥│ │🔥│ │🔥│
└─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘

... (4 weeks total)

🔥 Goal Met    X Incomplete    ○ No Fast
```

## Visual Indicators

### 🔥 Orange Flame
- **Meaning:** You completed a fast that **met your goal**
- **Background:** Light orange tint
- **Example:** 20h fast when goal is 20h

### ❌ Red X
- **Meaning:** You started a fast but **stopped before reaching goal**
- **Background:** Light red tint
- **Example:** 15h fast when goal is 20h (incomplete)

### ⚪ Gray/Empty
- **Meaning:** No fast recorded on this day
- **Background:** Light gray
- **No icon shown**

### 🔵 Blue Border (Today)
- **Special indicator:** Current day has blue outline
- Shows you where you are in the calendar

## Features

### 1. Header
- **Left:** 🔥 "Streak Calendar" title
- **Right:** Current streak count (e.g., "5 days")
- Only shows streak number if > 0

### 2. Weekday Labels
- Single letter: S M T W T F S
- Helps orient which day of week

### 3. Calendar Grid
- **4 rows × 7 columns** = 28 days (4 weeks)
- Each cell shows:
  - Day number (1-31)
  - Status icon (🔥, ❌, or empty)
  - Color-coded background

### 4. Legend
Three indicators at bottom:
- 🔥 Goal Met (orange)
- ❌ Incomplete (red)
- ⚪ No Fast (gray)

## How It Works

### Data Source
- Reads from `fastingManager.fastingHistory`
- Matches fasts to calendar days by **start date**
- Shows last 28 days from today backwards

### Streak Calculation
The calendar **visually shows** your streak:
- Look for **consecutive flame days** 🔥🔥🔥
- If you see an ❌ or gap, streak is broken
- New streak starts after a break

### Example Scenarios

**Perfect Week:**
```
M   T   W   T   F   S   S
🔥  🔥  🔥  🔥  🔥  🔥  🔥  ← 7 day streak!
```

**Broken Streak:**
```
M   T   W   T   F   S   S
🔥  🔥  ❌  🔥  🔥  🔥  🔥  ← Broke on Wed, new 4-day streak
```

**Missed Days:**
```
M   T   W   T   F   S   S
🔥  🔥  ⚪  ⚪  🔥  🔥  🔥  ← Skipped 2 days, new 3-day streak
```

**Mix of Everything:**
```
S   M   T   W   T   F   S
⚪  🔥  🔥  ❌  ⚪  🔥  🔥  ← Current 2-day streak
```

## Layout Structure

```
┌─────────────────────────────────────┐
│  History Tab                         │
├─────────────────────────────────────┤
│                                      │
│  ┌─────────────────────────────┐   │
│  │  🔥 Streak Calendar    5 days │   │
│  │                              │   │
│  │  [Calendar Grid - 4 weeks]   │   │
│  │                              │   │
│  │  🔥 Goal  ❌ Incomplete  ○ No│   │
│  └─────────────────────────────┘   │
│                                      │
│  Recent Fasts                        │
│  ─────────────────────                │
│  Jan 15, 2024 - 20h 15m - ✓ Goal   │
│  Jan 14, 2024 - 16h 30m - ✓ Goal   │
│  Jan 13, 2024 - 12h 45m - Incomplete│
│  ...                                 │
└─────────────────────────────────────┘
```

## Design Details

### Colors
- **Orange flame:** `#FF9500` (system orange)
- **Red X:** `#FF3B30` (system red)
- **Blue border:** `#007AFF` (system blue, for today)
- **Gray background:** Light gray opacity

### Spacing
- 8pt between calendar cells
- 12pt between rows
- 16pt padding around calendar
- 20pt spacing in legend

### Sizing
- Calendar cells: Square aspect ratio (1:1)
- Responsive to screen width
- Works on all iPhone sizes

## Interaction

### Current Implementation
- **View-only:** No tap interactions yet
- **Automatic updates:** Refreshes when history changes
- **Real-time:** Shows latest data from FastingManager

### Future Enhancements (Optional)
- Tap day to see details
- Swipe to see older months
- Export calendar as image
- Share streak on social media

## Technical Details

### Components
1. **StreakCalendarView**
   - Main calendar container
   - Header with title and streak count
   - Grid layout
   - Legend

2. **CalendarDayView**
   - Individual day cell
   - Shows day number + icon
   - Color-coded background
   - Blue border for today

3. **DayStatus Enum**
   - `.goalMet` → 🔥
   - `.incomplete` → ❌
   - `.noFast` → empty

### Data Flow
```
FastingManager.fastingHistory
    ↓
StreakCalendarView (last 28 days)
    ↓
CalendarDayView (each day)
    ↓
getDayStatus() → matches history
    ↓
Display: 🔥, ❌, or ⚪
```

## Usage Example

**User Journey:**
1. Complete 20h fast on Monday → Monday shows 🔥
2. Complete 20h fast on Tuesday → Tuesday shows 🔥
3. Stop at 15h on Wednesday → Wednesday shows ❌
4. Skip Thursday → Thursday shows ⚪
5. Complete 20h Friday-Sunday → Each shows 🔥

**Calendar View:**
```
M   T   W   T   F   S   S
🔥  🔥  ❌  ⚪  🔥  🔥  🔥

Current Streak: 3 days (Fri-Sat-Sun)
```

## Benefits

✅ **Visual Motivation:** See your progress at a glance
✅ **Pattern Recognition:** Identify good/bad days of week
✅ **Accountability:** Gaps are visible
✅ **Celebration:** Watch flames grow into streaks
✅ **History Context:** Understand your fasting habits

## What Didn't Change

✅ All existing features still work:
- Timer functionality
- Goal settings
- History list
- Notifications
- Streak counter on main screen

The calendar is an **addition**, not a replacement!
