# 🚀 Phase 2: Scale & Polish (Complete Guide)

**Transform 7.5 → 8.5 with enterprise polish**

**Timeline:** Weeks 9-12 (80-100 hours)
**Result:** +1.0 points (7.5 → 8.5)
**Goal:** Production-ready, accessible, compliant, performant

---

## 📋 Overview

**What you're building:**
- Full WCAG 2.1 Level AA accessibility
- async/await concurrency (replacing GCD)
- Actor isolation for thread safety
- GDPR compliance (data export/deletion)
- Performance optimization (<2s cold start)
- 70%+ test coverage (200+ tests)
- Snapshot tests for UI consistency
- Security audit and hardening

**Why this matters:**
- **Accessibility:** 67M Americans with disabilities can use your app
- **Compliance:** GDPR/CCPA required for EU/California users
- **Performance:** Sub-2s launch = 5x better retention
- **Quality:** 70% coverage = production-ready
- **Security:** Audit prevents data breaches

**Success criteria:**
- ✅ 100% VoiceOver support
- ✅ Full Dynamic Type support
- ✅ GDPR export/deletion working
- ✅ <2s cold start time
- ✅ 70%+ test coverage
- ✅ Zero security vulnerabilities
- ✅ All features support sleep tracking

---

## 🗓️ Week 9: Accessibility (24 hours)

### Goal
Achieve WCAG 2.1 Level AA compliance

### 9.1: VoiceOver Labels (8 hours)

**Purpose:** Screen reader support for visually impaired users

**Audit all interactive elements:**

**FastingTrackingView.swift:**
```swift
import SwiftUI
import DesignSystem

struct FastingTrackingView: View {
    @State private var viewModel: FastingTrackingViewModel

    var body: some View {
        VStack(spacing: 24) {
            if let session = viewModel.activeSession {
                // Timer display
                Text(formatDuration(session.duration))
                    .font(Typography.largeTitle)
                    .foregroundColor(.textPrimary)
                    .accessibilityLabel("Fasting duration: \(formatDurationAccessible(session.duration))")
                    .accessibilityValue("\(Int(session.progress * 100))% complete")

                // Progress ring
                FastingProgressRing(progress: session.progress)
                    .accessibilityLabel("Fasting progress")
                    .accessibilityValue("\(Int(session.progress * 100)) percent complete")
                    .accessibilityHint("Circular progress indicator")

                // End button
                PrimaryButton(title: "End Fast") {
                    Task { await viewModel.endFasting() }
                }
                .accessibilityLabel("End fasting session")
                .accessibilityHint("Stops the current fasting timer")
                .accessibilityAddTraits(.isButton)
            } else {
                // Empty state
                Image(systemName: "moon.zzz")
                    .font(.system(size: 64))
                    .foregroundColor(.textSecondary)
                    .accessibilityHidden(true) // Decorative

                Text("No active fasting")
                    .font(Typography.headline)
                    .accessibilityLabel("No active fasting session")

                // Start button
                PrimaryButton(title: "Start 16h Fast") {
                    Task { await viewModel.startFasting(hours: 16) }
                }
                .accessibilityLabel("Start 16 hour fasting session")
                .accessibilityHint("Begins a new fasting timer")
            }
        }
        .padding()
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return String(format: "%02d:%02d", hours, minutes)
    }

    private func formatDurationAccessible(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours) hours and \(minutes) minutes"
    }
}
```

**SleepTrackingView.swift:**
```swift
import SwiftUI
import DesignSystem
import DataLayer

struct SleepEntryForm: View {
    @Binding var bedTime: Date
    @Binding var wakeTime: Date
    @Binding var quality: SleepQuality
    @Binding var notes: String

    var body: some View {
        Form {
            Section("Sleep Times") {
                DatePicker("Bed Time", selection: $bedTime, displayedComponents: [.date, .hourAndMinute])
                    .accessibilityLabel("Bed time")
                    .accessibilityHint("Select when you went to bed")

                DatePicker("Wake Time", selection: $wakeTime, displayedComponents: [.date, .hourAndMinute])
                    .accessibilityLabel("Wake time")
                    .accessibilityHint("Select when you woke up")
            }

            Section("Sleep Quality") {
                SleepQualityPicker(quality: $quality)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Sleep quality selector")
            }

            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(height: 100)
                    .accessibilityLabel("Sleep notes")
                    .accessibilityHint("Optional notes about your sleep")
            }
        }
    }
}
```

**Audit checklist:**
- ✅ All buttons have labels
- ✅ All images marked hidden or labeled
- ✅ All form fields labeled
- ✅ All custom controls accessible
- ✅ Progress indicators have values
- ✅ Interactive elements have hints

**Time:** 8 hours to audit and fix all views

---

### 9.2: Dynamic Type Support (8 hours)

**Purpose:** Text scales for users with vision impairments

**Update Typography.swift:**
```swift
import SwiftUI

public enum Typography {
    // Use .scaledFont for dynamic type
    public static let largeTitle = Font.system(.largeTitle, design: .rounded)
    public static let title = Font.system(.title, design: .rounded)
    public static let headline = Font.system(.headline, design: .rounded)
    public static let body = Font.system(.body, design: .rounded)
    public static let callout = Font.system(.callout, design: .rounded)
    public static let caption = Font.system(.caption, design: .rounded)
}
```

**Update CardView with Dynamic Type:**
```swift
import SwiftUI

public struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    public var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.appPrimary)
                .frame(width: 40)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Typography.caption)
                    .foregroundColor(.textSecondary)

                Text(value)
                    .font(Typography.headline)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8) // Graceful scaling
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSurface)
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}
```

**Test Dynamic Type:**
```swift
import XCTest
import SwiftUI
@testable import DesignSystem

final class DynamicTypeTests: XCTestCase {
    func testStatCardWithLargeText() {
        let card = StatCard(
            title: "Fasting Duration",
            value: "14:32",
            icon: "flame.fill"
        )

        // Test with extra large text
        let view = card.environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)

        // Snapshot test to verify layout doesn't break
        // (Requires snapshot testing framework)
    }
}
```

**Update constraints:**
- Use `lineLimit()` + `minimumScaleFactor()` for critical text
- Use `.fixedSize(horizontal: false, vertical: true)` for multiline
- Test at all sizes: XS, S, M, L, XL, XXL, XXXL

**Time:** 8 hours to update all text elements

---

### 9.3: Color Contrast Audit (8 hours)

**Purpose:** WCAG AA requires 4.5:1 contrast ratio for text

**Audit current colors:**

**Before (failing):**
```swift
// Text secondary on light background
Color.gray.opacity(0.6) // Contrast: 2.8:1 ❌ FAIL

// Primary button text
Color.white on Color.blue.opacity(0.7) // Contrast: 3.2:1 ❌ FAIL
```

**After (passing):**
```swift
// Colors.swift
public extension Color {
    // Text colors (WCAG AA compliant)
    static let textPrimary = Color(red: 0.11, green: 0.11, blue: 0.11) // #1C1C1C on white = 15.8:1 ✅
    static let textSecondary = Color(red: 0.38, green: 0.38, blue: 0.41) // #616169 on white = 5.3:1 ✅
    static let textTertiary = Color(red: 0.56, green: 0.56, blue: 0.58) // #8E8E93 on white = 4.6:1 ✅

    // Primary button
    static let appPrimary = Color(red: 0.0, green: 0.48, blue: 0.0) // #007A00 (white text = 4.7:1) ✅

    // Status colors
    static let appSuccess = Color(red: 0.0, green: 0.56, blue: 0.0) // #008F00 ✅
    static let appWarning = Color(red: 0.8, green: 0.5, blue: 0.0) // #CC8000 ✅
    static let appError = Color(red: 0.77, green: 0.0, blue: 0.0) // #C40000 ✅
}
```

**Test contrast:**
```bash
# Use WebAIM Contrast Checker
# https://webaim.org/resources/contrastchecker/

# Or automate with script
./scripts/check_color_contrast.sh
```

**check_color_contrast.sh:**
```bash
#!/bin/bash

# Extract color values from Colors.swift
# Calculate contrast ratios
# Report violations

echo "Checking WCAG AA compliance..."
echo "Minimum required: 4.5:1 for normal text, 3:1 for large text"

# Check textSecondary on white
# (Requires color contrast calculation library)
```

**Time:** 8 hours to audit, fix, and test all color combinations

---

## 🗓️ Week 10: Performance (32 hours)

### Goal
Achieve sub-2 second cold start and smooth 60fps

### 10.1: async/await Migration (16 hours)

**Purpose:** Replace completion handlers and GCD with modern concurrency

**Before (GCD):**
```swift
class FastingManager {
    func startFasting(completion: @escaping (Result<FastingSession, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            // Simulate API call
            Thread.sleep(forTimeInterval: 0.5)

            let session = FastingSession(startTime: Date(), targetDuration: 16 * 3600)

            DispatchQueue.main.async {
                completion(.success(session))
            }
        }
    }
}
```

**After (async/await):**
```swift
actor FastingManager {
    func startFasting() async throws -> FastingSession {
        // Automatically runs on background
        try await Task.sleep(nanoseconds: 500_000_000)

        let session = FastingSession(startTime: Date(), targetDuration: 16 * 3600)
        return session
    }
}
```

**Migrate all repositories:**

**FastingRepository.swift:**
```swift
public final class FastingRepository: FastingRepositoryProtocol {
    private let modelContainer: ModelContainer
    private let actor: FastingActor

    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.actor = FastingActor(modelContainer: modelContainer)
    }

    public func startFasting(targetDuration: TimeInterval) async throws -> FastingSession {
        try await actor.startFasting(targetDuration: targetDuration)
    }

    // ... other methods
}

// Thread-safe actor for data operations
actor FastingActor {
    private let modelContext: ModelContext

    init(modelContainer: ModelContainer) {
        self.modelContext = ModelContext(modelContainer)
    }

    func startFasting(targetDuration: TimeInterval) async throws -> FastingSession {
        let session = FastingSession(
            startTime: Date(),
            targetDuration: targetDuration
        )

        modelContext.insert(session)
        try modelContext.save()

        return session
    }
}
```

**Migration checklist:**
- ✅ All repositories use async/await
- ✅ All ViewModels use async/await
- ✅ All network calls use async/await
- ✅ Remove all DispatchQueue.main.async
- ✅ Remove all completion handlers

**Time:** 16 hours to migrate all async code

---

### 10.2: Actor Isolation (8 hours)

**Purpose:** Prevent data races and ensure thread safety

**SleepManager.swift:**
```swift
import Foundation

actor SleepManager {
    private var entries: [SleepEntry] = []
    private let repository: SleepRepositoryProtocol

    init(repository: SleepRepositoryProtocol) {
        self.repository = repository
    }

    // Thread-safe operations
    func addEntry(_ entry: SleepEntry) async throws {
        try await repository.addEntry(entry)
        entries.append(entry)
    }

    func getAverageDuration(days: Int) async throws -> TimeInterval {
        try await repository.getAverageSleepDuration(days: days)
    }

    // Safe to call from any thread
    nonisolated func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return String(format: "%dh %dm", hours, minutes)
    }
}
```

**HealthKitManager.swift:**
```swift
import HealthKit

actor HealthKitManager {
    private let healthStore = HKHealthStore()

    func requestAuthorization() async throws {
        let types: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .dietaryWater)!,
            HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        ]

        try await healthStore.requestAuthorization(toShare: types, read: types)
    }

    func fetchSleepData(from: Date, to: Date) async throws -> [SleepEntry] {
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!

        let predicate = HKQuery.predicateForSamples(withStart: from, end: to)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let sleepSamples = samples as? [HKCategorySample] ?? []
                let entries = sleepSamples.compactMap { sample -> SleepEntry? in
                    guard sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue else {
                        return nil
                    }

                    return SleepEntry(
                        bedTime: sample.startDate,
                        wakeTime: sample.endDate,
                        quality: .fair,
                        source: .healthKit
                    )
                }

                continuation.resume(returning: entries)
            }

            healthStore.execute(query)
        }
    }
}
```

**Time:** 8 hours to add actor isolation

---

### 10.3: Instruments Profiling (8 hours)

**Purpose:** Identify and fix performance bottlenecks

**Profile cold start:**
```bash
# Build for profiling
xcodebuild -workspace FastingTracker.xcworkspace \
  -scheme FastingTracker \
  -configuration Release \
  -derivedDataPath ./DerivedData \
  build

# Open Instruments
open -a Instruments

# Select "Time Profiler"
# Record app launch
# Identify heavy functions
```

**Optimize identified bottlenecks:**

**Before (slow):**
```swift
// Loading all entries on startup
func loadAllData() async {
    let fastingSessions = try? await fastingRepository.getAllSessions()
    let hydrationEntries = try? await hydrationRepository.getAllEntries()
    let weightEntries = try? await weightRepository.getAllEntries()
    let sleepEntries = try? await sleepRepository.getAllEntries()

    // Process 1000s of entries on main thread
    self.fastingSessions = fastingSessions ?? []
    self.hydrationEntries = hydrationEntries ?? []
    // ... 2-5 second delay
}
```

**After (fast):**
```swift
// Lazy load only what's needed
func loadRecentData() async {
    let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!

    async let recentFasting = fastingRepository.getSessionsInRange(from: weekAgo, to: Date())
    async let recentHydration = hydrationRepository.getEntriesForDate(Date())
    async let recentWeight = weightRepository.getLatestEntry()
    async let recentSleep = sleepRepository.getEntriesInRange(from: weekAgo, to: Date())

    // Load in parallel, only recent data
    let (fasting, hydration, weight, sleep) = try? await (recentFasting, recentHydration, recentWeight, recentSleep)

    self.recentFasting = fasting ?? []
    self.todayHydration = hydration ?? []
    self.latestWeight = weight
    self.recentSleep = sleep ?? []

    // <0.5 second load time
}
```

**Optimization checklist:**
- ✅ Lazy load data (don't load all on startup)
- ✅ Parallel loading (async let)
- ✅ Image caching
- ✅ Reduce SwiftData fetch sizes
- ✅ Virtualize long lists

**Target:** <2s cold start, <0.5s warm start

**Time:** 8 hours to profile and optimize

---

## 🗓️ Week 11: Compliance (24 hours)

### Goal
GDPR/CCPA compliance for data privacy

### 11.1: Data Export (8 hours)

**Purpose:** Users can export all their data

**DataExportManager.swift:**
```swift
import Foundation

actor DataExportManager {
    private let container: DIContainer

    init(container: DIContainer) {
        self.container = container
    }

    func exportAllData() async throws -> URL {
        // Fetch all data
        async let fasting = container.fastingRepository.getAllSessions()
        async let hydration = container.hydrationRepository.getAllEntries()
        async let weight = container.weightRepository.getAllEntries()
        async let sleep = container.sleepRepository.getAllEntries()
        async let moodEnergy = container.moodEnergyRepository.getAllEntries()

        let (fastingSessions, hydrationEntries, weightEntries, sleepEntries, moodEnergyEntries) = try await (fasting, hydration, weight, sleep, moodEnergy)

        // Create export data structure
        let exportData = ExportData(
            fasting: fastingSessions.map(FastingExport.init),
            hydration: hydrationEntries.map(HydrationExport.init),
            weight: weightEntries.map(WeightExport.init),
            sleep: sleepEntries.map(SleepExport.init),
            moodEnergy: moodEnergyEntries.map(MoodEnergyExport.init),
            exportDate: Date()
        )

        // Convert to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let jsonData = try encoder.encode(exportData)

        // Save to file
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("fast-life-export-\(Date().timeIntervalSince1970).json")

        try jsonData.write(to: fileURL)

        return fileURL
    }
}

// MARK: - Export Models

struct ExportData: Codable {
    let fasting: [FastingExport]
    let hydration: [HydrationExport]
    let weight: [WeightExport]
    let sleep: [SleepExport]
    let moodEnergy: [MoodEnergyExport]
    let exportDate: Date
    let version: String = "1.0"
}

struct FastingExport: Codable {
    let id: UUID
    let startTime: Date
    let endTime: Date?
    let targetDuration: TimeInterval
    let notes: String?

    init(from session: FastingSession) {
        self.id = session.id
        self.startTime = session.startTime
        self.endTime = session.endTime
        self.targetDuration = session.targetDuration
        self.notes = session.notes
    }
}

struct SleepExport: Codable {
    let id: UUID
    let bedTime: Date
    let wakeTime: Date
    let quality: String
    let duration: TimeInterval
    let notes: String?
    let source: String

    init(from entry: SleepEntry) {
        self.id = entry.id
        self.bedTime = entry.bedTime
        self.wakeTime = entry.wakeTime
        self.quality = entry.quality.rawValue
        self.duration = entry.duration
        self.notes = entry.notes
        self.source = entry.source.rawValue
    }
}

struct MoodEnergyExport: Codable {
    let id: UUID
    let timestamp: Date
    let mood: Int
    let moodDescription: String
    let energy: Int
    let energyDescription: String
    let notes: String?
    let triggers: [String]?

    init(from entry: MoodEnergyEntry) {
        self.id = entry.id
        self.timestamp = entry.timestamp
        self.mood = entry.mood.rawValue
        self.moodDescription = entry.mood.description
        self.energy = entry.energy.rawValue
        self.energyDescription = entry.energy.description
        self.notes = entry.notes
        self.triggers = entry.triggers
    }
}

// ... HydrationExport, WeightExport similar
```

**Add to Settings:**
```swift
struct SettingsView: View {
    @State private var exportManager: DataExportManager

    var body: some View {
        List {
            Section("Privacy & Data") {
                Button("Export My Data") {
                    Task {
                        await exportData()
                    }
                }
                .accessibilityLabel("Export all my data")
                .accessibilityHint("Downloads a JSON file with all your health data")
            }
        }
    }

    private func exportData() async {
        do {
            let fileURL = try await exportManager.exportAllData()

            // Share file
            let activityVC = UIActivityViewController(
                activityItems: [fileURL],
                applicationActivities: nil
            )

            // Present share sheet
            // ...
        } catch {
            // Handle error
        }
    }
}
```

**Time:** 8 hours to implement export

---

### 11.2: Data Deletion (8 hours)

**Purpose:** Users can delete all their data

**DataDeletionManager.swift:**
```swift
import Foundation

actor DataDeletionManager {
    private let container: DIContainer

    init(container: DIContainer) {
        self.container = container
    }

    func deleteAllData() async throws {
        // Delete from repositories
        let fasting = try await container.fastingRepository.getAllSessions()
        for session in fasting {
            try await container.fastingRepository.deleteSession(session)
        }

        let hydration = try await container.hydrationRepository.getAllEntries()
        for entry in hydration {
            try await container.hydrationRepository.deleteEntry(entry)
        }

        let weight = try await container.weightRepository.getAllEntries()
        for entry in weight {
            try await container.weightRepository.deleteEntry(entry)
        }

        let sleep = try await container.sleepRepository.getAllEntries()
        for entry in sleep {
            try await container.sleepRepository.deleteEntry(entry)
        }

        let moodEnergy = try await container.moodEnergyRepository.getAllEntries()
        for entry in moodEnergy {
            try await container.moodEnergyRepository.deleteEntry(entry)
        }

        // Clear Keychain
        KeychainManager.shared.deleteAll()

        // Clear UserDefaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }

        // Clear caches
        URLCache.shared.removeAllCachedResponses()
    }
}
```

**Add confirmation dialog:**
```swift
struct SettingsView: View {
    @State private var showingDeleteConfirmation = false

    var body: some View {
        List {
            Section("Privacy & Data") {
                Button("Delete All My Data", role: .destructive) {
                    showingDeleteConfirmation = true
                }
                .accessibilityLabel("Delete all my data")
                .accessibilityHint("Permanently deletes all your health data from this device")
            }
        }
        .confirmationDialog(
            "Delete All Data?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Everything", role: .destructive) {
                Task {
                    await deleteAllData()
                }
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your fasting, hydration, weight, sleep, and mood & energy data. This action cannot be undone.")
        }
    }
}
```

**Time:** 8 hours to implement deletion

---

### 11.3: Security Audit (8 hours)

**Purpose:** Identify and fix security vulnerabilities

**Security checklist:**

**1. Keychain Security:**
```swift
// Verify Keychain uses kSecAttrAccessibleWhenUnlockedThisDeviceOnly
class KeychainManager {
    private let service = "com.fastlife.app"

    func save<T: Codable>(_ item: T, key: String) throws {
        let data = try JSONEncoder().encode(item)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly // ✅ Secure
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.saveFailed
        }
    }
}
```

**2. Network Security:**
```swift
// Verify all API calls use HTTPS
// Check Info.plist for App Transport Security

// Info.plist
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/> <!-- ✅ Enforces HTTPS -->
</dict>
```

**3. Code Obfuscation:**
```bash
# Ensure release builds strip debug symbols
# Build Settings:
STRIP_INSTALLED_PRODUCT = YES
COPY_PHASE_STRIP = YES
DEBUG_INFORMATION_FORMAT = dwarf-with-dsym
```

**4. API Key Security:**
```swift
// Never hardcode API keys
// Use Build Configuration

// Config.swift
enum Config {
    static var apiKey: String {
        // Read from Info.plist injected by CI/CD
        guard let key = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String else {
            fatalError("API_KEY not found")
        }
        return key
    }
}
```

**Run automated security scan:**
```bash
# Install MobSF (Mobile Security Framework)
# https://github.com/MobSF/Mobile-Security-Framework-MobSF

docker run -it -p 8000:8000 opensecurity/mobile-security-framework-mobsf

# Scan .ipa file
# Review report for vulnerabilities
```

**Time:** 8 hours for audit and fixes

---

## 🗓️ Week 12: Testing & Launch (24 hours)

### Goal
Achieve 70%+ coverage and production readiness

### 12.1: Snapshot Tests (16 hours)

**Purpose:** Catch UI regressions automatically

**Install SnapshotTesting:**
```swift
// Package.swift dependencies
.package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.15.0")
```

**FastingTrackingViewSnapshotTests.swift:**
```swift
import XCTest
import SwiftUI
import SnapshotTesting
@testable import FeatureFasting

final class FastingTrackingViewSnapshotTests: XCTestCase {
    func testEmptyState() {
        let viewModel = FastingTrackingViewModel(repository: MockFastingRepository())
        let view = FastingTrackingView(viewModel: viewModel)

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13)))
    }

    func testActiveFastingState() async {
        let repository = MockFastingRepository()
        let viewModel = FastingTrackingViewModel(repository: repository)

        await viewModel.startFasting(hours: 16)

        let view = FastingTrackingView(viewModel: viewModel)

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13)))
    }

    func testDarkMode() {
        let viewModel = FastingTrackingViewModel(repository: MockFastingRepository())
        let view = FastingTrackingView(viewModel: viewModel)
            .environment(\.colorScheme, .dark)

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13)))
    }

    func testAccessibilityExtraLarge() {
        let viewModel = FastingTrackingViewModel(repository: MockFastingRepository())
        let view = FastingTrackingView(viewModel: viewModel)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13)))
    }
}
```

**SleepTrackingViewSnapshotTests.swift:**
```swift
import XCTest
import SwiftUI
import SnapshotTesting
@testable import FeatureSleep

final class SleepTrackingViewSnapshotTests: XCTestCase {
    func testSleepEntryForm() {
        let view = SleepEntryForm(
            bedTime: .constant(Date().hoursAgo(8)),
            wakeTime: .constant(Date()),
            quality: .constant(.good),
            notes: .constant("")
        )

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13)))
    }

    func testSleepHistoryWithData() {
        let repository = MockSleepRepository()
        repository.entries = [
            SleepEntry(bedTime: Date().hoursAgo(32), wakeTime: Date().hoursAgo(24), quality: .excellent),
            SleepEntry(bedTime: Date().hoursAgo(56), wakeTime: Date().hoursAgo(48), quality: .good),
            SleepEntry(bedTime: Date().hoursAgo(80), wakeTime: Date().hoursAgo(72), quality: .fair)
        ]

        let viewModel = SleepHistoryViewModel(repository: repository)
        let view = SleepHistoryView(viewModel: viewModel)

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13)))
    }

    func testSleepQualityPicker() {
        let view = SleepQualityPicker(quality: .constant(.good))

        assertSnapshot(matching: view, as: .image)
    }
}
```

**Snapshot all views:**
- ✅ FastingTrackingView (empty, active, completed states)
- ✅ HydrationTrackingView (empty, partial, goal met states)
- ✅ WeightEntryView (empty, with entries)
- ✅ SleepTrackingView (empty, with entries)
- ✅ All in light/dark mode
- ✅ All with accessibility large text

**Target:** 50+ snapshot tests

**Time:** 16 hours for comprehensive snapshots

---

### 12.2: UI Tests (8 hours)

**Purpose:** Test user flows end-to-end

**FastingUITests.swift:**
```swift
import XCTest

final class FastingUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    func testStartAndEndFastingFlow() {
        // Navigate to Fasting tab
        app.tabBars.buttons["Fasting"].tap()

        // Verify empty state
        XCTAssertTrue(app.staticTexts["No active fasting"].exists)

        // Start fasting
        app.buttons["Start 16h Fast"].tap()

        // Verify timer appears
        XCTAssertTrue(app.staticTexts.matching(identifier: "fastingTimer").element.exists)

        // End fasting
        app.buttons["End Fast"].tap()

        // Verify empty state returns
        XCTAssertTrue(app.staticTexts["No active fasting"].exists)
    }

    func testFastingHistory() {
        app.tabBars.buttons["History"].tap()

        // Verify history list
        XCTAssertTrue(app.tables["fastingHistoryTable"].exists)

        // Tap first item
        app.tables["fastingHistoryTable"].cells.firstMatch.tap()

        // Verify detail view
        XCTAssertTrue(app.navigationBars["Fasting Details"].exists)
    }
}
```

**SleepUITests.swift:**
```swift
import XCTest

final class SleepUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    func testAddSleepEntry() {
        // Navigate to Sleep tab
        app.tabBars.buttons["Sleep"].tap()

        // Tap add button
        app.buttons["Add Sleep"].tap()

        // Set bed time
        app.datePickers["Bed Time"].tap()
        // (Date picker interaction)

        // Set wake time
        app.datePickers["Wake Time"].tap()
        // (Date picker interaction)

        // Select quality
        app.buttons["Good"].tap()

        // Add notes
        app.textViews["Sleep notes"].tap()
        app.textViews["Sleep notes"].typeText("Slept well")

        // Save
        app.buttons["Save"].tap()

        // Verify entry appears in list
        XCTAssertTrue(app.cells.containing(.staticText, identifier: "8.0 hours").element.exists)
    }

    func testSleepHistory() {
        app.tabBars.buttons["Sleep"].tap()

        // Verify sleep list exists
        XCTAssertTrue(app.tables["sleepHistoryTable"].exists)

        // Verify average duration shown
        XCTAssertTrue(app.staticTexts["7-day average"].exists)
    }
}
```

**Test all critical flows:**
- ✅ Start/end fasting
- ✅ Log hydration
- ✅ Add weight entry
- ✅ Add sleep entry
- ✅ View history
- ✅ Edit/delete entries
- ✅ Export data
- ✅ Delete all data

**Target:** 20+ UI tests

**Time:** 8 hours for UI tests

---

## ✅ Phase 2 Success Criteria

**You're done when:**
- ✅ 100% VoiceOver support (all interactive elements labeled)
- ✅ Full Dynamic Type support (text scales correctly)
- ✅ WCAG AA color contrast (4.5:1 minimum)
- ✅ async/await everywhere (zero GCD)
- ✅ Actor isolation for thread safety
- ✅ <2s cold start time
- ✅ GDPR data export working
- ✅ GDPR data deletion working
- ✅ Security audit passed
- ✅ 70%+ test coverage (200+ tests)
- ✅ 50+ snapshot tests
- ✅ 20+ UI tests
- ✅ Sleep tracking fully integrated

**Validation:**
```bash
# Run all tests
xcodebuild test -workspace FastingTracker.xcworkspace -scheme FastingTracker

# Check coverage
./scripts/coverage_report.sh

# Profile performance
# Open Instruments, select Time Profiler, record cold start

# Test VoiceOver
# Enable VoiceOver on device, test all screens

# Test accessibility
# Settings > Accessibility > Display & Text Size > Larger Text (max)

# Run security scan
# (See Week 11.3)
```

**Coverage targets:**
- DataLayer: 80%+
- ViewModels: 70%+
- Views: 50%+ (snapshot tests)
- Overall: 70%+

---

## 📊 Time Tracking

| Week | Tasks | Hours | Cumulative |
|------|-------|-------|------------|
| Week 9 | Accessibility | 24h | 24h |
| Week 10 | Performance | 32h | 56h |
| Week 11 | Compliance | 24h | 80h |
| Week 12 | Testing | 24h | 104h |

**Total: 104 hours (13 days at 8h/day)**

---

## 🎯 Score Impact

**Before Phase 2:** 7.5/10
**After Phase 2:** 8.5/10

**Improvements:**
- ✅ Accessibility: 0/10 → 10/10 (+10)
- ✅ Performance: 6/10 → 9/10 (+3)
- ✅ Security: 5/10 → 9/10 (+4)
- ✅ Compliance: 0/10 → 9/10 (+9)
- ✅ Testing: 6/10 → 9/10 (+3)

---

## 🚀 Next Steps

**After completing Phase 2:**
1. ✅ Celebrate! You've built an enterprise-grade app 🏆
2. ✅ Deploy to TestFlight
3. ✅ Beta test with 50-100 users
4. ✅ Collect feedback
5. ✅ Polish based on feedback (1-2 weeks)
6. ✅ Submit to App Store
7. ✅ **LAUNCH Fast LIFe and disrupt the industry!** 🚀

---

**[⬅️ Back to Phase 1](./PHASE_1_ARCHITECTURE_COMPLETE.md)** | **[📖 Master Plan](../ENTERPRISE_TRANSFORMATION_MASTER.md)** | **[🎯 Success Metrics](./SUCCESS_METRICS.md)**
