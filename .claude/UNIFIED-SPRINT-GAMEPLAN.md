# Fast LIFe — Unified Sprint Gameplan

**Date:** October 22, 2025
**Purpose:** Reconcile consultant recommendations with completed Track 1 work and create actionable next steps
**Target:** Complete remaining P0 blockers + ship Weight notifications v1 (2 week sprint)

---

## Executive Summary

### What We've Already Completed ✅

Based on our Track 1 work (branch: `feat/T1-folder-structure-file-splits`, tag: `track-1-complete`):

1. **✅ Force-Unwraps Eliminated** (Consultant Priority #1)
   - Status: **COMPLETE**
   - Found: 1 instance in DataStore.swift:372
   - Fixed: Replaced with guard statement + fatalError
   - Verified: 0 force-unwraps remaining in production code
   - Script: Used grep verification

2. **✅ Logging System** (Consultant Priority #4)
   - Status: **COMPLETE**
   - Replaced: 400+ print() statements → Log.debug()
   - Verified: 1 print() remaining (in Logging.swift itself, acceptable)
   - Script: `scripts/fix-print-logging.sh`

3. **✅ SwiftLint + CI** (Consultant Priority #2 - PARTIAL)
   - SwiftLint: **COMPLETE** (v0.57.0, 40+ rules, .swiftlint.yml committed)
   - CI Pipeline: **EXISTS** (.github/workflows/ci.yml)
   - **Gap:** Need to verify CI is passing on PRs
   - **Gap:** Need to add force_unwrapping, force_try, force_cast to opt_in_rules

4. **✅ Crash Reporting** (Consultant Priority #6)
   - Status: **COMPLETE**
   - Firebase Crashlytics: Active in production builds
   - Project: "Fast lIFe" (fast-life-264b4)
   - Bundle ID: com.fastlife.app
   - Build Status: BUILD SUCCEEDED

5. **🟡 Unit Tests** (Consultant Priority #2 - PARTIAL)
   - Status: **88 tests exist** (well-written, Given-When-Then pattern)
   - **Gap:** Test target has type mismatches (deferred to post-P0)
   - **Gap:** Need to verify tests run in CI

6. **🟡 Weight Notifications v1** (Consultant Priority #3)
   - Status: **CODE EXISTS**
   - Files: WeightNotificationPlanner.swift, WeightNotificationPlannerTests.swift
   - **Gap:** Need to verify end-to-end flow works
   - **Gap:** Need onboarding permission prompt
   - **Gap:** Need cancel-on-log logic

### What Remains (Priority Order) 🎯

**P0 (Blocking Beta):**
1. Fix SwiftLint opt-in rules (add force_unwrapping, force_try, force_cast)
2. Verify CI pipeline passes (build + lint + tests)
3. Fix test configuration issues (type mismatches)
4. Complete Weight notifications v1 end-to-end

**P1 (High Priority):**
5. Accessibility + Dynamic Type (Weight screens)
6. Fastlane TestFlight lane

**P2 (Medium Priority):**
7. SwiftUI Previews (Weight screens)

---

## Detailed Task Breakdown

### Task 1: Update SwiftLint Configuration ⚠️ BLOCKING
**Owner:** DevOps / Senior iOS Dev
**Time Estimate:** 5 minutes
**Status:** Needs update

**Current State:**
- ✅ SwiftLint 0.57.0 installed
- ✅ .swiftlint.yml exists with 40+ rules
- ⚠️ Missing consultant-recommended opt-in rules

**What to Do:**
```yaml
# Add to .swiftlint.yml opt_in_rules section:
opt_in_rules:
  - force_unwrapping
  - force_try
  - force_cast
```

**Verification:**
```bash
swiftlint lint --strict
```

**Deliverable:** PR with updated .swiftlint.yml that passes CI

---

### Task 2: Verify CI Pipeline ⚠️ BLOCKING
**Owner:** DevOps
**Time Estimate:** 15 minutes
**Status:** Needs verification

**Current State:**
- ✅ CI workflow exists: .github/workflows/ci.yml
- ✅ Runs on PRs to main/develop
- ✅ Includes: SwiftLint + Build + Test
- ⚠️ Unknown if currently passing

**What to Do:**
1. Check GitHub Actions tab for latest run status
2. If failing: debug and fix issues
3. Ensure all PRs show green checkmark

**Verification:**
```bash
# Trigger CI locally (if possible)
act pull_request  # Using nektos/act tool

# Or push a test branch and verify in GitHub UI
git checkout -b test/ci-verification
git commit --allow-empty -m "test: verify CI pipeline"
git push origin test/ci-verification
```

**Deliverable:** Screenshot of passing CI run

---

### Task 3: Fix Test Configuration ⚠️ BLOCKING
**Owner:** Backend Lead / App Architect
**Time Estimate:** 1-2 hours
**Status:** Deferred from Track 1, needs fixing now

**Current State:**
- ✅ 88 tests exist (WeightManager, ViewModels, Notification Planner)
- ✅ Tests follow Given-When-Then pattern
- ⚠️ Module import mismatch: tests import `FastingTracker` but app module is `Fast_lIFe`
- ⚠️ Type mismatches: MockWeightManager, BehavioralNotificationScheduler.shared

**What to Do:**
1. **Fix module imports:**
   - Already fixed: changed `@testable import FastingTracker` → `@testable import Fast_lIFe`

2. **Fix BehavioralNotificationScheduler.shared:**
   ```swift
   // In BehavioralNotificationScheduler.swift
   @MainActor
   class BehavioralNotificationScheduler {
       static let shared = BehavioralNotificationScheduler()
       // ... rest of implementation
   }
   ```

3. **Fix MockWeightManager conformance:**
   - Check what protocol/class WeightControlCenterViewModel expects
   - Update MockWeightManager to conform properly

4. **Run tests:**
   ```bash
   xcodebuild test \
     -project FastingTracker.xcodeproj \
     -scheme FastingTracker \
     -destination 'platform=iOS Simulator,name=iPhone 17'
   ```

**Reference:** `.claude/TEST-CONFIG-BLOCKERS.md` (detailed analysis)

**Deliverable:** All 88 tests passing in CI

---

### Task 4: Complete Weight Notifications v1 🎯 HIGH PRIORITY
**Owner:** Feature Lead
**Time Estimate:** 4-6 hours
**Status:** Partially implemented, needs end-to-end verification

**Current State:**
- ✅ WeightNotificationPlanner exists (pure logic)
- ✅ WeightNotificationPlannerTests exist (~15 tests)
- ✅ Midnight-spanning quiet hours fixed (October 22, 2025)
- ⚠️ Need to verify onboarding permission prompt
- ⚠️ Need to verify cancel-on-log logic
- ⚠️ Need end-to-end manual QA

**What to Do:**

1. **Verify Planner Logic:**
   ```bash
   # Run existing tests
   xcodebuild test \
     -project FastingTracker.xcodeproj \
     -scheme FastingTracker \
     -only-testing:FastingTrackerTests/WeightNotificationPlannerTests
   ```

2. **Add Onboarding Permission Prompt:**
   - Check if onboarding flow requests notification permission
   - If not: add permission request step with time picker
   - Reference: Apple Human Interface Guidelines - Notifications

3. **Verify Cancel-on-Log Logic:**
   - When user logs weight for the day, cancel pending notification
   - Schedule next day's notification
   - Test: Log weight → verify notification cancelled → verify next day scheduled

4. **Manual QA Checklist:**
   - [ ] User can set preferred notification time in onboarding
   - [ ] Notification arrives at scheduled time
   - [ ] Quiet hours respected (no notifications during sleep)
   - [ ] Midnight-spanning quiet hours work correctly
   - [ ] Logging weight cancels today's notification
   - [ ] Next day's notification is scheduled after log
   - [ ] Notifications persist across app restarts

5. **Add Debug View (Consultant Recommendation):**
   ```swift
   struct DebugNotificationsView: View {
       @State private var pending: [UNNotificationRequest] = []
       var body: some View {
           List(pending, id: \.identifier) { req in
               VStack(alignment: .leading) {
                   Text(req.identifier)
                   if let trigger = req.trigger as? UNCalendarNotificationTrigger,
                      let nextDate = trigger.nextTriggerDate() {
                       Text("Next: \(nextDate.formatted())")
                           .font(.caption)
                   }
               }
           }
           .navigationTitle("Pending Notifications")
           .onAppear { refresh() }
       }
       private func refresh() {
           UNUserNotificationCenter.current().getPendingNotificationRequests { reqs in
               DispatchQueue.main.async { self.pending = reqs }
           }
       }
   }
   ```

**Deliverable:** Weight notifications v1 working end-to-end + manual QA passed

---

### Task 5: Accessibility + Dynamic Type (Weight Screens) 📱 HIGH PRIORITY
**Owner:** UI Lead
**Time Estimate:** 3-4 hours
**Status:** Not started

**What to Do:**

1. **Add SwiftUI Previews:**
   ```swift
   #if DEBUG
   struct WeightControlCenterView_Previews: PreviewProvider {
       static var previews: some View {
           WeightControlCenterView()
               .previewDisplayName("Default")

           WeightControlCenterView()
               .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
               .previewDisplayName("Accessibility XXXL")
       }
   }
   #endif
   ```

2. **Replace Fixed Fonts with Semantic Styles:**
   ```swift
   // Before:
   .font(.system(size: 48, weight: .bold))

   // After:
   .font(.largeTitle.weight(.bold))
   // Or use custom dynamic type:
   .font(.system(.largeTitle, design: .rounded).weight(.bold))
   ```

3. **Add Accessibility Labels:**
   ```swift
   Button("Log Weight") {
       // action
   }
   .accessibilityLabel("Log your weight")
   .accessibilityHint("Opens weight entry form")
   ```

4. **Test with VoiceOver:**
   - Enable VoiceOver on simulator: Accessibility Inspector
   - Navigate through Weight screens
   - Verify all interactive elements are labeled
   - Verify labels are descriptive

**Reference:** Apple Human Interface Guidelines - Accessibility

**Deliverable:** Weight screens support Dynamic Type + VoiceOver + previews added

---

### Task 6: Fastlane TestFlight Lane 🚀 MEDIUM PRIORITY
**Owner:** Release Engineer
**Time Estimate:** 2-3 hours
**Status:** Not started

**What to Do:**

1. **Install Fastlane:**
   ```bash
   # Using Homebrew (recommended)
   brew install fastlane

   # Or using RubyGems
   sudo gem install fastlane -NV
   ```

2. **Initialize Fastlane:**
   ```bash
   cd /Users/richmarin/Desktop/FastingTracker
   fastlane init
   ```

3. **Create Beta Lane:**
   ```ruby
   # fastlane/Fastfile
   default_platform(:ios)

   platform :ios do
     desc "Build & upload to TestFlight"
     lane :beta do
       # Increment build number
       increment_build_number(xcodeproj: "FastingTracker.xcodeproj")

       # Build app
       build_app(
         scheme: "FastingTracker",
         export_method: "app-store",
         configuration: "Release"
       )

       # Upload to TestFlight
       upload_to_testflight(
         skip_waiting_for_build_processing: true,
         distribute_external: false  # Internal testing first
       )

       # Notify team
       slack(
         message: "New Fast LIFe build uploaded to TestFlight!",
         success: true
       ) rescue nil  # Optional: only if Slack configured
     end
   end
   ```

4. **Configure App Store Connect:**
   - Create App Store Connect API Key
   - Add to Fastlane: `fastlane fastlane-credentials add --username your@email.com`

5. **Test Fastlane:**
   ```bash
   fastlane beta
   ```

**Reference:** Fastlane docs - https://docs.fastlane.tools/

**Deliverable:** Working `fastlane beta` command that uploads to TestFlight

---

## Sprint Schedule (2 Weeks)

### Week 1: Fix Blockers
**Mon-Tue:**
- Task 1: Update SwiftLint (5 min)
- Task 2: Verify CI (15 min)
- Task 3: Fix test configuration (1-2 hours)

**Wed-Fri:**
- Task 4: Complete Weight notifications v1 (4-6 hours)

### Week 2: Polish + Ship
**Mon-Wed:**
- Task 5: Accessibility + Dynamic Type (3-4 hours)

**Thu-Fri:**
- Task 6: Fastlane TestFlight lane (2-3 hours)
- Final QA + ship to TestFlight

---

## Acceptance Criteria (From Consultant)

Sprint is COMPLETE when:
- ✅ **Zero** force-unwraps in production (ALREADY DONE)
- ✅ **Logging** cleanup complete (ALREADY DONE)
- ⏳ **CI** passes on PRs (build + lint + tests) - VERIFY
- ⏳ **Weight notifications v1** works end-to-end - COMPLETE
- ⏳ **Accessibility**: Weight screens support Dynamic Type and VoiceOver - COMPLETE
- ⏳ **Fastlane**: TestFlight lane working - COMPLETE

---

## What We're NOT Doing This Sprint

**Deferred to Future Sprints:**
- Expanding test coverage to other managers (Fasting, Hydration, Sleep, Mood)
- Design system hardcoded values replacement
- Performance optimization
- Additional tracker notifications (Hydration, Sleep, Mood)

**Rationale:** Focus on shipping Weight tracker to beta first, then iterate.

---

## Risk & Mitigation

### Risk 1: Test Configuration Takes Longer Than Expected
**Likelihood:** Medium
**Impact:** High (blocks CI)
**Mitigation:** Budget extra day for debugging, escalate early if stuck

### Risk 2: Weight Notifications Have Edge Cases
**Likelihood:** High
**Impact:** Medium
**Mitigation:** Thorough manual QA, add Debug Notifications View for visibility

### Risk 3: Fastlane Certificate Issues
**Likelihood:** Medium
**Impact:** Low (can ship manually if needed)
**Mitigation:** Start Fastlane setup early, have manual TestFlight upload as backup

---

## Success Metrics

**Code Quality:**
- 0 force-unwraps in production ✅
- 0 print() in production (except Logging.swift) ✅
- CI passing on all PRs
- 88+ tests passing

**Beta Readiness:**
- Weight notifications working end-to-end
- Crash reporting active (Firebase Crashlytics) ✅
- TestFlight builds automated (Fastlane)

**User Experience:**
- Weight screens support Dynamic Type
- VoiceOver users can navigate Weight tracker
- Notifications respect quiet hours

---

## Documentation References

**Our Existing Docs:**
- `.claude/CONSULTANT-HANDOFF.md` - Track 1 completion summary
- `.claude/TRACK-1-P0-STATUS.md` - Detailed Track 1 status
- `.claude/TEST-CONFIG-BLOCKERS.md` - Test configuration issues
- `.claude/FIREBASE-CRASHLYTICS-COMPLETE.md` - Crashlytics setup

**Consultant Docs:**
- `/Users/richmarin/Downloads/FastLIFe_Next_Sprint_Gameplan.md` - Sprint priorities

**Industry References:**
- Apple WWDC 2020: "Explore Logging in Swift"
- Apple WWDC 2022: "Eliminate data races using Swift Concurrency"
- Apple Human Interface Guidelines: Accessibility
- Fastlane Docs: https://docs.fastlane.tools/

---

## PR Template (Consultant Recommendation)

```md
## Summary
- What changed
- Why

## Testing
- Unit tests added/updated: Yes/No
- Manual QA steps

## Checklist
- [ ] CI green (build + lint + tests)
- [ ] No force-unwraps
- [ ] Accessibility checks
- [ ] Logger used
```

---

## Next Steps (Immediate)

1. **Read this document** and confirm understanding ✅
2. **Update SwiftLint config** (5 min) - Task 1
3. **Verify CI pipeline** (15 min) - Task 2
4. **Fix test configuration** (1-2 hours) - Task 3
5. **Complete Weight notifications v1** (4-6 hours) - Task 4

---

**Status:** Ready to execute
**Owner:** Dev Team
**Last Updated:** October 22, 2025
**Version:** 1.0
