import Foundation
import HealthKit
import OSLog
import Combine

/// Heart Rate Manager (Actor) for thread-safe HealthKit operations
/// Following expert recommendations for iOS 17+ strict concurrency compliance
/// Reference: Fast_LIFe_HeartRate_Debug_Spec.md - Expert Actor-based Solution
actor HeartRateManager {
    private let logger = Logger(subsystem: "com.fastlife.tracker", category: "HeartRate")
    private let healthStore: HKHealthStore
    private let heartRateType: HKQuantityType
    private var observerQuery: HKObserverQuery?

    // Industry standard: Callback for automatic UI updates when new data arrives
    private var onDataUpdated: (@Sendable () -> Void)?

    init() {
        // CRITICAL FIX: Use shared HKHealthStore to avoid authorization conflicts
        // Multiple HKHealthStore instances cause persistent SHARING DENIED status
        // Following expert debug guidance from Fast_LIFe_HeartRate_Connect_Debug.md
        self.healthStore = HealthKitManager.shared.getHealthStore()
        self.heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        logger.info("HeartRateManager actor initialized with shared HKHealthStore")

        // Set up automatic background sync following Apple HealthKit best practices
        Task {
            await setupBackgroundSync()
        }
    }

    // MARK: - Automatic Background Sync (Industry Standard)
    // Following Apple HealthKit Programming Guide and existing app patterns

    func setupBackgroundSync() async {
        logger.info("🔄 Setting up automatic heart rate background sync...")

        // Enable background delivery for heart rate updates
        do {
            try await healthStore.enableBackgroundDelivery(
                for: heartRateType,
                frequency: .immediate
            )
            logger.info("✅ Background delivery enabled for heart rate")
        } catch {
            logger.error("❌ Failed to enable background delivery: \(error.localizedDescription)")
        }

        // Create observer query for automatic updates
        observerQuery = HKObserverQuery(sampleType: heartRateType, predicate: nil) { [weak self] query, completionHandler, error in
            Task { @Sendable [weak self] in
                await self?.handleBackgroundUpdate(error: error)
                completionHandler()
            }
        }

        if let observerQuery = observerQuery {
            healthStore.execute(observerQuery)
            logger.info("✅ Heart rate observer query started - automatic sync active")
        }
    }

    private func handleBackgroundUpdate(error: Error?) async {
        if let error = error {
            logger.error("❌ Background heart rate update error: \(error.localizedDescription)")
            return
        }

        logger.info("📱 New heart rate data detected - triggering automatic update")

        // Notify UI to refresh data
        onDataUpdated?()
    }

    func setUpdateCallback(_ callback: @escaping @Sendable () -> Void) {
        onDataUpdated = callback
    }

    // MARK: - Authorization (Industry Standard - Delegated to Central System)

    func requestAuthorization() async throws {
        logger.info("🔐 Delegating heart rate authorization to centralized system...")
        // Use centralized authorization system instead of separate request
        // This ensures consistency with app-wide HealthKit permissions
        try await HealthKitManager.shared.authManager.requestHeartRateAuthorization()
        logger.info("✅ Heart rate authorization requested via centralized system")
    }

    func authorizationStatus() -> HKAuthorizationStatus {
        let status = healthStore.authorizationStatus(for: self.heartRateType)

        // CRITICAL: Apple's HealthKit authorizationStatus ONLY reflects WRITE permissions
        // For READ-ONLY access, status will always be .sharingDenied (1) - this is by design
        // The only way to check read access is to attempt data queries
        logger.info("🔍 DEBUGGING Heart Rate Authorization:")
        logger.info("   - HealthKit Available: \(HKHealthStore.isHealthDataAvailable())")
        logger.info("   - Heart Rate Type: \(self.heartRateType.identifier)")
        logger.info("   - Raw Status Value: \(status.rawValue)")
        logger.info("   - Status Description: \(status == .notDetermined ? "NOT DETERMINED" : status == .sharingDenied ? "SHARING DENIED (READ-ONLY NORMAL)" : status == .sharingAuthorized ? "SHARING AUTHORIZED" : "UNKNOWN")")
        logger.info("   - ⚠️  IMPORTANT: .sharingDenied is NORMAL for read-only access per Apple's privacy design")

        return status
    }

    /// Apple's recommended pattern: Check read access by attempting data query
    /// Returns true if we can read heart rate data (regardless of authorizationStatus)
    func hasReadAccess() async -> Bool {
        do {
            // Attempt to query one sample to check read access
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            return try await withCheckedThrowingContinuation { continuation in
                let query = HKSampleQuery(
                    sampleType: self.heartRateType,
                    predicate: nil,
                    limit: 1,
                    sortDescriptors: [sort]
                ) { _, samples, error in
                    if let error = error {
                        // Query failed - likely no read access
                        self.logger.info("📊 Read access check: DENIED (query failed: \(error.localizedDescription))")
                        continuation.resume(returning: false)
                        return
                    }
                    // Query succeeded - we have read access (data may be empty)
                    self.logger.info("📊 Read access check: GRANTED (query succeeded)")
                    continuation.resume(returning: true)
                }
                healthStore.execute(query)
            }
        } catch {
            logger.error("📊 Read access check failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Diagnostic Method (Industry Standard Verification)

    func diagnosticTest() async {
        logger.info("🧪 DIAGNOSTIC: Testing heart rate authorization flow...")

        // Test 1: Check initial status
        let initialStatus = authorizationStatus()
        logger.info("🧪 Initial status: \(initialStatus.rawValue)")

        // Test 2: Manual authorization request via centralized system (industry standard)
        do {
            logger.info("🧪 Requesting authorization via centralized HealthKitAuthManager...")
            try await HealthKitManager.shared.authManager.requestHeartRateAuthorization()
            logger.info("🧪 Centralized authorization request completed")

            // Test 3: Immediate status check
            let immediateStatus = authorizationStatus()
            logger.info("🧪 Immediate post-auth status: \(immediateStatus.rawValue)")

            // Test 4: Delayed status check
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            let delayedStatus = authorizationStatus()
            logger.info("🧪 Delayed post-auth status: \(delayedStatus.rawValue)")

            // Test 5: Apple's recommended read access check (the real test)
            let readAccess = await hasReadAccess()
            logger.info("🧪 ✅ REAL READ ACCESS CHECK: \(readAccess ? "✅ GRANTED" : "❌ DENIED")")

        } catch {
            logger.error("🧪 Diagnostic test failed: \(error)")
        }
    }

    // MARK: - Data Fetching (Expert Implementation)

    func latestHeartRate() async throws -> Double? {
        logger.info("📡 Fetching latest heart rate...")
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: self.heartRateType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error = error {
                    self.logger.error("❌ Heart rate query error: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }

                if let sample = samples?.first as? HKQuantitySample {
                    let bpm = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                    self.logger.info("💓 Latest heart rate: \(bpm) bpm at \(sample.startDate)")
                    continuation.resume(returning: bpm)
                } else {
                    self.logger.info("⚠️ No heart rate samples found - user may need to sync Apple Watch")
                    continuation.resume(returning: nil)
                }
            }
            healthStore.execute(query)
        }
    }

    func averageHeartRate(lastMinutes: Int = 1440) async throws -> Double? {
        logger.info("📊 Calculating average heart rate for last \(lastMinutes) minutes...")
        let end = Date()
        let start = Calendar.current.date(byAdding: .minute, value: -lastMinutes, to: end)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictEndDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: self.heartRateType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, stats, error in
                if let error = error {
                    self.logger.error("❌ Average heart rate query error: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }

                if let avg = stats?.averageQuantity()?.doubleValue(for: HKUnit(from: "count/min")) {
                    self.logger.info("📊 Average heart rate (\(lastMinutes)min): \(avg) bpm")
                    continuation.resume(returning: avg)
                } else {
                    self.logger.info("📊 No heart rate data for average calculation - may need Apple Watch sync")
                    continuation.resume(returning: nil)
                }
            }
            healthStore.execute(query)
        }
    }

}

// MARK: - MainActor Facade for SwiftUI Integration
// Following expert recommendation for SwiftUI binding with actor-based manager

@MainActor
final class HeartRateViewModel: ObservableObject {
    @Published var currentHeartRate: Double?
    @Published var dailyAverageHeartRate: Double?
    @Published var hasReadAccess: Bool = false // Apple's recommended approach
    @Published var lastUpdated: Date?
    @Published var isLoading: Bool = false

    private let manager: HeartRateManager
    private let logger = Logger(subsystem: "com.fastlife.tracker", category: "HeartRateViewModel")
    private var refreshTimer: Timer?

    init(manager: HeartRateManager = HeartRateManager()) {
        self.manager = manager
        logger.info("HeartRateViewModel initialized")

        // Set up automatic background sync callback
        // This enables real-time UI updates when new heart rate data arrives
        Task { [weak self] in
            await manager.setUpdateCallback { [weak self] in
                DispatchQueue.main.async { [weak self] in
                    self?.logger.info("🔄 Auto-sync triggered - refreshing heart rate UI")
                    self?.refresh()
                }
            }
        }

        // Set up periodic refresh timer as fallback (industry standard)
        // Updates every 30 seconds to ensure data freshness
        setupPeriodicRefresh()
    }

    deinit {
        refreshTimer?.invalidate()
        logger.info("HeartRateViewModel deinitialized - timers cleaned up")
    }

    // MARK: - Automatic Refresh Timer (Industry Standard Fallback)
    // Following Apple Health, Fitbit, MyFitnessPal patterns for periodic sync

    private func setupPeriodicRefresh() {
        // 30-second interval - balance between freshness and battery life
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            // Execute on main thread to access @MainActor properties safely
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                // Only auto-refresh if we have read access and aren't already loading
                if self.hasReadAccess && !self.isLoading {
                    self.logger.info("⏰ Periodic refresh - checking for new heart rate data")
                    self.refresh()
                }
            }
        }
    }

    /// Apple's recommended pattern: Check actual read access, not authorization status
    var isAuthorized: Bool {
        hasReadAccess
    }

    func refresh() {
        logger.info("🔄 Refreshing heart rate data...")
        isLoading = true

        Task { [weak self] in
            guard let self = self else { return }

            // Apple's recommended pattern: Check actual read access via data query
            let readAccess = await self.manager.hasReadAccess()
            await MainActor.run {
                self.hasReadAccess = readAccess
            }

            self.logger.info("📊 Read access check: \(readAccess ? "GRANTED" : "DENIED")")

            if readAccess {
                do {
                    // Fetch both current and average heart rate
                    async let latest = self.manager.latestHeartRate()
                    async let average = self.manager.averageHeartRate(lastMinutes: 1440) // 24 hours

                    let (currentHR, avgHR) = try await (latest, average)

                    await MainActor.run {
                        self.currentHeartRate = currentHR
                        self.dailyAverageHeartRate = avgHR
                        self.lastUpdated = Date()
                        self.isLoading = false
                        self.logger.info("✅ Heart rate data refreshed successfully")
                    }
                } catch {
                    await MainActor.run {
                        self.currentHeartRate = nil
                        self.dailyAverageHeartRate = nil
                        self.isLoading = false
                        self.logger.error("❌ Failed to fetch heart rate data: \(error.localizedDescription)")
                    }
                }
            } else {
                await MainActor.run {
                    self.currentHeartRate = nil
                    self.dailyAverageHeartRate = nil
                    self.isLoading = false
                    self.logger.info("ℹ️ Heart rate not authorized, clearing data")
                }
            }
        }
    }

    func requestAuthorization() {
        logger.info("🔐 Requesting heart rate authorization...")

        Task { [weak self] in
            guard let self = self else { return }

            do {
                // Request authorization via centralized system
                try await self.manager.requestAuthorization()

                await MainActor.run {
                    self.logger.info("✅ Heart rate authorization completed - refreshing UI")
                    self.refresh()
                }
            } catch {
                await MainActor.run {
                    self.logger.error("❌ Heart rate authorization failed: \(error.localizedDescription)")
                    // Still refresh to update UI state
                    self.refresh()
                }
            }
        }
    }
}

