import Foundation
import Combine

class FastingManager: ObservableObject {
    @Published var currentSession: FastingSession?
    @Published var fastingHistory: [FastingSession] = []
    @Published var elapsedTime: TimeInterval = 0
    @Published var fastingGoalHours: Double = 16
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0

    private var timer: AnyCancellable?
    private let dataStore: DataStore = AppDataStore.shared
    private let currentSessionKey = "currentFastingSession"
    private let historyKey = "fastingHistory"
    private let goalKey = "fastingGoalHours"
    private let streakKey = "currentStreak"
    private let longestStreakKey = "longestStreak"

    // MARK: - HealthKit Sync Properties (Intermittent Fasting Integration)
    @Published var syncWithHealthKit: Bool = false
    private let syncPreferenceKey = "fastingSyncWithHealthKit"
    private let hasCompletedInitialImportKey = "fastingHasCompletedInitialImport"

    /// Observer suppression flag to prevent infinite sync loops during manual operations
    private var isSuppressingObserver = false

    /// Observer query for automatic HealthKit sync
    private var observerQuery: Any? // HKObserverQuery type-erased

    // MARK: - Thread Safety
    // Serial queue to synchronize all history/streak operations
    // Prevents race condition: background streak calculation reading stale history while main thread modifies it
    // Reference: https://developer.apple.com/documentation/dispatch/dispatchqueue
    private let historyQueue = DispatchQueue(label: "com.fastlife.historyQueue", qos: .userInitiated)

    init() {
        // CRITICAL: Only load data needed for Timer tab (first screen)
        // History loading deferred to loadHistoryAsync() to avoid blocking app launch
        // Per Apple: "Defer work that isn't critical to launch"
        // Reference: https://developer.apple.com/documentation/xcode/reducing-your-app-s-launch-time

        loadGoal()              // Fast: Single double from UserDefaults
        loadCurrentSession()    // Fast: Single session object (or nil)
        loadStreak()            // Fast: Single int from UserDefaults
        loadLongestStreak()     // Fast: Single int from UserDefaults
        loadSyncPreference()    // Fast: Single bool from UserDefaults

        // Start timer immediately if there's an active session (critical for Timer tab UI)
        if currentSession != nil {
            startTimer()
        }

        // Setup observer if sync is already enabled (app restart scenario)
        if syncWithHealthKit && HealthKitManager.shared.isFastingAuthorized() {
            startObservingHealthKit()
        }

        // NOTE: History loading moved to loadHistoryAsync()
        // Called from MainTabView.onAppear after first frame renders
    }

    var remainingTime: TimeInterval {
        let goalSeconds = fastingGoalHours * 3600
        // If no session is active, return the full goal time
        guard currentSession != nil else {
            return goalSeconds
        }
        return max(0, goalSeconds - elapsedTime)
    }

    var isActive: Bool {
        currentSession != nil
    }

    var progress: Double {
        let goalSeconds = fastingGoalHours * 3600
        return min(elapsedTime / goalSeconds, 1.0)
    }

    // MARK: - State Validation Methods
    // Following Apple State Management best practices for UI validation
    // Reference: https://developer.apple.com/documentation/swiftui/managing-user-interface-state

    /// Check if starting a fast is currently valid
    /// Following roadmap requirement for state transition guards
    var canStartFast: Bool {
        return currentSession == nil
    }

    /// Check if stopping a fast is currently valid
    /// Following roadmap requirement for state transition guards
    var canStopFast: Bool {
        return currentSession != nil
    }

    /// Get current fasting state for UI display
    /// Following Apple State Pattern for clear state representation
    enum FastingState {
        case idle          // No active session, can start
        case active        // Session active, can stop
    }

    var currentState: FastingState {
        return currentSession == nil ? .idle : .active
    }

    func startFast() {
        print("\n⏱️  === START FAST ===")

        // ROADMAP REQUIREMENT: Guard overlapping sessions - reject invalid state transition (start→start)
        // Following Apple State Management best practices
        // Reference: https://developer.apple.com/documentation/swift/maintaining_state_in_your_apps
        guard currentSession == nil else {
            print("❌ INVALID STATE TRANSITION: Cannot start fast - session already active")
            AppLogger.error("Prevented invalid fasting state transition: start→start", category: AppLogger.fasting)
            return
        }

        print("Goal: \(fastingGoalHours)h")
        print("Current Streak: \(currentStreak)")

        // Calculate eating window duration if there's a previous fast
        var eatingWindowDuration: TimeInterval? = nil
        if let lastFast = fastingHistory.first, let lastEndTime = lastFast.endTime {
            eatingWindowDuration = Date().timeIntervalSince(lastEndTime)
            let hours = eatingWindowDuration! / 3600
            print("🍽️  Eating window: \(String(format: "%.1f", hours))h (since last fast ended)")
        } else {
            print("🍽️  No previous fast found - first fast or no history")
        }

        let session = FastingSession(startTime: Date(), goalHours: fastingGoalHours, eatingWindowDuration: eatingWindowDuration, source: .manual)
        currentSession = session
        saveCurrentSession()
        startTimer()

        // Schedule all enabled notifications based on user settings
        NotificationManager.shared.scheduleAllNotifications(
            for: session,
            goalHours: fastingGoalHours,
            currentStreak: currentStreak,
            longestStreak: longestStreak
        )

        // Sync to HealthKit when starting fasting session
        syncActiveSessionToHealthKit()

        print("✅ Fast started successfully")
        print("=========================\n")
    }

    func stopFast() {
        print("\n🛑 === STOP FAST ===")

        // ROADMAP REQUIREMENT: Reject invalid state transitions (end without active)
        // Following Apple State Management best practices
        guard var session = currentSession else {
            print("❌ INVALID STATE TRANSITION: Cannot stop fast - no active session")
            AppLogger.error("Prevented invalid fasting state transition: end without active", category: AppLogger.fasting)
            return
        }

        session.endTime = Date()
        let duration = session.endTime!.timeIntervalSince(session.startTime) / 3600
        print("Duration: \(String(format: "%.2f", duration))h")
        print("Goal: \(session.goalHours ?? 16)h")
        let goalStatus = session.metGoal ? "✅" : "❌"
        print("Met Goal: \(goalStatus)")

        // Add to history FIRST (one entry per day)
        addToHistory(session)

        // Then update streak based on goal completion
        // This ensures the new session is included in streak calculations
        updateStreak(for: session)

        // Sync completed session to HealthKit before clearing
        currentSession = session // Set session temporarily for sync
        syncActiveSessionToHealthKit()

        currentSession = nil
        clearCurrentSession()
        stopTimer()

        // Cancel notification
        NotificationManager.shared.cancelGoalNotification()

        print("✅ Fast stopped successfully")
        print("====================\n")
    }

    func deleteFast() {
        // Delete current fast without saving to history
        // This discards the fast as if it never happened
        currentSession = nil
        clearCurrentSession()
        stopTimer()

        // Cancel notification
        NotificationManager.shared.cancelGoalNotification()
    }

    /// API compatibility: deleteCurrentFast delegates to deleteFast
    /// Following established naming convention compatibility pattern
    func deleteCurrentFast() {
        deleteFast()
    }

    func stopFastWithCustomTimes(startTime: Date, endTime: Date) {
        guard var session = currentSession else { return }

        // Update session with custom times
        session.startTime = startTime
        session.endTime = endTime

        // Add to history FIRST (one entry per day)
        addToHistory(session)

        // Then update streak based on goal completion (with custom duration)
        // This ensures the new session is included in streak calculations
        updateStreak(for: session)

        currentSession = nil
        clearCurrentSession()
        stopTimer()

        // Cancel notification
        NotificationManager.shared.cancelGoalNotification()
    }

    func addManualFast(startTime: Date, endTime: Date, goalHours: Double) {
        print("\n📝 === ADD MANUAL FAST ===")
        print("Start: \(startTime)")
        print("End: \(endTime)")
        print("Goal: \(goalHours)h")

        // Calculate eating window if there's a previous fast before this manual entry
        var eatingWindowDuration: TimeInterval? = nil
        if let lastFast = fastingHistory.first, let lastEndTime = lastFast.endTime {
            // Only calculate if the manual fast starts after the previous fast ended
            if startTime > lastEndTime {
                eatingWindowDuration = startTime.timeIntervalSince(lastEndTime)
                let hours = eatingWindowDuration! / 3600
                print("🍽️  Eating window: \(String(format: "%.1f", hours))h (since last fast ended)")
            }
        }

        var session = FastingSession(startTime: startTime, goalHours: goalHours, eatingWindowDuration: eatingWindowDuration)
        session.endTime = endTime

        let duration = endTime.timeIntervalSince(startTime) / 3600
        print("Duration: \(String(format: "%.2f", duration))h")
        let goalStatus = session.metGoal ? "✅" : "❌"
        print("Met Goal: \(goalStatus)")
        print("⚠️  Manual fasts do NOT trigger notifications (by design)")

        // Add to history FIRST (one entry per day)
        addToHistory(session)

        // Then update streak based on goal completion
        // This ensures the new session is included in streak calculations
        updateStreak(for: session)

        print("✅ Manual fast added successfully")
        print("==========================\n")
    }

    func deleteFast(for date: Date) {
        print("\n🗑️  === DELETE FAST ===")
        print("Date: \(date)")
        let threadName = Thread.current.isMainThread ? "Main" : "Background"
        print("Thread: \(threadName)")

        // THREAD SAFETY: Synchronize deletion with serial queue
        historyQueue.async { [weak self] in
            guard let self = self else { return }

            print("📍 Deletion executing on historyQueue")

            let calendar = Calendar.current
            let targetDay = calendar.startOfDay(for: date)

            // Remove the fast for this day (must update on main thread for @Published)
            DispatchQueue.main.async {
                let beforeCount = self.fastingHistory.count
                self.fastingHistory.removeAll { session in
                    calendar.startOfDay(for: session.startTime) == targetDay
                }
                let afterCount = self.fastingHistory.count
                print("📊 History count: \(beforeCount) → \(afterCount)")
                self.saveHistory()
            }

            // Recalculate streaks from history (deleting may break streak)
            // This already uses historyQueue internally, so will execute after deletion completes
            self.calculateStreakFromHistory()

            print("✅ Fast deleted successfully")
            print("====================\n")
        }
    }

    private func addToHistory(_ session: FastingSession) {
        print("\n📥 === ADD TO HISTORY ===")
        print("Session Date: \(session.startTime)")
        let threadName = Thread.current.isMainThread ? "Main" : "Background"
        print("Thread: \(threadName)")

        // ROADMAP REQUIREMENT: Handle day-boundary and time zone transitions
        // Following Apple Calendar best practices for timezone-aware date handling
        // Reference: https://developer.apple.com/documentation/foundation/calendar
        let calendar = Calendar.current
        let sessionDay = calendar.startOfDay(for: session.startTime)

        // Log timezone information for debugging day-boundary issues
        let timeZone = calendar.timeZone
        print("🌍 Timezone: \(timeZone.identifier)")
        print("📅 Session day (start of day): \(sessionDay)")

        let beforeCount = fastingHistory.count

        // Check if there's already a fast for this day
        if let existingIndex = fastingHistory.firstIndex(where: {
            calendar.startOfDay(for: $0.startTime) == sessionDay
        }) {
            print("🔄 Replacing existing fast for this day")
            // Replace existing fast for this day
            fastingHistory[existingIndex] = session
        } else {
            print("➕ Adding new fast")
            // Add new fast
            fastingHistory.append(session)
        }

        // Sort by date (most recent first)
        fastingHistory.sort { $0.startTime > $1.startTime }

        print("📊 History count: \(beforeCount) → \(fastingHistory.count)")

        // No limit on history - need all data for lifetime statistics and streak calculations
        saveHistory()

        print("✅ Added to history successfully")
        print("========================\n")
    }

    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateElapsedTime()
            }
        updateElapsedTime()
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
        elapsedTime = 0
    }

    private func updateElapsedTime() {
        guard let session = currentSession else {
            elapsedTime = 0
            return
        }
        elapsedTime = Date().timeIntervalSince(session.startTime)
    }

    // MARK: - Persistence

    func saveCurrentSession() {
        guard let session = currentSession else { return }
        let success = dataStore.safeSave(session, forKey: currentSessionKey)
        if !success {
            CrashReportManager.shared.recordFastingError(
                NSError(domain: "Persistence", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to save current session"]),
                context: ["operation": "saveCurrentSession"]
            )
        }
    }

    private func loadCurrentSession() {
        currentSession = dataStore.safeLoad(FastingSession.self, forKey: currentSessionKey)
    }

    private func clearCurrentSession() {
        let success = dataStore.safeRemove(forKey: currentSessionKey)
        if !success {
            CrashReportManager.shared.recordFastingError(
                NSError(domain: "Persistence", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Failed to clear current session"]),
                context: ["operation": "clearCurrentSession"]
            )
        }
    }

    private func saveHistory() {
        let success = dataStore.safeSave(fastingHistory, forKey: historyKey)
        if !success {
            CrashReportManager.shared.recordFastingError(
                NSError(domain: "Persistence", code: 1004, userInfo: [NSLocalizedDescriptionKey: "Failed to save fasting history"]),
                context: ["operation": "saveHistory", "count": fastingHistory.count]
            )
        }
    }

    private func loadHistory() {
        if let history = dataStore.safeLoad([FastingSession].self, forKey: historyKey) {
            // Filter out any incomplete sessions from history (safety check)
            fastingHistory = history.filter { $0.isComplete }.sorted { $0.startTime > $1.startTime }
        }
    }

    /// Loads fasting history asynchronously on background thread
    /// Call this from MainTabView.onAppear() to defer heavy data loading until after first frame renders
    /// This prevents white screen lag on app launch
    func loadHistoryAsync() {
        print("\n📂 === LOAD HISTORY ASYNC ===")
        let threadName = Thread.current.isMainThread ? "Main" : "Background"
        print("Thread: \(threadName)")

        // THREAD SAFETY: Use historyQueue instead of global queue for synchronized access
        historyQueue.async { [weak self] in
            guard let self = self else { return }

            print("📍 Loading history on historyQueue")

            // Load and decode history on background thread
            guard let history = self.dataStore.safeLoad([FastingSession].self, forKey: self.historyKey) else {
                print("⚠️  No history found or decode failed")
                return
            }

            let filteredHistory = history.filter { $0.isComplete }.sorted { $0.startTime > $1.startTime }
            print("📊 Loaded \(filteredHistory.count) complete fasts from storage")

            // Update @Published property on main thread
            DispatchQueue.main.async {
                self.fastingHistory = filteredHistory
                print("✅ History updated on main thread")
            }

            // Recalculate streaks (already uses historyQueue internally)
            self.calculateStreakFromHistory()

            print("==========================\n")
        }
    }

    func setFastingGoal(hours: Double) {
        fastingGoalHours = hours
        let success = dataStore.safeSave(hours, forKey: goalKey)
        if !success {
            CrashReportManager.shared.recordFastingError(
                NSError(domain: "Persistence", code: 1005, userInfo: [NSLocalizedDescriptionKey: "Failed to save fasting goal"]),
                context: ["operation": "setGoal", "hours": hours]
            )
        }
    }

    private func loadGoal() {
        if let savedGoal = dataStore.safeLoad(Double.self, forKey: goalKey), savedGoal > 0 {
            fastingGoalHours = savedGoal
        }
    }

    // MARK: - Streak Management

    private func updateStreak(for session: FastingSession) {
        // Recalculate the entire streak from history
        calculateStreakFromHistory()
    }

    private func calculateStreakFromHistory() {
        print("\n🔥 === CALCULATE STREAK FROM HISTORY ===")
        let threadName = Thread.current.isMainThread ? "Main" : "Background"
        print("Called from thread: \(threadName)")

        // THREAD SAFETY: Execute on serial queue to prevent reading stale fastingHistory
        // Ensures streak calculation always uses most up-to-date history
        // Reference: https://developer.apple.com/documentation/dispatch/dispatchqueue
        historyQueue.async { [weak self] in
            guard let self = self else { return }

            print("📍 Executing on historyQueue (serial, thread-safe)")

            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())

            // Capture fastingHistory snapshot inside serial queue (thread-safe read)
            let historyCopy = self.fastingHistory
            print("📊 History snapshot: \(historyCopy.count) total fasts")

            // Get all goal-met fasts sorted by date (most recent first)
            let goalMetFasts = historyCopy
                .filter { $0.metGoal }
                .sorted { $0.startTime > $1.startTime }

            print("✅ Goal-met fasts: \(goalMetFasts.count)")

            guard !goalMetFasts.isEmpty else {
                print("⚠️  No goal-met fasts → Streak = 0")
                DispatchQueue.main.async {
                    self.currentStreak = 0
                    self.saveStreak()
                }
                return
            }

            let formatter = DateFormatter()
            formatter.dateStyle = .short
            print("📅 Most recent goal-met fast: \(formatter.string(from: goalMetFasts[0].startTime))")

            // Calculate current streak (must include today or yesterday)
            let mostRecentFast = goalMetFasts[0]
            let mostRecentDay = calendar.startOfDay(for: mostRecentFast.startTime)
            let daysBetween = calendar.dateComponents([.day], from: mostRecentDay, to: today).day ?? 0

            var currentStreakValue: Int

            if daysBetween > 1 {
                // Current streak is broken
                currentStreakValue = 0
            } else {
                // Calculate current streak
                var streak = 1
                var currentDay = mostRecentDay

                for i in 1..<goalMetFasts.count {
                    let fast = goalMetFasts[i]
                    let fastDay = calendar.startOfDay(for: fast.startTime)

                    if let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDay),
                       calendar.isDate(fastDay, inSameDayAs: previousDay) {
                        streak += 1
                        currentDay = fastDay
                    } else {
                        break
                    }
                }

                currentStreakValue = streak
            }

            // Calculate longest streak by examining ALL streaks in history
            // Always recalculate from scratch to ensure accuracy
            var maxStreak = 0
            var tempStreak = 0
            var lastDay: Date?

            // Sort by date (oldest first) for easier consecutive day detection
            let sortedFasts = goalMetFasts.sorted { $0.startTime < $1.startTime }

            for fast in sortedFasts {
                let fastDay = calendar.startOfDay(for: fast.startTime)

                if let last = lastDay {
                    let dayDiff = calendar.dateComponents([.day], from: last, to: fastDay).day ?? 0

                    if dayDiff == 1 {
                        // Consecutive day - continue streak
                        tempStreak += 1
                    } else {
                        // Gap detected - start new streak
                        tempStreak = 1
                    }
                } else {
                    // First fast in sorted list
                    tempStreak = 1
                }

                // Update max if this streak is longer
                if tempStreak > maxStreak {
                    maxStreak = tempStreak
                }

                lastDay = fastDay
            }

            // Update @Published properties on main thread
            print("\n📈 STREAK CALCULATION RESULTS:")
            let currentDayText = currentStreakValue == 1 ? "day" : "days"
            let longestDayText = maxStreak == 1 ? "day" : "days"
            print("   Current Streak: \(currentStreakValue) \(currentDayText)")
            print("   Longest Streak: \(maxStreak) \(longestDayText)")

            DispatchQueue.main.async {
                let oldCurrent = self.currentStreak
                let oldLongest = self.longestStreak

                self.currentStreak = currentStreakValue
                self.longestStreak = maxStreak
                self.saveStreak()
                self.saveLongestStreak()

                if oldCurrent != currentStreakValue || oldLongest != maxStreak {
                    print("🔄 Streak updated: Current \(oldCurrent) → \(currentStreakValue), Longest \(oldLongest) → \(maxStreak)")
                } else {
                    print("✅ Streak unchanged")
                }

                print("=====================================\n")
            }
        } // end historyQueue.async
    }

    private func saveStreak() {
        let success = dataStore.safeSave(currentStreak, forKey: streakKey)
        if !success {
            CrashReportManager.shared.recordFastingError(
                NSError(domain: "Persistence", code: 1006, userInfo: [NSLocalizedDescriptionKey: "Failed to save current streak"]),
                context: ["operation": "saveStreak", "streak": currentStreak]
            )
        }
    }

    private func loadStreak() {
        currentStreak = dataStore.safeLoad(Int.self, forKey: streakKey) ?? 0
    }

    private func saveLongestStreak() {
        let success = dataStore.safeSave(longestStreak, forKey: longestStreakKey)
        if !success {
            CrashReportManager.shared.recordFastingError(
                NSError(domain: "Persistence", code: 1007, userInfo: [NSLocalizedDescriptionKey: "Failed to save longest streak"]),
                context: ["operation": "saveLongestStreak", "streak": longestStreak]
            )
        }
    }

    private func loadLongestStreak() {
        longestStreak = dataStore.safeLoad(Int.self, forKey: longestStreakKey) ?? 0
    }

    // MARK: - Universal HealthKit Sync Architecture (Intermittent Fasting Integration)
    // Following Universal Sync Architecture patterns from handoff.md
    // Advanced approach: Sync fasting sessions as HealthKit Category Samples with custom metadata

    /// Automatic observer-triggered sync (Universal Method #1)
    func syncFromHealthKit(startDate: Date? = nil, completion: ((Int, Error?) -> Void)? = nil) {
        guard syncWithHealthKit else {
            DispatchQueue.main.async {
                completion?(0, nil)
            }
            return
        }

        guard HealthKitManager.shared.isFastingAuthorized() else {
            AppLogger.warning("HealthKit not authorized for fasting sync", category: AppLogger.fasting)
            DispatchQueue.main.async {
                completion?(0, NSError(domain: "FastingManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit not authorized"]))
            }
            return
        }

        // Prevent sync during observer suppression (manual operations)
        guard !isSuppressingObserver else {
            AppLogger.info("Skipping HealthKit fasting sync - observer suppressed during manual operation", category: AppLogger.fasting)
            DispatchQueue.main.async {
                completion?(0, nil)
            }
            return
        }

        // Default to comprehensive sync (6 months) for fasting data consistency
        let fromDate = startDate ?? Calendar.current.date(byAdding: .month, value: -6, to: Date())!

        AppLogger.info("Starting fasting sync from HealthKit", category: AppLogger.fasting)

        HealthKitManager.shared.fetchFastingSessions(startDate: fromDate) { [weak self] (fastingSessions: [FastingSession]) in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion?(0, NSError(domain: "FastingManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "FastingManager deallocated"]))
                }
                return
            }

            // Industry Standard: All @Published property updates must be on main thread (SwiftUI + HealthKit best practice)
            DispatchQueue.main.async {
                // Use history queue for thread-safe history modification
                self.historyQueue.async {
                    // Track newly added entries for accurate reporting
                    var newlyAddedCount = 0

                    // Import fasting sessions from HealthKit with robust deduplication
                    for hkSession in fastingSessions {
                        // Comprehensive duplicate check following WeightManager pattern
                        let isDuplicate = self.fastingHistory.contains { existingSession in
                            abs(existingSession.startTime.timeIntervalSince(hkSession.startTime)) < 300 && // Within 5 minutes
                            existingSession.isComplete == hkSession.isComplete &&
                            (existingSession.endTime == nil) == (hkSession.endTime == nil) // Both nil or both non-nil
                        }

                        if !isDuplicate {
                            let session = FastingSession(
                                startTime: hkSession.startTime,
                                endTime: hkSession.endTime,
                                goalHours: hkSession.goalHours,
                                eatingWindowDuration: hkSession.eatingWindowDuration,
                                source: .healthKit
                            )
                            self.fastingHistory.append(session)
                            newlyAddedCount += 1
                        }
                    }

                    // Update @Published properties on main thread
                    DispatchQueue.main.async {
                        // Sort by start time (most recent first) and save
                        self.fastingHistory.sort { $0.startTime > $1.startTime }
                        self.saveHistory()

                        // Recalculate streaks after sync
                        self.calculateStreakFromHistory()

                        // Report sync results
                        AppLogger.info("HealthKit fasting sync completed: \\(newlyAddedCount) new fasting sessions added", category: AppLogger.fasting)
                        completion?(newlyAddedCount, nil)
                    }
                }
            }
        }
    }

    /// Complete historical data import (Universal Method #2)
    func syncFromHealthKitHistorical(startDate: Date, completion: @escaping (Int, Error?) -> Void) {
        guard syncWithHealthKit else {
            DispatchQueue.main.async {
                completion(0, NSError(domain: "FastingManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit sync is disabled"]))
            }
            return
        }

        AppLogger.info("Starting historical fasting sync from HealthKit from \\(startDate)", category: AppLogger.fasting)

        HealthKitManager.shared.fetchFastingSessions(startDate: startDate) { [weak self] (fastingSessions: [FastingSession]) in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion(0, NSError(domain: "FastingManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "FastingManager instance deallocated"]))
                }
                return
            }

            // Industry Standard: All @Published property updates must be on main thread (SwiftUI + HealthKit best practice)
            DispatchQueue.main.async {
                // Use history queue for thread-safe history modification
                self.historyQueue.async {
                    // Track newly added entries for accurate reporting
                    var newlyAddedCount = 0

                    // Merge HealthKit fasting sessions with local sessions using robust deduplication
                    for hkSession in fastingSessions {
                        // Historical import uses more flexible duplicate check
                        let isDuplicate = self.fastingHistory.contains { existingSession in
                            abs(existingSession.startTime.timeIntervalSince(hkSession.startTime)) < 600 && // Within 10 minutes (flexible for historical)
                            existingSession.isComplete == hkSession.isComplete
                        }

                        if !isDuplicate {
                            let session = FastingSession(
                                startTime: hkSession.startTime,
                                endTime: hkSession.endTime,
                                goalHours: hkSession.goalHours,
                                eatingWindowDuration: hkSession.eatingWindowDuration,
                                source: .healthKit
                            )
                            self.fastingHistory.append(session)
                            newlyAddedCount += 1
                        }
                    }

                    // Update @Published properties on main thread
                    DispatchQueue.main.async {
                        // Sort by start time (most recent first)
                        self.fastingHistory.sort { $0.startTime > $1.startTime }
                        self.saveHistory()

                        // Recalculate streaks after sync
                        self.calculateStreakFromHistory()

                        // Report actual sync results
                        AppLogger.info("Historical HealthKit fasting sync completed: \\(newlyAddedCount) new fasting sessions imported from \\(fastingSessions.count) total sessions", category: AppLogger.fasting)
                        completion(newlyAddedCount, nil)
                    }
                }
            }
        }
    }

    /// Manual sync with deletion detection (Universal Method #3)
    func syncFromHealthKitWithReset(startDate: Date, completion: @escaping (Int, Error?) -> Void) {
        guard syncWithHealthKit else {
            DispatchQueue.main.async {
                completion(0, NSError(domain: "FastingManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit sync is disabled"]))
            }
            return
        }

        AppLogger.info("Starting manual fasting sync with anchor reset for deletion detection from \\(startDate)", category: AppLogger.fasting)

        HealthKitManager.shared.fetchFastingSessions(startDate: startDate) { [weak self] (fastingSessions: [FastingSession]) in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion(0, NSError(domain: "FastingManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "FastingManager instance deallocated"]))
                }
                return
            }

            // Industry Standard: All @Published property updates must be on main thread (SwiftUI + HealthKit best practice)
            DispatchQueue.main.async {
                // Use history queue for thread-safe history modification
                self.historyQueue.async {
                    // Industry Standard: Complete sync with deletion detection
                    // Step 1: Remove HealthKit entries that are no longer in Apple Health
                    let originalCount = self.fastingHistory.count

                    self.fastingHistory.removeAll { fastLifeSession in
                        // Only remove HealthKit-sourced sessions (preserve manual sessions)
                        guard fastLifeSession.source == .healthKit else {
                            return false
                        }

                        // Check if this Fast LIFe fasting session still exists in current HealthKit data
                        let stillExistsInHealthKit = fastingSessions.contains { healthKitSession in
                            let timeDiff = abs(fastLifeSession.startTime.timeIntervalSince(healthKitSession.startTime))
                            return timeDiff < 300 && // Within 5 minutes
                                   fastLifeSession.isComplete == healthKitSession.isComplete
                        }

                        return !stillExistsInHealthKit
                    }
                    _ = originalCount - self.fastingHistory.count  // Explicitly ignore deletedCount calculation
                    AppLogger.info("Manual sync: Removed \\(originalCount - self.fastingHistory.count) obsolete fasting sessions", category: AppLogger.fasting)

                    // Step 2: Add new HealthKit fasting sessions not already in Fast LIFe
                    var addedCount = 0
                    for healthKitSession in fastingSessions {
                        let alreadyExists = self.fastingHistory.contains { fastLifeSession in
                            let timeDiff = abs(fastLifeSession.startTime.timeIntervalSince(healthKitSession.startTime))
                            return timeDiff < 300 &&
                                   fastLifeSession.isComplete == healthKitSession.isComplete
                        }

                        if !alreadyExists {
                            let session = FastingSession(
                                startTime: healthKitSession.startTime,
                                endTime: healthKitSession.endTime,
                                goalHours: healthKitSession.goalHours,
                                eatingWindowDuration: healthKitSession.eatingWindowDuration,
                                source: .healthKit
                            )
                            self.fastingHistory.append(session)
                            addedCount += 1
                        }
                    }

                    // Update @Published properties on main thread
                    DispatchQueue.main.async {
                        // Sort by start time (most recent first) and save
                        self.fastingHistory.sort { $0.startTime > $1.startTime }
                        self.saveHistory()

                        // Recalculate streaks after sync
                        self.calculateStreakFromHistory()

                        // Report comprehensive sync results
                        AppLogger.info("Manual HealthKit fasting sync completed: \\(addedCount) sessions added, \\(originalCount - self.fastingHistory.count) sessions removed, \\(fastingSessions.count) total HealthKit sessions", category: AppLogger.fasting)
                        completion(addedCount, nil)
                    }
                }
            }
        }
    }

    // MARK: - Observer Pattern Implementation

    /// Start observing HealthKit for automatic fasting sync (Universal Pattern)
    func startObservingHealthKit() {
        guard syncWithHealthKit && HealthKitManager.shared.isFastingAuthorized() else {
            AppLogger.info("Fasting HealthKit observer not started - sync disabled or not authorized", category: AppLogger.fasting)
            return
        }

        // Start observing fasting data changes
        HealthKitManager.shared.startObservingFasting { [weak self] in
            guard let self = self else { return }

            // Industry Standard: All @Published property updates must be on main thread
            DispatchQueue.main.async {
                // Trigger automatic sync when HealthKit fasting data changes
                self.syncFromHealthKit { count, error in
                    if let error = error {
                        AppLogger.error("Observer-triggered fasting sync failed", category: AppLogger.fasting, error: error)
                    } else if count > 0 {
                        AppLogger.info("Observer-triggered fasting sync: \\(count) new fasting sessions added", category: AppLogger.fasting)
                    }
                }
            }
        }

        AppLogger.info("Fasting HealthKit observer started successfully - automatic sync enabled", category: AppLogger.fasting)
    }

    /// Stop observing HealthKit (Universal Pattern)
    func stopObservingHealthKit() {
        HealthKitManager.shared.stopObservingFasting()
        observerQuery = nil
        AppLogger.info("Fasting HealthKit observer stopped", category: AppLogger.fasting)
    }

    // MARK: - Preference Management (Universal Pattern)

    func setSyncPreference(_ enabled: Bool) {
        AppLogger.info("Setting fasting sync preference to \\(enabled)", category: AppLogger.fasting)
        syncWithHealthKit = enabled
        _ = dataStore.safeSave(enabled, forKey: syncPreferenceKey)

        if enabled {
            // Request fasting authorization
            if !HealthKitManager.shared.isFastingAuthorized() {
                HealthKitManager.shared.requestFastingAuthorization { [weak self] success, error in
                    DispatchQueue.main.async {
                        if success {
                            AppLogger.info("Fasting authorization granted, syncing from HealthKit", category: AppLogger.fasting)
                            self?.syncFromHealthKit { _, _ in }
                            self?.startObservingHealthKit()
                        } else {
                            AppLogger.error("Fasting authorization failed", category: AppLogger.fasting, error: error)
                        }
                    }
                }
            } else {
                AppLogger.info("Already authorized for fasting, syncing from HealthKit", category: AppLogger.fasting)
                syncFromHealthKit { _, _ in }
                startObservingHealthKit()
            }
        } else {
            AppLogger.info("Fasting sync disabled, stopping HealthKit observer", category: AppLogger.fasting)
            stopObservingHealthKit()
        }
    }

    private func loadSyncPreference() {
        syncWithHealthKit = dataStore.safeLoad(Bool.self, forKey: syncPreferenceKey) ?? false
    }

    func hasCompletedInitialImport() -> Bool {
        return dataStore.safeLoad(Bool.self, forKey: hasCompletedInitialImportKey) ?? false
    }

    func markInitialImportComplete() {
        let success = dataStore.safeSave(true, forKey: hasCompletedInitialImportKey)
        if !success {
            AppLogger.warning("Failed to mark fasting initial import as complete", category: AppLogger.fasting)
        }
    }

    /// Sync active session to HealthKit when starting/stopping fasting
    private func syncActiveSessionToHealthKit() {
        guard syncWithHealthKit && HealthKitManager.shared.isFastingAuthorized() else { return }

        // Observer suppression prevents infinite sync loops
        isSuppressingObserver = true

        if let session = currentSession {
            // Save current session to HealthKit
            HealthKitManager.shared.saveFastingSession(session) { [weak self] success, error in
                // Re-enable observer after HealthKit write completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self?.isSuppressingObserver = false
                    AppLogger.info("Observer suppression lifted after fasting session sync", category: AppLogger.fasting)
                }

                if let error = error {
                    AppLogger.error("Failed to sync fasting session to HealthKit", category: AppLogger.fasting, error: error)
                } else if success {
                    AppLogger.info("Synced fasting session to HealthKit", category: AppLogger.fasting)
                }
            }
        } else {
            // Reset suppression if no session
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.isSuppressingObserver = false
            }
        }
    }
}
