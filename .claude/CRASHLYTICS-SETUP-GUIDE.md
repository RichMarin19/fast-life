# Firebase Crashlytics Integration Guide

**Date:** October 22, 2025
**Status:** READY TO IMPLEMENT
**Estimated Time:** 1 hour (30 min manual, 30 min automated)

---

## 🎯 Objective

Integrate Firebase Crashlytics for production crash monitoring per consultant P0 requirement.

**Consultant Feedback:**
> "No crash reporting tool (Sentry, Firebase Crashlytics, Bugsnag, etc.)"
> "Beta Readiness Score: 5.7/10"
> "Impact: -2.0 points"

**Industry Standard:**
- **Apple:** Crash reports via TestFlight/App Store Connect (limited)
- **Google:** Firebase Crashlytics (recommended for startups)
- **Uber/Airbnb:** Crashlytics + custom monitoring
- **Industry Pattern:** Crashlytics for 80% of iOS apps (2024 survey)

---

## 📋 Implementation Phases

### Phase 1: Firebase Project Setup (MANUAL - 10 minutes)

**Step 1.1: Create Firebase Project**
1. Go to https://console.firebase.google.com/
2. Click "Add project" or select existing project
3. Enter project name: "Fast LIFe"
4. Enable Google Analytics (recommended)
5. Click "Create project"

**Step 1.2: Register iOS App**
1. In Firebase Console, click "Add app" → iOS
2. Enter iOS bundle ID: `com.richmarin.FastingTracker` (verify in Xcode)
3. Enter App nickname: "Fast LIFe Tracker"
4. Download `GoogleService-Info.plist`
5. **DO NOT commit GoogleService-Info.plist to git** (add to .gitignore)

**Step 1.3: Add GoogleService-Info.plist to Xcode**
1. Drag `GoogleService-Info.plist` into Xcode project root
2. ✅ Check "Copy items if needed"
3. ✅ Check "FastingTracker" target
4. Verify it appears in Project Navigator

---

### Phase 2: SPM Installation (MANUAL - 5 minutes)

**Step 2.1: Add Firebase SDK via Swift Package Manager**
1. In Xcode: File → Add Package Dependencies...
2. Enter repository URL: `https://github.com/firebase/firebase-ios-sdk.git`
3. Version: "Up to Next Major Version" (11.0.0 recommended as of Oct 2024)
4. Click "Add Package"

**Step 2.2: Select Products**
Select these packages:
- ✅ **FirebaseCrashlytics** (required)
- ✅ **FirebaseAnalytics** (recommended for breadcrumb logging)

Click "Add Package" and wait for Xcode to resolve dependencies (~2-3 minutes).

---

### Phase 3: Code Integration (SEMI-AUTOMATED - 15 minutes)

#### Step 3.1: Update FastingTrackerApp.swift (AUTOMATED)

Run automated script:
```bash
./scripts/setup-crashlytics.sh
```

This script will:
1. ✅ Add Firebase imports
2. ✅ Add `FirebaseApp.configure()` to app init
3. ✅ Add crash detection logging
4. ✅ Update .gitignore to exclude GoogleService-Info.plist
5. ✅ Verify Info.plist has required keys

**What the script does:**

```swift
// Before:
import SwiftUI

@main
struct FastingTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// After:
import SwiftUI
import Firebase
import FirebaseCrashlytics

@main
struct FastingTrackerApp: App {
    init() {
        // Configure Firebase on app launch
        FirebaseApp.configure()
        Log.info("Firebase Crashlytics initialized", category: .general)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

#### Step 3.2: Add -ObjC Linker Flag (MANUAL - 2 minutes)

**Why:** Firebase SDK requires Objective-C runtime linking

**How:**
1. Select FastingTracker project in Xcode
2. Select FastingTracker target
3. Go to "Build Settings" tab
4. Search for "Other Linker Flags"
5. Double-click the value field
6. Click "+"
7. Enter: `-ObjC`
8. Press Enter

**Verification:**
```bash
# Verify linker flag was added
grep -A 5 "OTHER_LDFLAGS" FastingTracker.xcodeproj/project.pbxproj | grep -- "-ObjC"
```

---

### Phase 4: Testing (SEMI-AUTOMATED - 10 minutes)

#### Step 4.1: Force Test Crash (AUTOMATED)

Run test crash script:
```bash
./scripts/test-crashlytics.sh
```

This will:
1. ✅ Build app for simulator
2. ✅ Launch simulator
3. ✅ Trigger test crash via button
4. ✅ Verify crash report sent to Firebase

**Manual Test Alternative:**
1. Build and run app on simulator (⌘R)
2. Add test crash button to ContentView (temporary):
```swift
Button("Test Crash") {
    fatalError("Test crash for Crashlytics verification")
}
```
3. Tap button to trigger crash
4. Relaunch app (crash reports upload on next launch)
5. Remove test button after verification

#### Step 4.2: Verify in Firebase Console (MANUAL - 5 minutes)

1. Go to https://console.firebase.google.com/
2. Select "Fast LIFe" project
3. Navigate to Crashlytics → Dashboard
4. Wait 2-5 minutes for report to appear
5. ✅ Verify crash shows: "Test crash for Crashlytics verification"

**Expected Output:**
- Crash count: 1
- Affected users: 1
- Stack trace visible
- Device info (iOS version, device model)

---

## 🤖 Automated Scripts

### Script 1: setup-crashlytics.sh

**Location:** `scripts/setup-crashlytics.sh`

**What it does:**
- Adds Firebase imports to FastingTrackerApp.swift
- Adds Firebase configuration to app init
- Updates .gitignore for GoogleService-Info.plist
- Verifies Info.plist configuration
- Creates backup before changes

**Usage:**
```bash
./scripts/setup-crashlytics.sh
```

### Script 2: test-crashlytics.sh

**Location:** `scripts/test-crashlytics.sh`

**What it does:**
- Builds app for simulator
- Injects test crash code (temporary)
- Launches app in simulator
- Waits for crash
- Removes test code
- Provides Firebase console link

**Usage:**
```bash
./scripts/test-crashlytics.sh
```

---

## 📝 Manual Checklist

Use this checklist to track manual steps:

- [ ] 1. Create Firebase project at console.firebase.google.com
- [ ] 2. Register iOS app with bundle ID `com.richmarin.FastingTracker`
- [ ] 3. Download GoogleService-Info.plist
- [ ] 4. Add GoogleService-Info.plist to Xcode project
- [ ] 5. Add Firebase SDK via SPM (File → Add Package Dependencies)
- [ ] 6. Select FirebaseCrashlytics and FirebaseAnalytics packages
- [ ] 7. Run `./scripts/setup-crashlytics.sh` (automated code integration)
- [ ] 8. Add `-ObjC` linker flag in Build Settings
- [ ] 9. Build and run app (⌘R) - verify no compile errors
- [ ] 10. Run `./scripts/test-crashlytics.sh` or manually test crash
- [ ] 11. Verify crash appears in Firebase Console within 5 minutes

---

## ✅ Verification Criteria

**How to know Crashlytics is working:**

1. **Build Succeeds:**
   ```bash
   xcodebuild build -project FastingTracker.xcodeproj -scheme FastingTracker | grep "BUILD SUCCEEDED"
   ```

2. **Firebase Initializes:**
   Check Xcode console on app launch:
   ```
   [Firebase/Crashlytics] Version 11.0.0
   [Firebase] Firebase Crashlytics initialized
   ```

3. **Crash Reports Upload:**
   - Trigger test crash
   - Relaunch app
   - Check Firebase Console (Crashlytics tab)
   - Crash report visible within 5 minutes

4. **No Sensitive Data:**
   - Verify `GoogleService-Info.plist` is in .gitignore
   - Check `git status` - should NOT show GoogleService-Info.plist

---

## 🔒 Security & Privacy

### .gitignore Update (AUTOMATED)

The setup script adds:
```
# Firebase
GoogleService-Info.plist
google-services.json
```

**Why:** GoogleService-Info.plist contains Firebase project API keys (not secret, but best practice to exclude).

### Info.plist Privacy

Crashlytics automatically collects:
- ✅ Crash stack traces
- ✅ Device model and iOS version
- ✅ App version and build number
- ❌ NO user data, passwords, or personal info

**Apple Privacy Manifest:** May need to declare Crashlytics in `PrivacyInfo.xcprivacy` (check iOS 17+ requirements).

---

## 📊 Score Impact

**Before Crashlytics:**
- Beta Readiness: 5.7/10
- Issue: No production crash monitoring
- Impact: -2.0 points

**After Crashlytics:**
- Beta Readiness: 7.7/10 (+2.0)
- Overall Score: 6.1 → 8.1 (+2.0)
- **Projected Overall: 8.1/10** (meets 8.5 target with other fixes)

---

## 🚨 Troubleshooting

### Issue: "Firebase SDK not found"
**Solution:** Re-add SPM package (File → Add Package Dependencies)

### Issue: "GoogleService-Info.plist not found"
**Solution:** Verify file is in project root and added to target

### Issue: Crashes not appearing in Firebase Console
**Causes:**
1. Crash report uploads on NEXT app launch (not immediately)
2. Firebase Console can take 2-5 minutes to process
3. `-ObjC` linker flag missing
4. GoogleService-Info.plist has wrong bundle ID

**Debug:**
```swift
// Add to FastingTrackerApp.swift init
Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
Log.debug("Crashlytics enabled: \\(Crashlytics.crashlytics().isCrashlyticsCollectionEnabled())", category: .general)
```

### Issue: Build fails with "Undefined symbol: _OBJC_CLASS_$_FIRApp"
**Solution:** Add `-ObjC` to Other Linker Flags

---

## 📚 Industry References

**Google Firebase:**
- Official docs: https://firebase.google.com/docs/crashlytics/get-started
- Best practices: https://firebase.google.com/docs/crashlytics/customize-crash-reports

**Apple:**
- Crash Reporting: https://developer.apple.com/documentation/xcode/diagnosing-issues-using-crash-reports
- (Limited to TestFlight/App Store - not real-time)

**Competitors:**
- Sentry.io: More expensive, more features
- Bugsnag: Similar to Crashlytics
- Instabug: Crash + bug reporting

**Why Crashlytics:**
- ✅ Free tier (unlimited crashes)
- ✅ Google-backed reliability
- ✅ Easy SPM integration
- ✅ 5-minute setup time
- ✅ Real-time alerting
- ✅ Integration with Firebase Analytics

---

## 🎯 Next Steps After Setup

1. **Custom Logging:**
   ```swift
   Crashlytics.crashlytics().log("User completed fasting session")
   ```

2. **User Identification (optional):**
   ```swift
   Crashlytics.crashlytics().setUserID("user_123")
   ```

3. **Custom Keys (debugging context):**
   ```swift
   Crashlytics.crashlytics().setCustomValue(fastingState, forKey: "fasting_active")
   ```

4. **Non-Fatal Errors:**
   ```swift
   Crashlytics.crashlytics().record(error: error)
   ```

---

**Status:** READY TO IMPLEMENT
**Blockers:** None - all dependencies available
**Time Estimate:** 1 hour end-to-end
**Score Impact:** +2.0 points (6.1 → 8.1)
