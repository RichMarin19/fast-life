# ✅ Definition of Done

**When is a task truly complete?**

---

## 📋 Overview

**Purpose:** Clear criteria to know when work is actually finished (not "90% done").

**Why this matters:**
- "Almost done" becomes "done done"
- Prevents scope creep
- Ensures quality
- Enables progress tracking
- Avoids rework

**How to use:**
- Check all boxes before marking task complete
- Don't skip items marked P0
- P1 items strongly recommended
- P2 items optional but valuable

---

## 🏗️ Phase 0: Foundation Tasks

### Privacy Manifest (2 hours)

**Must have (P0):**
- ✅ PrivacyInfo.xcprivacy file created in project root
- ✅ All data types declared (Health & Fitness)
- ✅ Required reason APIs documented
- ✅ Privacy nutrition label fields match manifest
- ✅ File committed to git

**Should have (P1):**
- ✅ Privacy policy updated on website
- ✅ In-app privacy link added

**Validation:**
```bash
# File exists
ls -la FastingTracker/PrivacyInfo.xcprivacy

# Valid XML
plutil -lint FastingTracker/PrivacyInfo.xcprivacy
```

---

### CI/CD Pipeline (4-6 hours)

**Must have (P0):**
- ✅ .github/workflows/ci.yml created
- ✅ Build job runs on push
- ✅ Test job runs all unit tests
- ✅ SwiftLint job checks code quality
- ✅ All jobs passing (green checkmarks)
- ✅ Status badge in README

**Should have (P1):**
- ✅ Runs on pull requests
- ✅ Required status checks enabled
- ✅ Slack/email notifications on failure
- ✅ Coverage report generated

**Could have (P2):**
- ✅ Automatic version bumping
- ✅ Release notes generation

**Validation:**
```bash
# Check workflow file
cat .github/workflows/ci.yml

# Trigger workflow
git commit --allow-empty -m "Test CI"
git push

# Check status
# Go to GitHub Actions tab
```

---

### Keychain Security (6 hours)

**Must have (P0):**
- ✅ KeychainManager.swift implemented
- ✅ All UserDefaults replaced with Keychain
- ✅ Uses kSecAttrAccessibleWhenUnlockedThisDeviceOnly
- ✅ Error handling for all operations
- ✅ Unit tests passing (10+ tests)

**Should have (P1):**
- ✅ Data migration from UserDefaults to Keychain
- ✅ Keychain backed up properly
- ✅ Integration tests passing

**Validation:**
```bash
# No UserDefaults references for sensitive data
rg "UserDefaults.*fasting|hydration|weight|sleep" --type swift

# Should return 0 results

# Tests passing
xcodebuild test -scheme FastingTracker -only-testing:FastingTrackerTests/KeychainManagerTests
```

---

### Crash Reporting (3 hours)

**Must have (P0):**
- ✅ Firebase SDK integrated
- ✅ GoogleService-Info.plist added (gitignored)
- ✅ Crashlytics initialized in App
- ✅ Test crash verified in Firebase console
- ✅ Symbolication working (readable stack traces)

**Should have (P1):**
- ✅ Custom keys for context (userID, appVersion)
- ✅ Non-fatal errors logged
- ✅ Alert configured for critical crashes

**Validation:**
```bash
# Trigger test crash
# Run app > Tap "Test Crash" button
# Check Firebase console after 5 minutes

# Symbolication working
# Stack traces show actual file names and line numbers, not memory addresses
```

---

### Structured Logging (4 hours)

**Must have (P0):**
- ✅ AppLogger.swift implemented using os_log
- ✅ All print() replaced with AppLogger calls
- ✅ Log levels used correctly (debug, info, error)
- ✅ Subsystems defined (fasting, hydration, weight, sleep)

**Should have (P1):**
- ✅ Privacy flags on sensitive data
- ✅ Logs visible in Console.app
- ✅ Logs persisted for debugging

**Validation:**
```bash
# No print() statements in production code
rg "print\(" --type swift FastingTracker/

# Should return 0 results (only test files OK)

# View logs
open /Applications/Utilities/Console.app
# Filter by "Fast LIFe"
```

---

### Basic Tests (8 hours)

**Must have (P0):**
- ✅ Test target created
- ✅ 20+ unit tests passing
- ✅ Core logic tested (fasting calculations, hydration tracking)
- ✅ CI runs tests automatically
- ✅ No failing tests

**Should have (P1):**
- ✅ Test coverage >15%
- ✅ Edge cases tested (zero values, negative numbers)
- ✅ Mock repositories created

**Validation:**
```bash
# Run all tests
xcodebuild test -workspace FastingTracker.xcworkspace -scheme FastingTracker

# Check coverage
./scripts/coverage_report.sh
# Verify overall coverage >15%
```

---

## 🏗️ Phase 1: Architecture Tasks

### SPM Package (Per Package: 8 hours)

**Must have (P0):**
- ✅ Package.swift created with correct structure
- ✅ Sources/ directory with at least 3 files
- ✅ Tests/ directory with at least 5 tests
- ✅ Package builds successfully
- ✅ Package added to main app target
- ✅ Tests passing

**Should have (P1):**
- ✅ README.md in package explaining purpose
- ✅ Example usage documented
- ✅ All public APIs have doc comments

**Validation:**
```bash
# Build package
cd Packages/Core
swift build

# Run tests
swift test

# Check documentation
# All public types/methods have /// comments
```

---

### Repository Implementation (Per Repository: 8 hours)

**Must have (P0):**
- ✅ Protocol defined with all CRUD operations
- ✅ Implementation class created
- ✅ All methods implemented with async/await
- ✅ SwiftData ModelContext used correctly
- ✅ 20+ unit tests passing
- ✅ Error handling on all operations

**Should have (P1):**
- ✅ Integration tests with real ModelContainer
- ✅ Performance tests (<100ms for reads)
- ✅ Batch operations for efficiency
- ✅ Observable streams working

**Could have (P2):**
- ✅ Caching layer
- ✅ Pagination for large datasets

**Validation:**
```bash
# Tests passing
xcodebuild test -scheme DataLayer -only-testing:DataLayerTests/FastingRepositoryTests

# Performance check
# Run tests with -measure flag
# Verify <100ms average
```

---

### Feature Package (Per Feature: 12-16 hours)

**Must have (P0):**
- ✅ Views implemented (tracking + history)
- ✅ ViewModels implemented with @Observable
- ✅ Components reusable
- ✅ Uses DesignSystem package
- ✅ Uses DataLayer package
- ✅ 15+ ViewModel tests passing
- ✅ No tight coupling to other features

**Should have (P1):**
- ✅ Snapshot tests for all views (5+ snapshots)
- ✅ Loading/error states handled
- ✅ Empty states designed
- ✅ Accessibility labels added

**Could have (P2):**
- ✅ UI tests for critical flows
- ✅ Animation polish

**Validation:**
```bash
# Build feature in isolation
cd Packages/FeatureFasting
swift build

# Run all tests
swift test

# Snapshot tests
# Verify snapshots generated in __Snapshots__/
```

---

### Phase 1 Complete

**Must have (P0):**
- ✅ All 7+ packages created (Core, DesignSystem, DataLayer, 4 features)
- ✅ All 4 repositories implemented (Fasting, Hydration, Weight, Sleep)
- ✅ Dependency injection working
- ✅ 100+ tests passing
- ✅ Test coverage >40%
- ✅ App builds and runs
- ✅ All features functional

**Should have (P1):**
- ✅ Architecture diagram created
- ✅ Package dependency graph documented
- ✅ Migration guide from monolith

**Validation:**
```bash
# Build all packages
xcodebuild build -workspace FastingTracker.xcworkspace -scheme "All Packages"

# Run all tests
xcodebuild test -workspace FastingTracker.xcworkspace -scheme "All Tests"

# Check coverage
./scripts/coverage_report.sh
# Verify >40% overall
```

---

## 🚀 Phase 2: Polish Tasks

### VoiceOver Support (8 hours)

**Must have (P0):**
- ✅ All buttons have accessibilityLabel
- ✅ All images marked hidden or labeled
- ✅ All form fields have labels and hints
- ✅ All custom controls accessible
- ✅ Navigation works with VoiceOver
- ✅ Tested on device with VoiceOver enabled

**Should have (P1):**
- ✅ Accessibility Inspector audit passing
- ✅ Custom rotor implemented for lists
- ✅ Skip navigation available

**Validation:**
```
1. Enable VoiceOver on device
2. Navigate entire app using only swipe gestures
3. Verify all elements announce correctly
4. Verify all actions work
5. Run Accessibility Inspector audit (0 errors)
```

---

### Dynamic Type (8 hours)

**Must have (P0):**
- ✅ All text uses system fonts
- ✅ Typography.swift uses scalable fonts
- ✅ Layout doesn't break at XXL size
- ✅ Critical text uses minimumScaleFactor
- ✅ Tested at all sizes (XS to XXXL)

**Should have (P1):**
- ✅ Custom font scaling implemented
- ✅ Images scale with text

**Validation:**
```
1. Settings > Accessibility > Display & Text Size > Larger Text
2. Set to maximum size
3. Open app
4. Navigate all screens
5. Verify no text truncated or overlapping
```

---

### Color Contrast (8 hours)

**Must have (P0):**
- ✅ All text meets WCAG AA (4.5:1)
- ✅ Large text meets 3:1 ratio
- ✅ Interactive elements have 3:1 contrast with background
- ✅ Focus indicators visible
- ✅ Contrast checked in light and dark mode

**Should have (P1):**
- ✅ Automated contrast testing
- ✅ WCAG AAA achieved (7:1)

**Validation:**
```bash
# Check all color combinations
./scripts/check_color_contrast.sh

# Manual check
# Use WebAIM Contrast Checker
# https://webaim.org/resources/contrastchecker/
```

---

### async/await Migration (16 hours)

**Must have (P0):**
- ✅ All completion handlers replaced
- ✅ All DispatchQueue calls removed
- ✅ All repositories use async/await
- ✅ All ViewModels use async/await
- ✅ No compiler warnings about concurrency
- ✅ Tests updated and passing

**Should have (P1):**
- ✅ Parallel loading with async let
- ✅ Cancellation supported
- ✅ Progress reporting

**Validation:**
```bash
# No completion handlers
rg "@escaping.*->.*Void" --type swift

# No DispatchQueue.main.async
rg "DispatchQueue.main.async" --type swift

# Both should return 0 results
```

---

### Actor Isolation (8 hours)

**Must have (P0):**
- ✅ All managers are actors
- ✅ Data races eliminated
- ✅ Concurrency warnings fixed
- ✅ Thread-safe operations verified

**Should have (P1):**
- ✅ Custom executors for performance
- ✅ Actor reentrancy handled

**Validation:**
```bash
# Enable strict concurrency checking
# Build Settings > Swift Compiler > Strict Concurrency Checking = Complete

# Build with no warnings
xcodebuild build -workspace FastingTracker.xcworkspace -scheme FastingTracker | grep "warning:"

# Should return 0 warnings
```

---

### Performance Optimization (8 hours)

**Must have (P0):**
- ✅ Cold start <2 seconds
- ✅ Warm start <0.5 seconds
- ✅ Scrolling 60fps
- ✅ No memory leaks detected
- ✅ Instruments profile clean

**Should have (P1):**
- ✅ Images cached
- ✅ Data pagination implemented
- ✅ List virtualization working

**Validation:**
```bash
# Profile cold start
# 1. Delete app
# 2. Open Instruments > Time Profiler
# 3. Launch app
# 4. Measure time to first interaction
# 5. Verify <2 seconds

# Check memory
# Debug > Memory Graph Debugger
# Look for leaks (purple warnings)
```

---

### GDPR Compliance (16 hours)

**Must have (P0):**
- ✅ Data export working (JSON file)
- ✅ Data deletion working (all data removed)
- ✅ Settings UI for privacy options
- ✅ Confirmation dialogs for destructive actions
- ✅ Privacy policy link added

**Should have (P1):**
- ✅ Export includes all data types (fasting, hydration, weight, sleep)
- ✅ Deletion verified in Keychain and SwiftData
- ✅ GDPR consent flow (if tracking users)

**Validation:**
```bash
# Test export
# 1. Add test data
# 2. Tap "Export My Data"
# 3. Verify JSON file generated
# 4. Verify all 4 data types included

# Test deletion
# 1. Tap "Delete All Data" > Confirm
# 2. Verify all lists empty
# 3. Reinstall app
# 4. Verify data not restored
```

---

### Security Audit (8 hours)

**Must have (P0):**
- ✅ Keychain uses correct access level
- ✅ All network calls HTTPS
- ✅ No hardcoded API keys
- ✅ No sensitive data in logs
- ✅ MobSF scan passing (0 critical issues)

**Should have (P1):**
- ✅ Certificate pinning implemented
- ✅ Jailbreak detection
- ✅ Obfuscation for release builds

**Validation:**
```bash
# Run MobSF scan
docker run -it -p 8000:8000 opensecurity/mobile-security-framework-mobsf

# Upload .ipa
# Review report for critical/high issues
# Fix all critical issues
```

---

### Snapshot Tests (16 hours)

**Must have (P0):**
- ✅ 50+ snapshot tests created
- ✅ All major views covered
- ✅ Light and dark mode snapshots
- ✅ Accessibility size snapshots
- ✅ Tests passing on CI

**Should have (P1):**
- ✅ Different device sizes (SE, 13, 13 Pro Max)
- ✅ Different locales
- ✅ Loading/error states

**Validation:**
```bash
# Run snapshot tests
xcodebuild test -workspace FastingTracker.xcworkspace -scheme FastingTracker -only-testing:FastingTrackerTests/SnapshotTests

# Check snapshot count
find . -name "*.png" -path "*/__Snapshots__/*" | wc -l
# Should be 50+
```

---

### UI Tests (8 hours)

**Must have (P0):**
- ✅ 20+ UI tests created
- ✅ All critical flows tested
- ✅ Tests passing consistently
- ✅ Tests run on CI

**Critical flows:**
- ✅ Start/end fasting
- ✅ Log hydration
- ✅ Add weight entry
- ✅ Add sleep entry
- ✅ View history
- ✅ Export data
- ✅ Delete data

**Validation:**
```bash
# Run UI tests
xcodebuild test -workspace FastingTracker.xcworkspace -scheme FastingTrackerUITests

# Should pass consistently (5 runs)
for i in {1..5}; do
  xcodebuild test -workspace FastingTracker.xcworkspace -scheme FastingTrackerUITests
done
```

---

### Phase 2 Complete

**Must have (P0):**
- ✅ 100% VoiceOver support
- ✅ Full Dynamic Type support
- ✅ WCAG AA compliance
- ✅ async/await everywhere
- ✅ Actor isolation complete
- ✅ <2s cold start
- ✅ GDPR export/deletion working
- ✅ Security audit passed
- ✅ 70%+ test coverage
- ✅ 50+ snapshot tests
- ✅ 20+ UI tests
- ✅ App Store ready

**Should have (P1):**
- ✅ Beta tested with 50+ users
- ✅ All feedback addressed
- ✅ App Store screenshots prepared
- ✅ App Store description written

**Validation:**
```bash
# Final checks
xcodebuild test -workspace FastingTracker.xcworkspace -scheme FastingTracker

./scripts/coverage_report.sh
# Verify >70%

# VoiceOver test
# Navigate entire app with VoiceOver

# Performance test
# Profile cold start <2s

# Build for release
xcodebuild archive -workspace FastingTracker.xcworkspace -scheme FastingTracker

# Submit to TestFlight
./scripts/deploy_testflight.sh
```

---

## 🚢 Release Checklist

### Beta Release (TestFlight)

**Must have (P0):**
- ✅ All Phase 2 criteria met
- ✅ Privacy manifest complete
- ✅ TestFlight build uploaded
- ✅ Beta tester group created
- ✅ What to Test section written

**Should have (P1):**
- ✅ 50+ beta testers invited
- ✅ Feedback form created
- ✅ Bug reporting process documented

---

### App Store Submission

**Must have (P0):**
- ✅ All TestFlight feedback addressed
- ✅ App Store metadata complete (title, description, keywords)
- ✅ Screenshots for all device sizes
- ✅ App icon finalized
- ✅ Privacy policy live
- ✅ Support URL active
- ✅ Age rating assigned
- ✅ Pricing selected
- ✅ Build submitted for review

**Should have (P1):**
- ✅ App preview video created
- ✅ Press kit prepared
- ✅ Launch announcement ready
- ✅ Social media accounts created

---

## 🎯 How to Use This Document

**For each task:**
1. Read all P0 items before starting
2. Work through task
3. Check off each P0 item as you complete it
4. Don't move to next task until all P0 checked
5. Come back for P1/P2 items if time allows

**When stuck:**
1. Review definition for your current task
2. Check what's not yet complete
3. Refer to [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for help
4. Use validation commands to verify

**Benefits:**
- No ambiguity about "done"
- Quality gates enforced
- Progress accurately tracked
- Rework minimized
- Confidence in completion

---

**[⬅️ Back to Process Improvements](../PROCESS_IMPROVEMENTS_ACTION_PLAN.md)** | **[📖 Master Plan](../ENTERPRISE_TRANSFORMATION_MASTER.md)**
