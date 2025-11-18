# 🛟 Troubleshooting Guide

**Common issues and solutions for Fast LIFe transformation**

---

## 📋 Quick Reference

| Issue | Phase | Solution | Time |
|-------|-------|----------|------|
| [Build fails after adding SPM](#1-spm-build-failures) | Phase 1 | Check dependencies | 5min |
| [Tests not running](#2-tests-not-running) | All | Fix scheme config | 10min |
| [SwiftData migration fails](#3-swiftdata-migration-fails) | Phase 1 | Delete app, rebuild | 5min |
| [Keychain errors](#4-keychain-errors) | Phase 0 | Reset simulator | 2min |
| [CI/CD pipeline fails](#5-cicd-pipeline-fails) | Phase 0 | Check secrets | 15min |
| [VoiceOver not working](#6-voiceover-not-working) | Phase 2 | Add labels | 30min |
| [Performance issues](#7-performance-issues) | Phase 2 | Profile with Instruments | 1h |
| [Memory leaks](#8-memory-leaks) | All | Fix retain cycles | 30min |
| [App Store rejection](#9-app-store-rejection) | Launch | Check privacy manifest | 1h |
| [HealthKit not working](#10-healthkit-not-working) | Phase 0 | Check entitlements | 15min |

---

## 1. SPM Build Failures

### Symptom
```
Command SwiftCompile failed with a nonzero exit code
Package.resolved is out of sync
```

### Cause
- Outdated Package.resolved
- Circular dependencies
- Wrong platform version

### Solution

**Step 1: Clean build folder**
```bash
# Xcode menu
Product > Clean Build Folder
# Or
rm -rf ~/Library/Developer/Xcode/DerivedData
```

**Step 2: Reset package cache**
```bash
# Xcode menu
File > Packages > Reset Package Caches

# Or command line
cd /Users/richmarin/fast-life
rm -rf .build
rm Package.resolved
```

**Step 3: Update packages**
```bash
# Xcode menu
File > Packages > Update to Latest Package Versions
```

**Step 4: Verify Package.swift**
```swift
// Ensure all packages have correct dependencies
let package = Package(
    name: "FeatureFasting",
    platforms: [.iOS(.v17)], // ✅ Correct version
    products: [
        .library(name: "FeatureFasting", targets: ["FeatureFasting"]),
    ],
    dependencies: [
        .package(path: "../Core"),           // ✅ Correct path
        .package(path: "../DesignSystem"),
        .package(path: "../DataLayer"),
    ],
    targets: [
        .target(
            name: "FeatureFasting",
            dependencies: ["Core", "DesignSystem", "DataLayer"]
        ),
    ]
)
```

**Prevention:**
- Always use relative paths (../Core) not absolute
- Keep all packages at same platform version (.iOS(.v17))
- Don't create circular dependencies (A depends on B, B depends on A)

---

## 2. Tests Not Running

### Symptom
```
Test suite 'All tests' started
Test suite 'All tests' finished (0 tests run)
```

### Cause
- Test target not added to scheme
- Test files not in target membership
- Test methods not prefixed with `test`

### Solution

**Step 1: Check test target membership**
```
1. Select test file (e.g., FastingRepositoryTests.swift)
2. Open File Inspector (⌘⌥1)
3. Verify "Target Membership" includes test target
4. If not, check the box
```

**Step 2: Check test scheme**
```
1. Product > Scheme > Edit Scheme
2. Select "Test" on left
3. Verify test targets are checked
4. If not, click "+" and add them
```

**Step 3: Verify test method naming**
```swift
// ❌ WRONG - won't run
func checkFastingStarts() { }

// ✅ CORRECT - will run
func testFastingStarts() { }
```

**Step 4: Run specific test**
```bash
# Run single test class
xcodebuild test \
  -workspace FastingTracker.xcworkspace \
  -scheme FastingTracker \
  -only-testing:FastingTrackerTests/FastingRepositoryTests

# Run single test method
xcodebuild test \
  -workspace FastingTracker.xcworkspace \
  -scheme FastingTracker \
  -only-testing:FastingTrackerTests/FastingRepositoryTests/testStartFasting
```

---

## 3. SwiftData Migration Fails

### Symptom
```
Fatal error: Failed to load ModelContainer
NSPersistentStoreCoordinator with no persistent stores
```

### Cause
- Schema changed without migration
- Corrupt SwiftData store
- Model conflicts

### Solution

**Step 1: Delete app and rebuild (Development)**
```bash
# Delete app from simulator
# Then rebuild

xcodebuild clean -workspace FastingTracker.xcworkspace -scheme FastingTracker
xcodebuild build -workspace FastingTracker.xcworkspace -scheme FastingTracker
```

**Step 2: Add migration (Production)**
```swift
import SwiftData

// Define schema versions
enum FastLifeSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [FastingSession.self, HydrationEntry.self, WeightEntry.self]
    }
}

enum FastLifeSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [FastingSession.self, HydrationEntry.self, WeightEntry.self, SleepEntry.self]
    }
}

// Migration plan
let migrationPlan = SchemaMigrationPlan(
    schemas: [FastLifeSchemaV1.self, FastLifeSchemaV2.self],
    stages: [
        MigrationStage.lightweight(fromVersion: FastLifeSchemaV1.self, toVersion: FastLifeSchemaV2.self)
    ]
)

// Use in container
let container = try ModelContainer(
    for: FastLifeSchemaV2.self,
    migrationPlan: migrationPlan
)
```

**Step 3: Find store location (Debug)**
```swift
// Add temporary code to find store
let container = try ModelContainer(for: schema)
if let url = container.configurations.first?.url {
    print("SwiftData store: \(url)")
}

// Inspect with SQLite browser
open -a "DB Browser for SQLite" /path/to/store
```

**Prevention:**
- Use lightweight migrations when possible
- Test migrations before releasing
- Back up data before schema changes

---

## 4. Keychain Errors

### Symptom
```
errSecItemNotFound (-25300)
errSecDuplicateItem (-25299)
Keychain save failed
```

### Cause
- Keychain item already exists
- Wrong access group
- Simulator keychain corrupt

### Solution

**Step 1: Delete existing item before save**
```swift
func save<T: Codable>(_ item: T, key: String) throws {
    let data = try JSONEncoder().encode(item)

    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: key,
        kSecValueData as String: data,
    ]

    // Delete existing item first
    SecItemDelete(query as CFDictionary)

    // Then save new
    let status = SecItemAdd(query as CFDictionary, nil)

    guard status == errSecSuccess else {
        throw KeychainError.saveFailed(status)
    }
}
```

**Step 2: Reset simulator (Development)**
```bash
# Reset simulator
Device > Erase All Content and Settings

# Or command line
xcrun simctl erase all
```

**Step 3: Check entitlements (Production)**
```xml
<!-- FastingTracker.entitlements -->
<key>keychain-access-groups</key>
<array>
    <string>$(AppIdentifierPrefix)com.fastlife.app</string>
</array>
```

**Step 4: Debug keychain operations**
```swift
func save<T: Codable>(_ item: T, key: String) throws {
    let data = try JSONEncoder().encode(item)

    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: key,
        kSecValueData as String: data,
    ]

    SecItemDelete(query as CFDictionary)

    let status = SecItemAdd(query as CFDictionary, nil)

    // Debug log
    print("Keychain save status: \(status)")
    if status != errSecSuccess {
        print("Error: \(SecCopyErrorMessageString(status, nil) ?? "Unknown" as CFString)")
    }

    guard status == errSecSuccess else {
        throw KeychainError.saveFailed(status)
    }
}
```

---

## 5. CI/CD Pipeline Fails

### Symptom
```
GitHub Actions: Build failed
Error: Missing signing certificate
Error: Archive failed
```

### Cause
- Missing secrets
- Wrong certificate
- Expired provisioning profile

### Solution

**Step 1: Check GitHub secrets**
```
1. Go to GitHub repo > Settings > Secrets and variables > Actions
2. Verify these secrets exist:
   - APPLE_CERTIFICATE_BASE64
   - APPLE_CERTIFICATE_PASSWORD
   - PROVISIONING_PROFILE_BASE64
   - KEYCHAIN_PASSWORD
```

**Step 2: Regenerate secrets**
```bash
# Export certificate
# Keychain Access > My Certificates > Right-click > Export

# Convert to base64
base64 -i Certificates.p12 | pbcopy

# Paste into GitHub secret: APPLE_CERTIFICATE_BASE64

# Export provisioning profile
# Xcode > Settings > Account > Download Manual Profiles
# Find in: ~/Library/MobileDevice/Provisioning Profiles/

base64 -i profile.mobileprovision | pbcopy

# Paste into GitHub secret: PROVISIONING_PROFILE_BASE64
```

**Step 3: Test locally**
```bash
# Run same commands as CI
xcodebuild clean \
  -workspace FastingTracker.xcworkspace \
  -scheme FastingTracker

xcodebuild test \
  -workspace FastingTracker.xcworkspace \
  -scheme FastingTracker \
  -destination 'platform=iOS Simulator,name=iPhone 15'

xcodebuild archive \
  -workspace FastingTracker.xcworkspace \
  -scheme FastingTracker \
  -archivePath ./build/FastingTracker.xcarchive
```

**Step 4: Check certificate expiration**
```bash
# View certificate details
security find-identity -v -p codesigning

# Check provisioning profile expiration
# Xcode > Settings > Account > Manage Certificates
```

---

## 6. VoiceOver Not Working

### Symptom
- VoiceOver doesn't read elements
- Custom controls not accessible
- Wrong labels announced

### Cause
- Missing accessibility labels
- Incorrect accessibility traits
- Elements marked as hidden

### Solution

**Step 1: Add labels to all interactive elements**
```swift
// ❌ BEFORE
Button("Start") {
    startFasting()
}

// ✅ AFTER
Button("Start") {
    startFasting()
}
.accessibilityLabel("Start 16 hour fasting session")
.accessibilityHint("Begins a new fasting timer")
```

**Step 2: Mark decorative images as hidden**
```swift
// ❌ BEFORE
Image(systemName: "flame.fill")
    .font(.largeTitle)

// ✅ AFTER
Image(systemName: "flame.fill")
    .font(.largeTitle)
    .accessibilityHidden(true) // Decorative only
```

**Step 3: Group related elements**
```swift
// ❌ BEFORE - VoiceOver reads separately
HStack {
    Text("Fasting Duration")
    Text("14:32")
}

// ✅ AFTER - VoiceOver reads combined
HStack {
    Text("Fasting Duration")
    Text("14:32")
}
.accessibilityElement(children: .combine)
.accessibilityLabel("Fasting duration: 14 hours 32 minutes")
```

**Step 4: Test with VoiceOver**
```
1. Enable VoiceOver: Settings > Accessibility > VoiceOver
2. Swipe right to navigate
3. Verify all elements announce correctly
4. Test all interactions
```

**Step 5: Use Accessibility Inspector**
```
1. Xcode > Open Developer Tool > Accessibility Inspector
2. Select simulator
3. Click inspect button
4. Hover over elements to see accessibility info
5. Run audit to find issues
```

---

## 7. Performance Issues

### Symptom
- Slow app launch (>2s)
- Laggy scrolling
- High CPU usage
- Memory warnings

### Cause
- Loading too much data on startup
- Blocking main thread
- Memory leaks
- Inefficient queries

### Solution

**Step 1: Profile with Instruments**
```bash
# Build for profiling
xcodebuild -workspace FastingTracker.xcworkspace \
  -scheme FastingTracker \
  -configuration Release \
  build

# Open Instruments
open -a Instruments

# Select "Time Profiler"
# Record app launch
# Identify heavy functions (>100ms)
```

**Step 2: Lazy load data**
```swift
// ❌ BEFORE - loads all data on startup
func loadData() async {
    let allSessions = try? await fastingRepository.getAllSessions() // 1000s of items
    self.sessions = allSessions ?? []
}

// ✅ AFTER - loads only recent data
func loadRecentData() async {
    let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    let recent = try? await fastingRepository.getSessionsInRange(from: weekAgo, to: Date())
    self.recentSessions = recent ?? []
}
```

**Step 3: Use async let for parallel loading**
```swift
// ❌ BEFORE - sequential loading (slow)
let fasting = try await fastingRepository.getActiveFasting()
let hydration = try await hydrationRepository.getTodayTotal()
let weight = try await weightRepository.getLatestEntry()
let sleep = try await sleepRepository.getAverageSleepDuration(days: 7)

// ✅ AFTER - parallel loading (fast)
async let fasting = fastingRepository.getActiveFasting()
async let hydration = hydrationRepository.getTodayTotal()
async let weight = weightRepository.getLatestEntry()
async let sleep = sleepRepository.getAverageSleepDuration(days: 7)

let (f, h, w, s) = try await (fasting, hydration, weight, sleep)
```

**Step 4: Virtualize long lists**
```swift
// ❌ BEFORE - renders all 1000 items
ScrollView {
    VStack {
        ForEach(allSessions) { session in
            SessionRow(session: session)
        }
    }
}

// ✅ AFTER - renders only visible items
List(recentSessions) { session in
    SessionRow(session: session)
}
```

**Step 5: Monitor memory**
```
1. Xcode > Debug > Memory Graph Debugger
2. Look for large objects
3. Check for retain cycles
4. Use weak/unowned for delegates
```

---

## 8. Memory Leaks

### Symptom
- Memory usage grows over time
- App crashes with memory warnings
- Debug navigator shows growing memory

### Cause
- Retain cycles (strong references)
- Closures capturing self
- NotificationCenter observers not removed

### Solution

**Step 1: Use weak self in closures**
```swift
// ❌ BEFORE - retain cycle
class FastingViewModel {
    var updateTimer: Timer?

    func startTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.update() // Strong capture of self
        }
    }
}

// ✅ AFTER - no retain cycle
class FastingViewModel {
    var updateTimer: Timer?

    func startTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.update() // Weak capture
        }
    }

    deinit {
        updateTimer?.invalidate()
    }
}
```

**Step 2: Remove observers**
```swift
// ❌ BEFORE - observer never removed
class FastingViewModel {
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNotification),
            name: .fastingEnded,
            object: nil
        )
    }
}

// ✅ AFTER - observer removed
class FastingViewModel {
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNotification),
            name: .fastingEnded,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
```

**Step 3: Use Instruments Leaks tool**
```
1. Open Instruments
2. Select "Leaks" template
3. Record app usage
4. Review leaked objects
5. Fix retain cycles
```

**Step 4: Debug Memory Graph**
```
1. Xcode > Debug > Debug Memory Graph
2. Look for purple warnings (leaks)
3. Select leaked object
4. View backtrace to find cause
```

---

## 9. App Store Rejection

### Symptom
```
Guideline 2.1 - Performance
Your app crashed on launch

Guideline 5.1.2 - Legal - Privacy
Missing privacy manifest
```

### Cause
- Missing PrivacyInfo.xcprivacy
- Missing required reason APIs
- Crashes on specific devices

### Solution

**Step 1: Add privacy manifest**
```xml
<!-- PrivacyInfo.xcprivacy -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array>
        <dict>
            <key>NSPrivacyCollectedDataType</key>
            <string>NSPrivacyCollectedDataTypeHealthAndFitness</string>
            <key>NSPrivacyCollectedDataTypeLinked</key>
            <false/>
            <key>NSPrivacyCollectedDataTypeTracking</key>
            <false/>
            <key>NSPrivacyCollectedDataTypePurposes</key>
            <array>
                <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
            </array>
        </dict>
    </array>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

**Step 2: Test on device**
```
1. Build for device (not simulator)
2. Test all features
3. Check crash logs (Window > Devices and Simulators)
4. Fix device-specific issues
```

**Step 3: Review App Store Connect feedback**
```
1. Log in to App Store Connect
2. Check rejection reason details
3. Fix specific issues mentioned
4. Resubmit with resolution notes
```

---

## 10. HealthKit Not Working

### Symptom
```
HealthKit authorization not appearing
Unable to read sleep data
Error: HealthKit not available
```

### Cause
- Missing entitlements
- Not requesting authorization
- Simulator doesn't support HealthKit

### Solution

**Step 1: Add HealthKit entitlement**
```
1. Select FastingTracker target
2. Signing & Capabilities tab
3. Click "+ Capability"
4. Add "HealthKit"
5. Check "Clinical Health Records" if needed
```

**Step 2: Add privacy description**
```xml
<!-- Info.plist -->
<key>NSHealthShareUsageDescription</key>
<string>Fast LIFe needs access to read your sleep data to track your sleep patterns and health progress.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>Fast LIFe needs permission to save your fasting, hydration, and weight data to Apple Health.</string>
```

**Step 3: Request authorization**
```swift
import HealthKit

actor HealthKitManager {
    private let healthStore = HKHealthStore()

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let types: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .dietaryWater)!,
            HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        ]

        try await healthStore.requestAuthorization(toShare: types, read: types)
    }
}
```

**Step 4: Test on device (HealthKit not in simulator)**
```
1. Build and run on physical device
2. Go to Settings > Health
3. Verify authorization prompt appears
4. Grant permission
5. Test data read/write
```

---

## 📞 Still Stuck?

**If issue not listed:**
1. Check [Apple Developer Forums](https://developer.apple.com/forums/)
2. Search [Stack Overflow](https://stackoverflow.com/questions/tagged/swiftui)
3. Review [Swift Forums](https://forums.swift.org/)
4. Check GitHub issues for dependencies

**Prevention:**
- Commit frequently (can rollback)
- Test after each major change
- Keep dependencies updated
- Read error messages carefully
- Use version control branches

---

## 🎯 Common Patterns

**When something breaks:**
1. Read the error message completely
2. Google the exact error
3. Check if recent change caused it (git diff)
4. Try the solutions above
5. Rollback if needed (git reset)
6. Ask for help if stuck >1 hour

**When tests fail:**
1. Run single test to isolate issue
2. Check test target membership
3. Verify mock data is correct
4. Add print statements to debug
5. Use XCTest breakpoints

**When app crashes:**
1. Check crash log (Console.app)
2. Enable Exception Breakpoint
3. Look at backtrace
4. Fix the specific line
5. Add defensive code (guard, nil checks)

---

**[⬅️ Back to Process Improvements](../PROCESS_IMPROVEMENTS_ACTION_PLAN.md)** | **[📖 Master Plan](../ENTERPRISE_TRANSFORMATION_MASTER.md)**
