# Phase 2: Weight Tracker Notifications - Architecture Analysis
**Date:** October 22, 2025
**Status:** ✅ Architecture Review Complete
**Duration:** Option C Complete (45 minutes)

---

## 🎯 Executive Summary

**RECOMMENDATION:** Implement Weight Tracker notifications as a **NEW, SEPARATE SYSTEM** alongside existing Fasting notifications.

**Rationale:**
- Existing system is **Fasting-specific** (milestones, stages, hydration reminders, goal completions)
- Weight tracking needs **SIMPLE daily reminders** (not milestone-based)
- **Zero risk** to working Fasting notifications
- Clean separation of concerns (Weight vs Fasting)

---

## 📊 Current Notification Architecture

### ✅ What Exists (Fasting-Only System)

#### **1. Core Infrastructure (REUSABLE)** ✅
- **NotificationManager.swift** (1,000 LOC)
  - `@MainActor` singleton (`NotificationManager.shared`)
  - `UNUserNotificationCenterDelegate` conformance
  - `requestAuthorization()` - **CAN REUSE** ✅
  - `getAuthorizationStatus()` - **CAN REUSE** ✅
  - `cancelAllNotifications()` - shared cancellation

#### **2. Fasting-Specific Notifications** (DO NOT TOUCH)
- **Milestone Notifications** (4h, 8h, 12h, 16h, 18h, 20h, 24h+)
- **Stage Transitions** (Post-Absorptive, Glycogen Burning, Metabolic Switch, etc.)
- **Hydration Reminders** (every 2-4 hours during fast)
- **Did You Know Facts** (educational content)
- **Goal Reminders** (before/at fasting goal completion)

**Identifier Prefixes:**
```swift
private let milestoneIdentifierPrefix = "fastingMilestone_"
private let hydrationIdentifierPrefix = "hydration_"
private let didYouKnowIdentifierPrefix = "didyouknow_"
private let stageIdentifierPrefix = "stage_"
private let goalReminderIdentifierPrefix = "goalreminder_"
```

**❌ NONE of these apply to Weight Tracker!**

---

#### **3. Behavioral Notification System** (COMPLEX - NOT NEEDED)
- **BehavioralNotificationScheduler.swift** (expert panel architecture)
- **NotificationIdentifierBuilder.swift** (complex ID generation)
- **BehavioralNotificationRule.swift** (rule engine)

**Purpose:** Dynamic notification scheduling based on user behavior patterns
**Complexity:** HIGH (ML-assisted timing, adaptive frequency, rotation algorithms)
**Weight Tracker Need:** SIMPLE fixed-time daily reminder

**Decision:** ❌ **DO NOT USE** - Overengineered for Weight Tracker's needs

---

### ✅ What We Can Reuse

#### **1. Authorization (100% Reusable)** ✅
```swift
// Location: NotificationManager.swift (lines 21-33)
func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
    notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        if let error = error {
            Log.error("Notification authorization failed", category: .notifications, error: error)
        } else {
            Log.info("Notification authorization granted: \(granted)", category: .notifications)
        }
        DispatchQueue.main.async {
            completion?(granted)
        }
    }
}
```

**Usage for Weight:** Same method, no changes needed ✅

---

#### **2. Permission Checking (100% Reusable)** ✅
```swift
// Location: NotificationManager.swift (lines 35-41)
func getAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
    notificationCenter.getNotificationSettings { settings in
        DispatchQueue.main.async {
            completion(settings.authorizationStatus)
        }
    }
}
```

**Usage for Weight:** Check before scheduling ✅

---

#### **3. Info.plist Notification String (ALREADY UPDATED)** ✅
```xml
<!-- Location: Info.plist (lines 49-50) -->
<key>NSUserNotificationsUsageDescription</key>
<string>Fast LIFe needs permission to send helpful reminders for your fasting goals and daily weigh-ins to help you stay on track.</string>
```

**Status:** ✅ Already includes "daily weigh-ins" (Track 2.5 enhancement)

---

#### **4. Onboarding Permission Flow (PATTERN REUSABLE)** ✅
```swift
// Location: OnboardingView.swift (lines 688-693)
Button(action: {
    AppLogger.debug("Enable Notifications button tapped, requesting notification authorization", category: AppLogger.ui)
    NotificationManager.shared.requestAuthorization { granted in
        AppLogger.debug("Notification authorization result: \(granted ? "granted" : "denied"), completing onboarding", category: AppLogger.ui)
        completeOnboarding()
    }
})
```

**Pattern:** Request permission AFTER value-framing screen ✅
**Current:** Onboarding page 7 (Fasting + Weight weigh-ins)
**Enhancement Needed:** Add Weight-specific value-framing (v1.1)

---

## 🚀 Recommended Architecture: Weight Notification System

### **Phase 2a Implementation (NEW Code - 8-12 hours)**

#### **File 1: WeightNotificationPlanner.swift** (NEW - 200 LOC)
**Location:** `FastingTracker/Core/Managers/WeightNotificationPlanner.swift`

```swift
import Foundation

/// Pure scheduling logic for Weight Tracker daily reminders
/// Zero dependencies on UserNotifications framework (100% testable)
/// Following technical plan: fastlife_notifications_plan.md

struct WeightNotificationPlan {
    let id: String
    let fireDate: Date
}

enum WeightReminderID {
    /// Deterministic ID generation for one-per-day policy
    /// Format: "weight-YYYY-MM-DD" (e.g., "weight-2025-10-23")
    static func forDate(_ date: Date, tz: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = tz
        let ymd = formatter.string(from: date)
        return "weight-\(ymd)"
    }
}

struct WeightNotificationPlanner {
    /// Calculate next daily weight reminder
    /// Pure function - no side effects, 100% testable
    ///
    /// - Parameters:
    ///   - now: Current date/time
    ///   - preferred: Preferred reminder time (hour/minute components)
    ///   - tz: User's time zone
    ///   - quietHours: Optional quiet hours range (start..<end)
    ///   - skipWeekdays: Weekdays to skip (1=Sunday, 7=Saturday)
    ///
    /// - Returns: Next weight notification plan, or nil if scheduling not possible
    static func nextPlan(
        from now: Date = Date(),
        preferred: DateComponents,
        tz: TimeZone = .current,
        quietHours: Range<DateComponents>? = nil,
        skipWeekdays: Set<Int> = []
    ) -> WeightNotificationPlan? {

        let calendar = Calendar.current
        var candidateDate = calendar.startOfDay(for: now)

        // Step 1: Find next eligible day (not in skipWeekdays)
        var attempts = 0
        while attempts < 8 { // Max 1 week lookahead
            let weekday = calendar.component(.weekday, from: candidateDate)

            if !skipWeekdays.contains(weekday) {
                // Valid day found
                break
            }

            // Skip to next day
            candidateDate = calendar.date(byAdding: .day, value: 1, to: candidateDate)!
            attempts += 1
        }

        guard attempts < 8 else {
            AppLogger.notifications.warning("No valid day found within 1 week (all days skipped)")
            return nil
        }

        // Step 2: Build candidate fire time at preferred time
        var components = calendar.dateComponents([.year, .month, .day], from: candidateDate)
        components.hour = preferred.hour
        components.minute = preferred.minute
        components.timeZone = tz

        guard var fireDate = calendar.date(from: components) else {
            AppLogger.notifications.error("Failed to create fire date from components")
            return nil
        }

        // Step 3: If fire time is in past, move to next valid day
        if fireDate <= now {
            candidateDate = calendar.date(byAdding: .day, value: 1, to: candidateDate)!

            // Re-check skipWeekdays for next day
            let nextWeekday = calendar.component(.weekday, from: candidateDate)
            if skipWeekdays.contains(nextWeekday) {
                // Recursively find next valid day
                return nextPlan(from: candidateDate, preferred: preferred, tz: tz, quietHours: quietHours, skipWeekdays: skipWeekdays)
            }

            components = calendar.dateComponents([.year, .month, .day], from: candidateDate)
            components.hour = preferred.hour
            components.minute = preferred.minute
            components.timeZone = tz

            guard let nextFireDate = calendar.date(from: components) else {
                return nil
            }

            fireDate = nextFireDate
        }

        // Step 4: Check quiet hours and adjust if needed
        if let quietHours = quietHours {
            fireDate = adjustForQuietHours(fireDate, quietHours: quietHours, calendar: calendar)
        }

        // Step 5: Generate deterministic ID
        let id = WeightReminderID.forDate(fireDate, tz: tz)

        return WeightNotificationPlan(id: id, fireDate: fireDate)
    }

    /// Adjust fire date if it falls within quiet hours
    private static func adjustForQuietHours(
        _ fireDate: Date,
        quietHours: Range<DateComponents>,
        calendar: Calendar
    ) -> Date {
        let fireComponents = calendar.dateComponents([.hour, .minute], from: fireDate)
        let fireHour = fireComponents.hour ?? 0
        let fireMinute = fireComponents.minute ?? 0

        let quietStart = quietHours.lowerBound
        let quietEnd = quietHours.upperBound

        let quietStartHour = quietStart.hour ?? 0
        let quietStartMinute = quietStart.minute ?? 0
        let quietEndHour = quietEnd.hour ?? 0
        let quietEndMinute = quietEnd.minute ?? 0

        // Check if fire time falls within quiet hours
        let isInQuietHours: Bool

        if quietStartHour > quietEndHour || (quietStartHour == quietEndHour && quietStartMinute > quietEndMinute) {
            // Overnight quiet hours (e.g., 9 PM - 6:30 AM)
            let afterStart = (fireHour > quietStartHour) || (fireHour == quietStartHour && fireMinute >= quietStartMinute)
            let beforeEnd = (fireHour < quietEndHour) || (fireHour == quietEndHour && fireMinute < quietEndMinute)
            isInQuietHours = afterStart || beforeEnd
        } else {
            // Same-day quiet hours (e.g., 1 PM - 3 PM)
            let afterStart = (fireHour > quietStartHour) || (fireHour == quietStartHour && fireMinute >= quietStartMinute)
            let beforeEnd = (fireHour < quietEndHour) || (fireHour == quietEndHour && fireMinute < quietEndMinute)
            isInQuietHours = afterStart && beforeEnd
        }

        if isInQuietHours {
            // Move to first minute after quiet hours end
            var adjustedComponents = calendar.dateComponents([.year, .month, .day], from: fireDate)
            adjustedComponents.hour = quietEndHour
            adjustedComponents.minute = quietEndMinute

            if let adjustedDate = calendar.date(from: adjustedComponents) {
                AppLogger.notifications.debug("Adjusted fire time from quiet hours: \(fireDate) → \(adjustedDate)")
                return adjustedDate
            }
        }

        return fireDate
    }
}
```

**Testing Requirements:**
- ✅ 15+ unit test cases (100% coverage)
- ✅ Today before preferred time → schedules today
- ✅ Today after preferred time → schedules tomorrow
- ✅ Quiet hours overlap → moves to first minute after quiet window
- ✅ DST forward/backward days
- ✅ Time zone change event
- ✅ Weekday skips (e.g., weekends off)

---

#### **File 2: WeightNotificationManager.swift** (NEW - 150 LOC)
**Location:** `FastingTracker/Core/Managers/WeightNotificationManager.swift`

```swift
import Foundation
import UserNotifications

/// Weight Tracker notification scheduling
/// Delegates authorization to NotificationManager.shared (reuses Fasting auth)
/// Handles scheduling/cancellation for daily weight reminders only

@MainActor
class WeightNotificationManager {
    static let shared = WeightNotificationManager()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let category = "WEIGHT_REMINDER"

    private init() {}

    // MARK: - Scheduling

    /// Schedule next daily weight reminder
    /// - Parameters:
    ///   - preferredTime: User's preferred reminder time (DateComponents with hour/minute)
    ///   - quietHours: Optional quiet hours range
    ///   - skipWeekdays: Weekdays to skip (1=Sunday, 7=Saturday)
    func scheduleNextReminder(
        preferredTime: DateComponents,
        quietHours: Range<DateComponents>? = nil,
        skipWeekdays: Set<Int> = []
    ) async throws {
        // Step 1: Check authorization
        let settings = await notificationCenter.notificationSettings()
        guard settings.authorizationStatus == .authorized else {
            AppLogger.notifications.warning("Cannot schedule weight reminder - notifications not authorized")
            return
        }

        // Step 2: Compute next plan using pure planner
        guard let plan = WeightNotificationPlanner.nextPlan(
            from: Date(),
            preferred: preferredTime,
            tz: .current,
            quietHours: quietHours,
            skipWeekdays: skipWeekdays
        ) else {
            AppLogger.notifications.error("Failed to compute weight reminder plan")
            return
        }

        // Step 3: Cancel any existing weight reminders (de-dupe)
        await cancelAllWeightReminders()

        // Step 4: Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Time for your weigh-in"
        content.body = "Logging now keeps your trend accurate."
        content.sound = .default
        content.categoryIdentifier = category
        content.userInfo = ["type": "weight_reminder"]

        // Step 5: Create trigger
        let timeInterval = plan.fireDate.timeIntervalSinceNow
        guard timeInterval > 0 else {
            AppLogger.notifications.warning("Fire date is in past, skipping schedule")
            return
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)

        // Step 6: Create and add request
        let request = UNNotificationRequest(identifier: plan.id, content: content, trigger: trigger)

        try await notificationCenter.add(request)

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        AppLogger.notifications.info("Weight reminder scheduled: \(plan.id) at \(formatter.string(from: plan.fireDate))")
    }

    // MARK: - Cancellation

    /// Cancel today's weight reminder (called after successful weigh-in)
    func cancelTodayReminder() async {
        let todayID = WeightReminderID.forDate(Date(), tz: .current)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [todayID])
        AppLogger.notifications.info("Cancelled today's weight reminder: \(todayID)")
    }

    /// Cancel all pending weight reminders
    func cancelAllWeightReminders() async {
        let requests = await notificationCenter.pendingNotificationRequests()
        let weightIDs = requests
            .filter { $0.identifier.hasPrefix("weight-") }
            .map { $0.identifier }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: weightIDs)
        AppLogger.notifications.info("Cancelled \(weightIDs.count) weight reminders")
    }

    // MARK: - Debug

    func debugPrintPendingWeightReminders() async {
        let requests = await notificationCenter.pendingNotificationRequests()
        let weightRequests = requests.filter { $0.identifier.hasPrefix("weight-") }

        AppLogger.notifications.debug("Pending Weight Reminders: \(weightRequests.count)")

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short

        for request in weightRequests {
            if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                let fireDate = Date(timeIntervalSinceNow: trigger.timeInterval)
                AppLogger.notifications.debug("  \(request.identifier) → \(formatter.string(from: fireDate))")
            }
        }
    }
}
```

---

#### **File 3: WeightControlCenterView Enhancements** (MODIFY - 100 LOC)
**Location:** `FastingTracker/UI/Components/WeightComponents.swift`

**Add Settings Section:**
```swift
// MARK: - Weight Notification Settings (Phase 2a)

Section {
    Toggle("Enable Weight Reminders", isOn: $weightRemindersEnabled)
        .accessibilityLabel("Toggle daily weight reminders")
        .onChange(of: weightRemindersEnabled) { oldValue, newValue in
            if newValue {
                scheduleWeightReminders()
            } else {
                Task {
                    await WeightNotificationManager.shared.cancelAllWeightReminders()
                }
            }
        }

    if weightRemindersEnabled {
        DatePicker("Preferred Time", selection: $preferredReminderTime, displayedComponents: .hourAndMinute)
            .accessibilityLabel("Set preferred weigh-in reminder time")
            .onChange(of: preferredReminderTime) { _, _ in
                scheduleWeightReminders()
            }

        Toggle("Quiet Hours", isOn: $quietHoursEnabled)
            .accessibilityLabel("Enable quiet hours for weight reminders")

        if quietHoursEnabled {
            DatePicker("Start", selection: $quietHoursStart, displayedComponents: .hourAndMinute)
                .accessibilityLabel("Set quiet hours start time")

            DatePicker("End", selection: $quietHoursEnd, displayedComponents: .hourAndMinute)
                .accessibilityLabel("Set quiet hours end time")
        }

        // Skip Days (multi-select)
        DisclosureGroup("Skip Days") {
            ForEach(["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"], id: \.self) { day in
                Toggle(day, isOn: binding(for: day))
                    .accessibilityLabel("Skip weight reminders on \(day)")
            }
        }
    }
} header: {
    Text("Daily Reminders")
} footer: {
    if weightRemindersEnabled {
        Text("You'll receive one reminder per day at your preferred time. Reminders are cancelled automatically after you log your weight.")
    }
}

private func scheduleWeightReminders() {
    Task {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: preferredReminderTime)

        var quietRange: Range<DateComponents>? = nil
        if quietHoursEnabled {
            let startComponents = calendar.dateComponents([.hour, .minute], from: quietHoursStart)
            let endComponents = calendar.dateComponents([.hour, .minute], from: quietHoursEnd)
            quietRange = startComponents..<endComponents
        }

        try? await WeightNotificationManager.shared.scheduleNextReminder(
            preferredTime: components,
            quietHours: quietRange,
            skipWeekdays: skipWeekdaysSet
        )
    }
}
```

---

#### **File 4: WeightManager Integration** (MODIFY - 20 LOC)
**Location:** `FastingTracker/Core/Managers/WeightManager.swift`

**Add Notification Hooks:**
```swift
// After successful weight entry
func addWeightEntry(_ entry: WeightEntry) {
    // ... existing code ...

    // Cancel today's reminder after successful log
    Task {
        await WeightNotificationManager.shared.cancelTodayReminder()

        // Schedule tomorrow's reminder if enabled
        if UserDefaults.standard.bool(forKey: "weightRemindersEnabled") {
            let preferredTime = UserDefaults.standard.object(forKey: "weightReminderTime") as? Date ?? Date()
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: preferredTime)

            try? await WeightNotificationManager.shared.scheduleNextReminder(
                preferredTime: components,
                quietHours: getQuietHoursRange(),
                skipWeekdays: getSkipWeekdays()
            )
        }
    }
}
```

---

## 📊 Comparison: Existing vs Proposed

| Aspect | Existing (Fasting) | Proposed (Weight) |
|--------|-------------------|-------------------|
| **Complexity** | HIGH (behavioral rules, rotation, stages) | LOW (simple daily reminder) |
| **Notification Types** | 5 types (milestones, stages, hydration, facts, goals) | 1 type (daily reminder) |
| **Scheduling Logic** | Dynamic (milestone-based, behavior-adaptive) | Fixed (one per day at set time) |
| **ID Pattern** | `fastingMilestone_12`, `stage_16`, etc. | `weight-2025-10-23` |
| **Cancel Policy** | On fast completion | On successful weigh-in |
| **Settings Location** | Fasting Settings | **Weight Control Center** ✅ |
| **Lines of Code** | ~1,000 LOC | ~350 LOC (70% less) |
| **Testability** | Mixed (some side effects) | 100% pure (planner) |

---

## ✅ Key Decisions

### **1. Separate System (Not Behavioral)** ✅
**Reason:** Weight reminders are fundamentally different from Fasting notifications:
- Fasting: Event-driven (milestones during active fast)
- Weight: Time-driven (daily reminder regardless of fasting state)

**Decision:** Create standalone `WeightNotificationManager` + `WeightNotificationPlanner`

---

### **2. Reuse Authorization Only** ✅
**Reason:** NotificationManager.shared already handles:
- `requestAuthorization()` (works for all notification types)
- Permission status checking
- Onboarding flow (already mentions "daily weigh-ins")

**Decision:** Delegate auth to NotificationManager.shared, implement own scheduling

---

### **3. Settings in Control Center** ✅
**Reason:** User explicitly said: *"the customizations for notifications has it's own card under the control center and should be configured there for the users frequency choices"*

**Decision:** Add settings section in `WeightControlCenterView` (gear icon), NOT inline in WeightTrackingView

---

### **4. Simple Copy (v1), Behavioral Copy (v1.1+)** ✅
**Reason:** Follow "simplest method first" principle
- **v1 (Phase 2a):** Fixed copy: "Time for your weigh-in" / "Logging now keeps your trend accurate"
- **v1.1+ (Phase 2b):** Tone options (Minimalist, Motivational, Educational, Data-centric)

**Decision:** Ship Phase 2a with simple copy, iterate based on user feedback

---

## 🚀 Implementation Sequence (Phase 2a - 8-12 hours)

### **Day 1 (4 hours):**
1. **Create WeightNotificationPlanner.swift** (2 hours)
   - Pure `nextPlan()` function
   - `WeightReminderID.forDate()` helper
   - Quiet hours logic
   - Skip weekdays logic

2. **Write Unit Tests** (2 hours)
   - 15+ test cases
   - 100% coverage on planner
   - Edge cases (DST, time zones, quiet hours)

### **Day 2 (4 hours):**
3. **Create WeightNotificationManager.swift** (2 hours)
   - `scheduleNextReminder()` async function
   - `cancelTodayReminder()` helper
   - `cancelAllWeightReminders()` batch cancel

4. **Add Settings UI to WeightControlCenterView** (2 hours)
   - Toggle: "Enable Weight Reminders"
   - Time Picker: "Preferred Time"
   - Quiet Hours section
   - Skip Days multi-select

### **Day 3 (2-4 hours):**
5. **Wire Integration in WeightManager** (1 hour)
   - Cancel on successful log
   - Schedule tomorrow after log

6. **Testing & QA** (1-3 hours)
   - Integration tests (schedule/cancel flows)
   - UI smoke tests (toggle, time picker)
   - Real device testing (notifications appear)

---

## 📋 Acceptance Criteria (Phase 2a)

**MUST HAVE (Beta-Ready):**
- ✅ Exactly 1 pending weight reminder per eligible day
- ✅ Reminder cancelled automatically after weight logged
- ✅ Tomorrow's reminder scheduled after today's log
- ✅ Respect quiet hours (move to first minute after)
- ✅ Respect skip weekdays
- ✅ Settings in Weight Control Center (NOT inline)
- ✅ 0 crashes from notification flows
- ✅ 0 force-unwraps in notification code
- ✅ 100% unit test coverage on WeightNotificationPlanner
- ✅ ≥1 integration test proving cancel-on-log

**NICE TO HAVE (v1.1+):**
- Snooze action (60 min)
- Tone options (Minimalist, Motivational, Educational, Data-centric)
- Progress notifications (weekly recap, streak celebration)
- Recovery flow (missed check-in gentle re-engagement)

---

## 🎯 Score Impact Projection

**Current Score:** 8.0/10 (after Track 2)

**After Phase 2a (Weight Notifications):** **8.8/10** (+0.8 points)
- Customer Experience: 8.0 → 8.6 (+0.6) - Daily reminders improve engagement
- Beta Readiness: 7.2 → 8.2 (+1.0) - Feature parity with competitors (Lose It, MyFitnessPal)

---

## 📚 References

**Apple Documentation:**
- [UserNotifications Framework](https://developer.apple.com/documentation/usernotifications)
- [UNTimeIntervalNotificationTrigger](https://developer.apple.com/documentation/usernotifications/untimeintervalnotificationtrigger)
- [Human Interface Guidelines - Notifications](https://developer.apple.com/design/human-interface-guidelines/notifications)

**Industry Patterns:**
- **Lose It:** Daily weigh-in reminder at user-selected time
- **MyFitnessPal:** Cancel-on-log pattern (reminder disappears after log)
- **Apple Health:** Quiet hours respect, time zone handling

**Project Documentation:**
- Technical Plan: `/Users/richmarin/Desktop/Fast LIFe Roadmap/fastlife_notifications_plan.md`
- Advisory Board Input: `/Users/richmarin/Desktop/Fast LIFe Roadmap/Fast_LIFe_Weight_Tracker_Notification_System.md`
- Track 2 Summary: `.claude/TRACK-2-COMPLETE-SUMMARY.md`
- Gameplan: `.claude/GAMEPLAN-OCT22-UPDATED.md`

---

## ✅ Next Steps

### **Immediate (Start Phase 2a):**
1. ✅ Architecture review complete (Option C done)
2. **Create WeightNotificationPlanner.swift** (pure scheduling logic)
3. **Write unit tests** (100% coverage target)
4. **Create WeightNotificationManager.swift** (scheduling wrapper)
5. **Add settings UI** in WeightControlCenterView
6. **Wire integration** in WeightManager

### **Future (Phase 2b - v1.1+):**
- Tone system (user-selectable copy)
- Progress notifications (weekly recap, streaks)
- Recovery flow (missed check-in prompts)
- Snooze action (60 min delay)

---

**Status:** ✅ READY TO START PHASE 2a IMPLEMENTATION
**Estimated Duration:** 8-12 hours
**Expected Score:** 8.8/10 after completion
**Risk Level:** LOW (separate system, zero impact on Fasting notifications)

**Last Updated:** October 22, 2025
**Maintained By:** AI (Claude Code) + User (Rich Marin)
