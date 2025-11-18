# 🏗️ Phase 1: Architecture & Modularization (Complete Guide)

**Transform 5.5 → 7.5 with enterprise architecture**

**Timeline:** Weeks 4-8 (120-160 hours)
**Result:** +2.0 points (5.5 → 7.5)
**Goal:** Single source of truth + modular architecture

---

## 📋 Overview

**What you're building:**
- Swift Package Manager (SPM) modularization
- SwiftData-based DataLayer with Repository pattern
- Dependency Injection container
- 5 feature packages (Fasting, Hydration, Weight, Sleep, **Mood & Energy**)
- 125+ unit tests (40%+ coverage)

**Why this matters:**
- **Testability:** Can test features in isolation
- **Reusability:** Design system used across features
- **Maintainability:** Changes don't cascade across app
- **Team scalability:** Multiple devs work in parallel
- **Build times:** Only changed packages rebuild

**Success criteria:**
- ✅ All business logic in isolated packages
- ✅ Zero tight coupling between features
- ✅ Single source of truth for all data
- ✅ 40%+ test coverage (100+ tests)
- ✅ All data flows through repositories

---

## 🗓️ Week 4: SPM Package Structure (32 hours)

### Goal
Create the modular foundation using Swift Package Manager

### Tasks

#### 4.1: Create Core Package (8 hours)

**Purpose:** Shared utilities, extensions, protocols

**Structure:**
```
Packages/Core/
├── Package.swift
└── Sources/
    └── Core/
        ├── Extensions/
        │   ├── Date+Extensions.swift
        │   ├── String+Extensions.swift
        │   └── View+Extensions.swift
        ├── Utilities/
        │   ├── Constants.swift
        │   ├── Formatters.swift
        │   └── Validators.swift
        └── Protocols/
            ├── Identifiable.swift
            └── Timestampable.swift
```

**Package.swift:**
```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Core",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "Core",
            targets: ["Core"]
        ),
    ],
    targets: [
        .target(
            name: "Core",
            dependencies: []
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"]
        ),
    ]
)
```

**Key Files:**

**Date+Extensions.swift:**
```swift
import Foundation

public extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }

    func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }

    func hoursAgo(_ hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: -hours, to: self)!
    }
}
```

**Formatters.swift:**
```swift
import Foundation

public enum AppFormatters {
    public static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    public static let date: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    public static let duration: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    public static let weight: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }()
}
```

---

#### 4.2: Create DesignSystem Package (8 hours)

**Purpose:** Reusable UI components, tokens, styles

**Structure:**
```
Packages/DesignSystem/
├── Package.swift
└── Sources/
    └── DesignSystem/
        ├── Tokens/
        │   ├── Colors.swift
        │   ├── Typography.swift
        │   ├── Spacing.swift
        │   └── AnimationDurations.swift
        ├── Components/
        │   ├── PrimaryButton.swift
        │   ├── SecondaryButton.swift
        │   ├── CardView.swift
        │   ├── StatCard.swift
        │   └── EmptyStateView.swift
        └── Modifiers/
            ├── CardStyle.swift
            └── AccessibleModifier.swift
```

**Colors.swift:**
```swift
import SwiftUI

public extension Color {
    // Primary
    static let appPrimary = Color("Primary", bundle: .module)
    static let appSecondary = Color("Secondary", bundle: .module)

    // Semantic
    static let appSuccess = Color("Success", bundle: .module)
    static let appWarning = Color("Warning", bundle: .module)
    static let appError = Color("Error", bundle: .module)

    // Neutrals
    static let appBackground = Color("Background", bundle: .module)
    static let appSurface = Color("Surface", bundle: .module)
    static let appBorder = Color("Border", bundle: .module)

    // Text
    static let textPrimary = Color("TextPrimary", bundle: .module)
    static let textSecondary = Color("TextSecondary", bundle: .module)
    static let textTertiary = Color("TextTertiary", bundle: .module)
}
```

**Typography.swift:**
```swift
import SwiftUI

public enum Typography {
    public static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    public static let title = Font.system(size: 28, weight: .bold, design: .rounded)
    public static let headline = Font.system(size: 20, weight: .semibold, design: .rounded)
    public static let body = Font.system(size: 17, weight: .regular, design: .rounded)
    public static let callout = Font.system(size: 16, weight: .regular, design: .rounded)
    public static let caption = Font.system(size: 14, weight: .regular, design: .rounded)
}
```

**PrimaryButton.swift:**
```swift
import SwiftUI

public struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    public init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.appPrimary)
                .cornerRadius(12)
        }
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}
```

**CardView.swift:**
```swift
import SwiftUI

public struct CardView<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding()
            .background(Color.appSurface)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}
```

---

#### 4.3: Create DataLayer Structure (8 hours)

**Purpose:** Foundation for Repository pattern with SwiftData

**Structure:**
```
Packages/DataLayer/
├── Package.swift
└── Sources/
    └── DataLayer/
        ├── Models/
        │   ├── FastingSession.swift
        │   ├── WeightEntry.swift
        │   ├── HydrationEntry.swift
        │   ├── SleepEntry.swift
        │   └── MoodEnergyEntry.swift     ← NEW
        ├── Repositories/
        │   ├── Protocols/
        │   │   ├── FastingRepositoryProtocol.swift
        │   │   ├── WeightRepositoryProtocol.swift
        │   │   ├── HydrationRepositoryProtocol.swift
        │   │   ├── SleepRepositoryProtocol.swift
        │   │   └── MoodEnergyRepositoryProtocol.swift    ← NEW
        │   └── Implementation/
        │       ├── FastingRepository.swift
        │       ├── WeightRepository.swift
        │       ├── HydrationRepository.swift
        │       ├── SleepRepository.swift
        │       └── MoodEnergyRepository.swift            ← NEW
        └── Container/
            └── DataContainer.swift
```

**Package.swift:**
```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DataLayer",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "DataLayer",
            targets: ["DataLayer"]
        ),
    ],
    dependencies: [
        .package(path: "../Core")
    ],
    targets: [
        .target(
            name: "DataLayer",
            dependencies: ["Core"]
        ),
        .testTarget(
            name: "DataLayerTests",
            dependencies: ["DataLayer"]
        ),
    ]
)
```

**Models:**

**FastingSession.swift:**
```swift
import SwiftData
import Foundation

@Model
public final class FastingSession {
    public var id: UUID
    public var startTime: Date
    public var endTime: Date?
    public var targetDuration: TimeInterval
    public var notes: String?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date? = nil,
        targetDuration: TimeInterval = 16 * 3600,
        notes: String? = nil
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.targetDuration = targetDuration
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    public var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }

    public var isActive: Bool {
        endTime == nil
    }

    public var progress: Double {
        duration / targetDuration
    }
}
```

**SleepEntry.swift:**
```swift
import SwiftData
import Foundation

@Model
public final class SleepEntry {
    public var id: UUID
    public var bedTime: Date
    public var wakeTime: Date
    public var quality: SleepQuality
    public var notes: String?
    public var source: DataSource
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        bedTime: Date,
        wakeTime: Date,
        quality: SleepQuality = .fair,
        notes: String? = nil,
        source: DataSource = .manual
    ) {
        self.id = id
        self.bedTime = bedTime
        self.wakeTime = wakeTime
        self.quality = quality
        self.notes = notes
        self.source = source
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    public var duration: TimeInterval {
        wakeTime.timeIntervalSince(bedTime)
    }

    public var durationHours: Double {
        duration / 3600
    }

    public var isComplete: Bool {
        wakeTime > bedTime
    }

    public var sleepDate: Date {
        bedTime.startOfDay
    }
}

public enum SleepQuality: String, Codable {
    case poor
    case fair
    case good
    case excellent

    public var emoji: String {
        switch self {
        case .poor: return "😴"
        case .fair: return "😐"
        case .good: return "😊"
        case .excellent: return "🌟"
        }
    }

    public var score: Int {
        switch self {
        case .poor: return 1
        case .fair: return 2
        case .good: return 3
        case .excellent: return 4
        }
    }
}

public enum DataSource: String, Codable {
    case manual
    case healthKit
    case appleWatch
    case other
}
```

**WeightEntry.swift:**
```swift
import SwiftData
import Foundation

@Model
public final class WeightEntry {
    public var id: UUID
    public var weight: Double // in kg
    public var date: Date
    public var notes: String?
    public var source: DataSource
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        weight: Double,
        date: Date = Date(),
        notes: String? = nil,
        source: DataSource = .manual
    ) {
        self.id = id
        self.weight = weight
        self.date = date
        self.notes = notes
        self.source = source
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    public var weightInPounds: Double {
        weight * 2.20462
    }
}
```

**HydrationEntry.swift:**
```swift
import SwiftData
import Foundation

@Model
public final class HydrationEntry {
    public var id: UUID
    public var amount: Double // in ml
    public var timestamp: Date
    public var beverage: BeverageType
    public var notes: String?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        amount: Double,
        timestamp: Date = Date(),
        beverage: BeverageType = .water,
        notes: String? = nil
    ) {
        self.id = id
        self.amount = amount
        self.timestamp = timestamp
        self.beverage = beverage
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    public var amountInOunces: Double {
        amount / 29.5735
    }
}

public enum BeverageType: String, Codable {
    case water
    case tea
    case coffee
    case juice
    case other
}
```

**MoodEnergyEntry.swift:**
```swift
import SwiftData
import Foundation

@Model
public final class MoodEnergyEntry {
    public var id: UUID
    public var timestamp: Date
    public var mood: MoodLevel
    public var energy: EnergyLevel
    public var notes: String?
    public var triggers: [String]?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        mood: MoodLevel = .neutral,
        energy: EnergyLevel = .moderate,
        notes: String? = nil,
        triggers: [String]? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.mood = mood
        self.energy = energy
        self.notes = notes
        self.triggers = triggers
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

public enum MoodLevel: Int, Codable {
    case veryBad = 1
    case bad = 2
    case neutral = 3
    case good = 4
    case veryGood = 5

    public var emoji: String {
        switch self {
        case .veryBad: return "😢"
        case .bad: return "😕"
        case .neutral: return "😐"
        case .good: return "🙂"
        case .veryGood: return "😄"
        }
    }

    public var description: String {
        switch self {
        case .veryBad: return "Very Bad"
        case .bad: return "Bad"
        case .neutral: return "Neutral"
        case .good: return "Good"
        case .veryGood: return "Very Good"
        }
    }
}

public enum EnergyLevel: Int, Codable {
    case veryLow = 1
    case low = 2
    case moderate = 3
    case high = 4
    case veryHigh = 5

    public var emoji: String {
        switch self {
        case .veryLow: return "🪫"
        case .low: return "🔋"
        case .moderate: return "🔋🔋"
        case .high: return "⚡"
        case .veryHigh: return "⚡⚡"
        }
    }

    public var description: String {
        switch self {
        case .veryLow: return "Very Low"
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        case .veryHigh: return "Very High"
        }
    }
}
```

---

#### 4.4: Implement FastingRepository (8 hours)

**Protocol:**

**FastingRepositoryProtocol.swift:**
```swift
import Foundation

public protocol FastingRepositoryProtocol {
    // READ
    func getActiveFasting() async throws -> FastingSession?
    func getAllSessions() async throws -> [FastingSession]
    func getSessionsInRange(from: Date, to: Date) async throws -> [FastingSession]
    func getSession(id: UUID) async throws -> FastingSession?

    // WRITE
    func startFasting(targetDuration: TimeInterval) async throws -> FastingSession
    func endFasting(session: FastingSession) async throws
    func updateSession(_ session: FastingSession) async throws
    func deleteSession(_ session: FastingSession) async throws

    // OBSERVE
    func observeActiveFasting() -> AsyncStream<FastingSession?>
    func observeAllSessions() -> AsyncStream<[FastingSession]>
}
```

**Implementation:**

**FastingRepository.swift:**
```swift
import SwiftData
import Foundation

public final class FastingRepository: FastingRepositoryProtocol {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext

    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.modelContext = ModelContext(modelContainer)
    }

    // MARK: - READ

    public func getActiveFasting() async throws -> FastingSession? {
        let descriptor = FetchDescriptor<FastingSession>(
            predicate: #Predicate { $0.endTime == nil },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        let sessions = try modelContext.fetch(descriptor)
        return sessions.first
    }

    public func getAllSessions() async throws -> [FastingSession] {
        let descriptor = FetchDescriptor<FastingSession>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        return try modelContext.fetch(descriptor)
    }

    public func getSessionsInRange(from: Date, to: Date) async throws -> [FastingSession] {
        let descriptor = FetchDescriptor<FastingSession>(
            predicate: #Predicate { session in
                session.startTime >= from && session.startTime <= to
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        return try modelContext.fetch(descriptor)
    }

    public func getSession(id: UUID) async throws -> FastingSession? {
        let descriptor = FetchDescriptor<FastingSession>(
            predicate: #Predicate { $0.id == id }
        )

        let sessions = try modelContext.fetch(descriptor)
        return sessions.first
    }

    // MARK: - WRITE

    public func startFasting(targetDuration: TimeInterval) async throws -> FastingSession {
        // End any active sessions first
        if let activeSession = try await getActiveFasting() {
            try await endFasting(session: activeSession)
        }

        let session = FastingSession(
            startTime: Date(),
            targetDuration: targetDuration
        )

        modelContext.insert(session)
        try modelContext.save()

        return session
    }

    public func endFasting(session: FastingSession) async throws {
        session.endTime = Date()
        session.updatedAt = Date()
        try modelContext.save()
    }

    public func updateSession(_ session: FastingSession) async throws {
        session.updatedAt = Date()
        try modelContext.save()
    }

    public func deleteSession(_ session: FastingSession) async throws {
        modelContext.delete(session)
        try modelContext.save()
    }

    // MARK: - OBSERVE

    public func observeActiveFasting() -> AsyncStream<FastingSession?> {
        AsyncStream { continuation in
            Task {
                while !Task.isCancelled {
                    if let session = try? await getActiveFasting() {
                        continuation.yield(session)
                    }
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                }
                continuation.finish()
            }
        }
    }

    public func observeAllSessions() -> AsyncStream<[FastingSession]> {
        AsyncStream { continuation in
            Task {
                while !Task.isCancelled {
                    if let sessions = try? await getAllSessions() {
                        continuation.yield(sessions)
                    }
                    try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                }
                continuation.finish()
            }
        }
    }
}
```

---

## 🗓️ Week 5: DataLayer Completion (40 hours)

### Goal
Complete all repository implementations

### Tasks

#### 5.1: Implement HydrationRepository (8 hours)

**HydrationRepositoryProtocol.swift:**
```swift
import Foundation

public protocol HydrationRepositoryProtocol {
    // READ
    func getAllEntries() async throws -> [HydrationEntry]
    func getEntriesForDate(_ date: Date) async throws -> [HydrationEntry]
    func getTodayTotal() async throws -> Double
    func getWeeklyAverage() async throws -> Double

    // WRITE
    func addEntry(_ entry: HydrationEntry) async throws
    func updateEntry(_ entry: HydrationEntry) async throws
    func deleteEntry(_ entry: HydrationEntry) async throws

    // OBSERVE
    func observeTodayEntries() -> AsyncStream<[HydrationEntry]>
    func observeTodayTotal() -> AsyncStream<Double>
}
```

**HydrationRepository.swift:**
```swift
import SwiftData
import Foundation

public final class HydrationRepository: HydrationRepositoryProtocol {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext

    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.modelContext = ModelContext(modelContainer)
    }

    public func getAllEntries() async throws -> [HydrationEntry] {
        let descriptor = FetchDescriptor<HydrationEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    public func getEntriesForDate(_ date: Date) async throws -> [HydrationEntry] {
        let startOfDay = date.startOfDay
        let endOfDay = date.endOfDay

        let descriptor = FetchDescriptor<HydrationEntry>(
            predicate: #Predicate { entry in
                entry.timestamp >= startOfDay && entry.timestamp <= endOfDay
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        return try modelContext.fetch(descriptor)
    }

    public func getTodayTotal() async throws -> Double {
        let entries = try await getEntriesForDate(Date())
        return entries.reduce(0) { $0 + $1.amount }
    }

    public func getWeeklyAverage() async throws -> Double {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!

        let descriptor = FetchDescriptor<HydrationEntry>(
            predicate: #Predicate { $0.timestamp >= weekAgo }
        )

        let entries = try modelContext.fetch(descriptor)
        let totalAmount = entries.reduce(0) { $0 + $1.amount }
        return totalAmount / 7
    }

    public func addEntry(_ entry: HydrationEntry) async throws {
        modelContext.insert(entry)
        try modelContext.save()
    }

    public func updateEntry(_ entry: HydrationEntry) async throws {
        entry.updatedAt = Date()
        try modelContext.save()
    }

    public func deleteEntry(_ entry: HydrationEntry) async throws {
        modelContext.delete(entry)
        try modelContext.save()
    }

    public func observeTodayEntries() -> AsyncStream<[HydrationEntry]> {
        AsyncStream { continuation in
            Task {
                while !Task.isCancelled {
                    if let entries = try? await getEntriesForDate(Date()) {
                        continuation.yield(entries)
                    }
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                }
                continuation.finish()
            }
        }
    }

    public func observeTodayTotal() -> AsyncStream<Double> {
        AsyncStream { continuation in
            Task {
                while !Task.isCancelled {
                    if let total = try? await getTodayTotal() {
                        continuation.yield(total)
                    }
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                }
                continuation.finish()
            }
        }
    }
}
```

---

#### 5.2: Implement WeightRepository (8 hours)

**WeightRepositoryProtocol.swift:**
```swift
import Foundation

public protocol WeightRepositoryProtocol {
    // READ
    func getAllEntries() async throws -> [WeightEntry]
    func getLatestEntry() async throws -> WeightEntry?
    func getEntriesInRange(from: Date, to: Date) async throws -> [WeightEntry]
    func getWeightTrend(days: Int) async throws -> [WeightEntry]

    // WRITE
    func addEntry(_ entry: WeightEntry) async throws
    func updateEntry(_ entry: WeightEntry) async throws
    func deleteEntry(_ entry: WeightEntry) async throws

    // OBSERVE
    func observeLatestEntry() -> AsyncStream<WeightEntry?>
    func observeAllEntries() -> AsyncStream<[WeightEntry]>
}
```

Follow similar pattern to HydrationRepository.

---

#### 5.3: Implement SleepRepository (8 hours)

**SleepRepositoryProtocol.swift:**
```swift
import Foundation

public protocol SleepRepositoryProtocol {
    // READ
    func getAllEntries() async throws -> [SleepEntry]
    func getEntriesInRange(from: Date, to: Date) async throws -> [SleepEntry]
    func getAverageSleepDuration(days: Int) async throws -> TimeInterval
    func getSleepQualityTrend(days: Int) async throws -> [SleepQuality]
    func getEntryForDate(_ date: Date) async throws -> SleepEntry?

    // WRITE
    func addEntry(_ entry: SleepEntry) async throws
    func updateEntry(_ entry: SleepEntry) async throws
    func deleteEntry(_ entry: SleepEntry) async throws

    // OBSERVE
    func observeEntries() -> AsyncStream<[SleepEntry]>
}
```

**SleepRepository.swift:**
```swift
import SwiftData
import Foundation

public final class SleepRepository: SleepRepositoryProtocol {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext

    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.modelContext = ModelContext(modelContainer)
    }

    public func getAllEntries() async throws -> [SleepEntry] {
        let descriptor = FetchDescriptor<SleepEntry>(
            sortBy: [SortDescriptor(\.bedTime, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    public func getEntriesInRange(from: Date, to: Date) async throws -> [SleepEntry] {
        let descriptor = FetchDescriptor<SleepEntry>(
            predicate: #Predicate { entry in
                entry.bedTime >= from && entry.bedTime <= to
            },
            sortBy: [SortDescriptor(\.bedTime, order: .reverse)]
        )

        return try modelContext.fetch(descriptor)
    }

    public func getAverageSleepDuration(days: Int) async throws -> TimeInterval {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let entries = try await getEntriesInRange(from: startDate, to: Date())

        guard !entries.isEmpty else { return 0 }

        let totalDuration = entries.reduce(0.0) { $0 + $1.duration }
        return totalDuration / Double(entries.count)
    }

    public func getSleepQualityTrend(days: Int) async throws -> [SleepQuality] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let entries = try await getEntriesInRange(from: startDate, to: Date())
        return entries.map { $0.quality }
    }

    public func getEntryForDate(_ date: Date) async throws -> SleepEntry? {
        let startOfDay = date.startOfDay
        let endOfDay = date.endOfDay

        let descriptor = FetchDescriptor<SleepEntry>(
            predicate: #Predicate { entry in
                entry.bedTime >= startOfDay && entry.bedTime <= endOfDay
            }
        )

        let entries = try modelContext.fetch(descriptor)
        return entries.first
    }

    public func addEntry(_ entry: SleepEntry) async throws {
        modelContext.insert(entry)
        try modelContext.save()
    }

    public func updateEntry(_ entry: SleepEntry) async throws {
        entry.updatedAt = Date()
        try modelContext.save()
    }

    public func deleteEntry(_ entry: SleepEntry) async throws {
        modelContext.delete(entry)
        try modelContext.save()
    }

    public func observeEntries() -> AsyncStream<[SleepEntry]> {
        AsyncStream { continuation in
            Task {
                while !Task.isCancelled {
                    if let entries = try? await getAllEntries() {
                        continuation.yield(entries)
                    }
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                }
                continuation.finish()
            }
        }
    }
}
```

---

#### 5.4: Implement MoodEnergyRepository (8 hours)

**MoodEnergyRepositoryProtocol.swift:**
```swift
import Foundation

public protocol MoodEnergyRepositoryProtocol {
    // READ
    func getAllEntries() async throws -> [MoodEnergyEntry]
    func getEntriesForDate(_ date: Date) async throws -> [MoodEnergyEntry]
    func getAverageMood(days: Int) async throws -> Double
    func getAverageEnergy(days: Int) async throws -> Double
    func getMoodTrend(days: Int) async throws -> [MoodLevel]
    func getEnergyTrend(days: Int) async throws -> [EnergyLevel]

    // WRITE
    func addEntry(_ entry: MoodEnergyEntry) async throws
    func updateEntry(_ entry: MoodEnergyEntry) async throws
    func deleteEntry(_ entry: MoodEnergyEntry) async throws

    // OBSERVE
    func observeEntries() -> AsyncStream<[MoodEnergyEntry]>
}
```

**MoodEnergyRepository.swift:**
```swift
import SwiftData
import Foundation

public final class MoodEnergyRepository: MoodEnergyRepositoryProtocol {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext

    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.modelContext = ModelContext(modelContainer)
    }

    public func getAllEntries() async throws -> [MoodEnergyEntry] {
        let descriptor = FetchDescriptor<MoodEnergyEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    public func getEntriesForDate(_ date: Date) async throws -> [MoodEnergyEntry] {
        let startOfDay = date.startOfDay
        let endOfDay = date.endOfDay

        let descriptor = FetchDescriptor<MoodEnergyEntry>(
            predicate: #Predicate { entry in
                entry.timestamp >= startOfDay && entry.timestamp <= endOfDay
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        return try modelContext.fetch(descriptor)
    }

    public func getAverageMood(days: Int) async throws -> Double {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let entries = try await getEntriesInRange(from: startDate, to: Date())

        guard !entries.isEmpty else { return 0 }

        let totalScore = entries.reduce(0.0) { $0 + Double($1.mood.rawValue) }
        return totalScore / Double(entries.count)
    }

    public func getAverageEnergy(days: Int) async throws -> Double {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let entries = try await getEntriesInRange(from: startDate, to: Date())

        guard !entries.isEmpty else { return 0 }

        let totalScore = entries.reduce(0.0) { $0 + Double($1.energy.rawValue) }
        return totalScore / Double(entries.count)
    }

    public func getMoodTrend(days: Int) async throws -> [MoodLevel] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let entries = try await getEntriesInRange(from: startDate, to: Date())
        return entries.map { $0.mood }
    }

    public func getEnergyTrend(days: Int) async throws -> [EnergyLevel] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let entries = try await getEntriesInRange(from: startDate, to: Date())
        return entries.map { $0.energy }
    }

    private func getEntriesInRange(from: Date, to: Date) async throws -> [MoodEnergyEntry] {
        let descriptor = FetchDescriptor<MoodEnergyEntry>(
            predicate: #Predicate { entry in
                entry.timestamp >= from && entry.timestamp <= to
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        return try modelContext.fetch(descriptor)
    }

    public func addEntry(_ entry: MoodEnergyEntry) async throws {
        modelContext.insert(entry)
        try modelContext.save()
    }

    public func updateEntry(_ entry: MoodEnergyEntry) async throws {
        entry.updatedAt = Date()
        try modelContext.save()
    }

    public func deleteEntry(_ entry: MoodEnergyEntry) async throws {
        modelContext.delete(entry)
        try modelContext.save()
    }

    public func observeEntries() -> AsyncStream<[MoodEnergyEntry]> {
        AsyncStream { continuation in
            Task {
                while !Task.isCancelled {
                    if let entries = try? await getAllEntries() {
                        continuation.yield(entries)
                    }
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                }
                continuation.finish()
            }
        }
    }
}
```

---

#### 5.5: Dependency Injection Container (8 hours)

**DIContainer.swift:**
```swift
import SwiftData
import Foundation

public final class DIContainer {
    public static let shared = DIContainer()

    private let modelContainer: ModelContainer

    // Repositories
    public lazy var fastingRepository: FastingRepositoryProtocol = {
        FastingRepository(modelContainer: modelContainer)
    }()

    public lazy var hydrationRepository: HydrationRepositoryProtocol = {
        HydrationRepository(modelContainer: modelContainer)
    }()

    public lazy var weightRepository: WeightRepositoryProtocol = {
        WeightRepository(modelContainer: modelContainer)
    }()

    public lazy var sleepRepository: SleepRepositoryProtocol = {
        SleepRepository(modelContainer: modelContainer)
    }()

    public lazy var moodEnergyRepository: MoodEnergyRepositoryProtocol = {
        MoodEnergyRepository(modelContainer: modelContainer)
    }()

    private init() {
        do {
            let schema = Schema([
                FastingSession.self,
                HydrationEntry.self,
                WeightEntry.self,
                SleepEntry.self,
                MoodEnergyEntry.self
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )

            self.modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    // For testing
    public static func preview() -> DIContainer {
        let container = DIContainer()
        return container
    }
}
```

---

## 🗓️ Weeks 6-7: Feature Packages (60 hours)

### Goal
Create isolated feature packages using DesignSystem and DataLayer

### 6.1: FeatureFasting Package (16 hours)

**Structure:**
```
Packages/FeatureFasting/
├── Package.swift
└── Sources/
    └── FeatureFasting/
        ├── Views/
        │   ├── FastingTrackingView.swift
        │   └── FastingHistoryView.swift
        ├── ViewModels/
        │   ├── FastingTrackingViewModel.swift
        │   └── FastingHistoryViewModel.swift
        └── Components/
            ├── FastingTimerView.swift
            └── FastingProgressRing.swift
```

**FastingTrackingViewModel.swift:**
```swift
import Foundation
import Observation
import DataLayer

@Observable
public final class FastingTrackingViewModel {
    private let repository: FastingRepositoryProtocol

    public var activeSession: FastingSession?
    public var isLoading = false
    public var error: Error?

    public init(repository: FastingRepositoryProtocol) {
        self.repository = repository
        Task {
            await loadActiveSession()
            await observeActiveSession()
        }
    }

    @MainActor
    private func loadActiveSession() async {
        isLoading = true
        defer { isLoading = false }

        do {
            activeSession = try await repository.getActiveFasting()
        } catch {
            self.error = error
        }
    }

    @MainActor
    private func observeActiveSession() async {
        for await session in repository.observeActiveFasting() {
            activeSession = session
        }
    }

    @MainActor
    public func startFasting(hours: Int) async {
        do {
            let targetDuration = TimeInterval(hours * 3600)
            activeSession = try await repository.startFasting(targetDuration: targetDuration)
        } catch {
            self.error = error
        }
    }

    @MainActor
    public func endFasting() async {
        guard let session = activeSession else { return }

        do {
            try await repository.endFasting(session: session)
            activeSession = nil
        } catch {
            self.error = error
        }
    }
}
```

**FastingTrackingView.swift:**
```swift
import SwiftUI
import DesignSystem
import DataLayer

public struct FastingTrackingView: View {
    @State private var viewModel: FastingTrackingViewModel

    public init(viewModel: FastingTrackingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 24) {
            if let session = viewModel.activeSession {
                FastingTimerView(session: session)

                PrimaryButton(title: "End Fast") {
                    Task {
                        await viewModel.endFasting()
                    }
                }
                .accessibilityLabel("End fasting session")
            } else {
                Text("No active fasting")
                    .font(Typography.headline)
                    .foregroundColor(.textSecondary)

                PrimaryButton(title: "Start 16h Fast") {
                    Task {
                        await viewModel.startFasting(hours: 16)
                    }
                }
                .accessibilityLabel("Start 16 hour fasting session")
            }
        }
        .padding()
    }
}
```

---

### 6.2: FeatureHydration Package (12 hours)

Similar structure to FeatureFasting:
- HydrationTrackingView
- HydrationHistoryView
- HydrationTrackingViewModel
- HydrationHistoryViewModel
- WaterIntakeButton component

---

### 6.3: FeatureWeight Package (12 hours)

Similar structure:
- WeightEntryView
- WeightHistoryView
- WeightTrendChart
- WeightEntryViewModel

---

### 6.4: FeatureSleep Package (12 hours)

**Structure:**
```
Packages/FeatureSleep/
├── Package.swift
└── Sources/
    └── FeatureSleep/
        ├── Views/
        │   ├── SleepTrackingView.swift
        │   └── SleepHistoryView.swift
        ├── ViewModels/
        │   ├── SleepTrackingViewModel.swift
        │   └── SleepHistoryViewModel.swift
        └── Components/
            ├── SleepQualityPicker.swift
            └── SleepDurationChart.swift
```

**SleepTrackingViewModel.swift:**
```swift
import Foundation
import Observation
import DataLayer

@Observable
public final class SleepTrackingViewModel {
    private let repository: SleepRepositoryProtocol

    public var entries: [SleepEntry] = []
    public var averageDuration: TimeInterval = 0
    public var isLoading = false
    public var error: Error?

    public init(repository: SleepRepositoryProtocol) {
        self.repository = repository
        Task {
            await loadEntries()
            await loadAverageDuration()
        }
    }

    @MainActor
    private func loadEntries() async {
        isLoading = true
        defer { isLoading = false }

        do {
            entries = try await repository.getAllEntries()
        } catch {
            self.error = error
        }
    }

    @MainActor
    private func loadAverageDuration() async {
        do {
            averageDuration = try await repository.getAverageSleepDuration(days: 7)
        } catch {
            self.error = error
        }
    }

    @MainActor
    public func addEntry(bedTime: Date, wakeTime: Date, quality: SleepQuality, notes: String?) async {
        let entry = SleepEntry(
            bedTime: bedTime,
            wakeTime: wakeTime,
            quality: quality,
            notes: notes
        )

        do {
            try await repository.addEntry(entry)
            await loadEntries()
            await loadAverageDuration()
        } catch {
            self.error = error
        }
    }

    @MainActor
    public func deleteEntry(_ entry: SleepEntry) async {
        do {
            try await repository.deleteEntry(entry)
            await loadEntries()
            await loadAverageDuration()
        } catch {
            self.error = error
        }
    }
}
```

**SleepQualityPicker.swift:**
```swift
import SwiftUI
import DesignSystem
import DataLayer

public struct SleepQualityPicker: View {
    @Binding var quality: SleepQuality

    public init(quality: Binding<SleepQuality>) {
        self._quality = quality
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sleep Quality")
                .font(Typography.headline)
                .foregroundColor(.textPrimary)

            HStack(spacing: 12) {
                ForEach([SleepQuality.poor, .fair, .good, .excellent], id: \.self) { q in
                    Button {
                        quality = q
                    } label: {
                        VStack(spacing: 4) {
                            Text(q.emoji)
                                .font(.system(size: 32))
                            Text(q.rawValue.capitalized)
                                .font(Typography.caption)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(quality == q ? Color.appPrimary.opacity(0.2) : Color.appSurface)
                        .cornerRadius(12)
                    }
                    .accessibilityLabel("\(q.rawValue.capitalized) sleep quality")
                    .accessibilityAddTraits(quality == q ? [.isButton, .isSelected] : .isButton)
                }
            }
        }
    }
}
```

---

### 6.5: FeatureMoodEnergy Package (12 hours)

**Structure:**
```
Packages/FeatureMoodEnergy/
├── Package.swift
└── Sources/
    └── FeatureMoodEnergy/
        ├── Views/
        │   ├── MoodEnergyTrackingView.swift
        │   └── MoodEnergyHistoryView.swift
        ├── ViewModels/
        │   ├── MoodEnergyTrackingViewModel.swift
        │   └── MoodEnergyHistoryViewModel.swift
        └── Components/
            ├── MoodPicker.swift
            ├── EnergyPicker.swift
            └── TriggersList.swift
```

**MoodEnergyTrackingViewModel.swift:**
```swift
import Foundation
import Observation
import DataLayer

@Observable
public final class MoodEnergyTrackingViewModel {
    private let repository: MoodEnergyRepositoryProtocol

    public var entries: [MoodEnergyEntry] = []
    public var averageMood: Double = 0
    public var averageEnergy: Double = 0
    public var isLoading = false
    public var error: Error?

    public init(repository: MoodEnergyRepositoryProtocol) {
        self.repository = repository
        Task {
            await loadEntries()
            await loadAverages()
        }
    }

    @MainActor
    private func loadEntries() async {
        isLoading = true
        defer { isLoading = false }

        do {
            entries = try await repository.getAllEntries()
        } catch {
            self.error = error
        }
    }

    @MainActor
    private func loadAverages() async {
        do {
            averageMood = try await repository.getAverageMood(days: 7)
            averageEnergy = try await repository.getAverageEnergy(days: 7)
        } catch {
            self.error = error
        }
    }

    @MainActor
    public func addEntry(mood: MoodLevel, energy: EnergyLevel, notes: String?, triggers: [String]?) async {
        let entry = MoodEnergyEntry(
            mood: mood,
            energy: energy,
            notes: notes,
            triggers: triggers
        )

        do {
            try await repository.addEntry(entry)
            await loadEntries()
            await loadAverages()
        } catch {
            self.error = error
        }
    }

    @MainActor
    public func deleteEntry(_ entry: MoodEnergyEntry) async {
        do {
            try await repository.deleteEntry(entry)
            await loadEntries()
            await loadAverages()
        } catch {
            self.error = error
        }
    }
}
```

**MoodPicker.swift:**
```swift
import SwiftUI
import DesignSystem
import DataLayer

public struct MoodPicker: View {
    @Binding var mood: MoodLevel

    public init(mood: Binding<MoodLevel>) {
        self._mood = mood
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How are you feeling?")
                .font(Typography.headline)
                .foregroundColor(.textPrimary)

            HStack(spacing: 8) {
                ForEach([MoodLevel.veryBad, .bad, .neutral, .good, .veryGood], id: \.self) { m in
                    Button {
                        mood = m
                    } label: {
                        VStack(spacing: 4) {
                            Text(m.emoji)
                                .font(.system(size: 32))
                            Text(m.description)
                                .font(Typography.caption)
                                .minimumScaleFactor(0.7)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(mood == m ? Color.appPrimary.opacity(0.2) : Color.appSurface)
                        .cornerRadius(12)
                    }
                    .accessibilityLabel("\(m.description) mood")
                    .accessibilityAddTraits(mood == m ? [.isButton, .isSelected] : .isButton)
                }
            }
        }
    }
}
```

**EnergyPicker.swift:**
```swift
import SwiftUI
import DesignSystem
import DataLayer

public struct EnergyPicker: View {
    @Binding var energy: EnergyLevel

    public init(energy: Binding<EnergyLevel>) {
        self._energy = energy
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Energy Level")
                .font(Typography.headline)
                .foregroundColor(.textPrimary)

            HStack(spacing: 8) {
                ForEach([EnergyLevel.veryLow, .low, .moderate, .high, .veryHigh], id: \.self) { e in
                    Button {
                        energy = e
                    } label: {
                        VStack(spacing: 4) {
                            Text(e.emoji)
                                .font(.system(size: 32))
                            Text(e.description)
                                .font(Typography.caption)
                                .minimumScaleFactor(0.7)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(energy == e ? Color.appPrimary.opacity(0.2) : Color.appSurface)
                        .cornerRadius(12)
                    }
                    .accessibilityLabel("\(e.description) energy level")
                    .accessibilityAddTraits(energy == e ? [.isButton, .isSelected] : .isButton)
                }
            }
        }
    }
}
```

---

## 🗓️ Week 8: Testing & Integration (32 hours)

### Goal
Write comprehensive tests and integrate all features

### 8.1: Repository Tests (16 hours)

**FastingRepositoryTests.swift:**
```swift
import XCTest
import SwiftData
@testable import DataLayer

final class FastingRepositoryTests: XCTestCase {
    var repository: FastingRepository!
    var modelContainer: ModelContainer!

    override func setUp() async throws {
        let schema = Schema([FastingSession.self])
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        repository = FastingRepository(modelContainer: modelContainer)
    }

    func testStartFasting() async throws {
        // Given
        let targetDuration: TimeInterval = 16 * 3600

        // When
        let session = try await repository.startFasting(targetDuration: targetDuration)

        // Then
        XCTAssertNotNil(session.id)
        XCTAssertEqual(session.targetDuration, targetDuration)
        XCTAssertTrue(session.isActive)
        XCTAssertNil(session.endTime)
    }

    func testEndFasting() async throws {
        // Given
        let session = try await repository.startFasting(targetDuration: 16 * 3600)

        // When
        try await repository.endFasting(session: session)

        // Then
        let fetchedSession = try await repository.getSession(id: session.id)
        XCTAssertNotNil(fetchedSession?.endTime)
        XCTAssertFalse(fetchedSession?.isActive ?? true)
    }

    func testGetActiveFasting() async throws {
        // Given
        let session = try await repository.startFasting(targetDuration: 16 * 3600)

        // When
        let activeSession = try await repository.getActiveFasting()

        // Then
        XCTAssertEqual(activeSession?.id, session.id)
    }

    func testGetAllSessions() async throws {
        // Given
        _ = try await repository.startFasting(targetDuration: 16 * 3600)
        _ = try await repository.startFasting(targetDuration: 18 * 3600)

        // When
        let sessions = try await repository.getAllSessions()

        // Then
        XCTAssertEqual(sessions.count, 2)
    }
}
```

Write similar tests for:
- HydrationRepositoryTests
- WeightRepositoryTests
- SleepRepositoryTests
- MoodEnergyRepositoryTests

**Target:** 25+ tests per repository = 125+ total tests

---

### 8.2: ViewModel Tests (8 hours)

**FastingTrackingViewModelTests.swift:**
```swift
import XCTest
@testable import FeatureFasting
@testable import DataLayer

final class FastingTrackingViewModelTests: XCTestCase {
    var viewModel: FastingTrackingViewModel!
    var mockRepository: MockFastingRepository!

    override func setUp() {
        mockRepository = MockFastingRepository()
        viewModel = FastingTrackingViewModel(repository: mockRepository)
    }

    func testStartFasting() async {
        // Given
        XCTAssertNil(viewModel.activeSession)

        // When
        await viewModel.startFasting(hours: 16)

        // Then
        XCTAssertNotNil(viewModel.activeSession)
        XCTAssertEqual(viewModel.activeSession?.targetDuration, 16 * 3600)
    }

    func testEndFasting() async {
        // Given
        await viewModel.startFasting(hours: 16)
        XCTAssertNotNil(viewModel.activeSession)

        // When
        await viewModel.endFasting()

        // Then
        // Wait for async updates
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertNil(viewModel.activeSession)
    }
}

// Mock Repository for testing
class MockFastingRepository: FastingRepositoryProtocol {
    private var sessions: [FastingSession] = []

    func getActiveFasting() async throws -> FastingSession? {
        sessions.first { $0.isActive }
    }

    func startFasting(targetDuration: TimeInterval) async throws -> FastingSession {
        let session = FastingSession(startTime: Date(), targetDuration: targetDuration)
        sessions.append(session)
        return session
    }

    func endFasting(session: FastingSession) async throws {
        session.endTime = Date()
    }

    // ... implement other methods
}
```

---

### 8.3: Integration Tests (8 hours)

**AppIntegrationTests.swift:**
```swift
import XCTest
import SwiftData
@testable import DataLayer
@testable import FeatureFasting
@testable import FeatureHydration
@testable import FeatureWeight
@testable import FeatureSleep

final class AppIntegrationTests: XCTestCase {
    var container: DIContainer!

    override func setUp() async throws {
        container = DIContainer.preview()
    }

    func testFastingToHydrationFlow() async throws {
        // Start fasting
        let fastingRepo = container.fastingRepository
        let session = try await fastingRepo.startFasting(targetDuration: 16 * 3600)
        XCTAssertTrue(session.isActive)

        // Log hydration during fast
        let hydrationRepo = container.hydrationRepository
        let entry = HydrationEntry(amount: 500)
        try await hydrationRepo.addEntry(entry)

        let todayTotal = try await hydrationRepo.getTodayTotal()
        XCTAssertEqual(todayTotal, 500)
    }

    func testSleepAndWeightCorrelation() async throws {
        // Log sleep
        let sleepRepo = container.sleepRepository
        let bedTime = Date().hoursAgo(8)
        let wakeTime = Date()
        let sleepEntry = SleepEntry(bedTime: bedTime, wakeTime: wakeTime, quality: .good)
        try await sleepRepo.addEntry(sleepEntry)

        // Log weight
        let weightRepo = container.weightRepository
        let weightEntry = WeightEntry(weight: 75.0)
        try await weightRepo.addEntry(weightEntry)

        // Verify both logged
        let sleepEntries = try await sleepRepo.getAllEntries()
        let weightEntries = try await weightRepo.getAllEntries()

        XCTAssertEqual(sleepEntries.count, 1)
        XCTAssertEqual(weightEntries.count, 1)
    }
}
```

---

## ✅ Phase 1 Success Criteria

**You're done when:**
- ✅ All 5+ SPM packages created (Core, DesignSystem, DataLayer, 5 features)
- ✅ All 5 repositories implemented (Fasting, Hydration, Weight, Sleep, **Mood & Energy**)
- ✅ Dependency injection container working
- ✅ 125+ unit tests passing (40%+ coverage)
- ✅ All features use DesignSystem components
- ✅ Zero tight coupling between features
- ✅ SwiftData as single source of truth
- ✅ All data flows through repositories

**Validation:**
```bash
# Build all packages
xcodebuild -workspace FastingTracker.xcworkspace -scheme "All Packages" build

# Run all tests
xcodebuild -workspace FastingTracker.xcworkspace -scheme "All Tests" test

# Check coverage
./scripts/coverage_report.sh
```

**Coverage targets:**
- DataLayer: 70%+
- Repositories: 80%+
- ViewModels: 60%+
- Overall: 40%+

---

## 📊 Time Tracking

| Week | Tasks | Hours | Cumulative |
|------|-------|-------|------------|
| Week 4 | SPM packages | 32h | 32h |
| Week 5 | Repositories + DI (5 repos) | 40h | 72h |
| Week 6-7 | Feature packages (5 features) | 60h | 132h |
| Week 8 | Tests + integration | 32h | 164h |

**Total: 164 hours (20.5 days at 8h/day)**

---

## 🎯 Score Impact

**Before Phase 1:** 5.5/10
**After Phase 1:** 7.5/10

**Improvements:**
- ✅ Architecture: 3/10 → 8/10 (+5)
- ✅ Testing: 0/10 → 6/10 (+6)
- ✅ Modularity: 2/10 → 9/10 (+7)
- ✅ Single Source of Truth: 3/10 → 9/10 (+6)
- ✅ Code Reusability: 4/10 → 8/10 (+4)

---

## 🚀 Next Steps

**After completing Phase 1:**
1. ✅ Celebrate! You've built enterprise architecture
2. ✅ Review [Phase 2: Scale & Polish](./PHASE_2_SCALE_POLISH_COMPLETE.md)
3. ✅ Take 2-day break before Phase 2
4. ✅ Verify all tests green
5. ✅ Deploy to TestFlight for beta testing

---

**[⬅️ Back to Phase 0](./PHASE_0_FOUNDATION.md)** | **[▶️ Next: Phase 2](./PHASE_2_SCALE_POLISH_COMPLETE.md)** | **[📖 Master Plan](../ENTERPRISE_TRANSFORMATION_MASTER.md)**
