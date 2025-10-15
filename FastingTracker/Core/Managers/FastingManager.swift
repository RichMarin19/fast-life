import Foundation
import Combine

@MainActor
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
        AppLogger.info("Starting new fasting session", category: AppLogger.fasting)

        // ROADMAP REQUIREMENT: Guard overlapping sessions - reject invalid state transition (start→start)
        // Following Apple State Management best practices
        // Reference: https://developer.apple.com/documentation/swift/maintaining_state_in_your_apps
        guard currentSession == nil else {
            AppLogger.error("Cannot start fast - session already active", category: AppLogger.fasting)
            AppLogger.error("Prevented invalid fasting state transition: start→start", category: AppLogger.fasting)
            return
        }

        AppLogger.info("Fast configuration: goal=\(fastingGoalHours)h, currentStreak=\(currentStreak)", category: AppLogger.fasting)

        // Calculate eating window duration if there's a previous fast
        var eatingWindowDuration: TimeInterval? = nil
        if let lastFast = fastingHistory.first, let lastEndTime = lastFast.endTime {
            eatingWindowDuration = Date().timeIntervalSince(lastEndTime)
            let hours = eatingWindowDuration! / 3600
            AppLogger.debug("Eating window calculated: \(String(format: "%.1f", hours))h since last fast ended", category: AppLogger.fasting)
        } else {
            AppLogger.debug("No previous fast found - first fast or no history", category: AppLogger.fasting)
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

        AppLogger.info("Fast started successfully", category: AppLogger.fasting)
    }

    func stopFast() {
        AppLogger.info("Stopping current fasting session", category: AppLogger.fasting)

        // ROADMAP REQUIREMENT: Reject invalid state transitions (end without active)
        // Following Apple State Management best practices
        guard var session = currentSession else {
            AppLogger.error("Cannot stop fast - no active session", category: AppLogger.fasting)
            AppLogger.error("Prevented invalid fasting state transition: end without active", category: AppLogger.fasting)
            return
        }

        session.endTime = Date()
        let duration = session.endTime!.timeIntervalSince(session.startTime) / 3600
        AppLogger.info("Fast session completed: duration=\(String(format: "%.2f", duration))h", category: AppLogger.fasting)
        AppLogger.debug("Session goal: \(session.goalHours ?? 16)h", category: AppLogger.fasting)
        let goalStatus = session.metGoal ? "✅" : "❌"
        AppLogger.info("Goal achievement status: metGoal=\(goalStatus)", category: AppLogger.fasting)

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

        AppLogger.info("Fast stopped successfully", category: AppLogger.fasting)
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
        AppLogger.info("Adding manual fast session", category: AppLogger.fasting)
        AppLogger.debug("Manual fast parameters: start=\(startTime), end=\(endTime), goal=\(goalHours)h", category: AppLogger.fasting)

        // Calculate eating window if there's a previous fast before this manual entry
        var eatingWindowDuration: TimeInterval? = nil
        if let lastFast = fastingHistory.first, let lastEndTime = lastFast.endTime {
            // Only calculate if the manual fast starts after the previous fast ended
            if startTime > lastEndTime {
                eatingWindowDuration = startTime.timeIntervalSince(lastEndTime)
                let hours = eatingWindowDuration! / 3600
                AppLogger.debug("Eating window for manual fast: \(String(format: "%.1f", hours))h since last fast ended", category: AppLogger.fasting)
            }
        }

        var session = FastingSession(startTime: startTime, goalHours: goalHours, eatingWindowDuration: eatingWindowDuration)
        session.endTime = endTime

        let duration = endTime.timeIntervalSince(startTime) / 3600
        AppLogger.info("Fast session completed: duration=\(String(format: "%.2f", duration))h", category: AppLogger.fasting)
        let goalStatus = session.metGoal ? "✅" : "❌"
        AppLogger.info("Goal achievement status: metGoal=\(goalStatus)", category: AppLogger.fasting)
        AppLogger.debug("Manual fasts do not trigger notifications by design", category: AppLogger.fasting)

        // Add to history FIRST (one entry per day)
        addToHistory(session)

        // Then update streak based on goal completion
        // This ensures the new session is included in streak calculations
        updateStreak(for: session)

        AppLogger.info("Manual fast added successfully", category: AppLogger.fasting)
    }

    func deleteFast(for date: Date) {
        AppLogger.info("Deleting fast session for date: \(date)", category: AppLogger.fasting)

        // THREAD SAFETY: Synchronize deletion with serial queue
        historyQueue.async { [weak self] in
            guard let self = self else { return }

            AppLogger.debug("Executing deletion on background queue", category: AppLogger.fasting)

            let calendar = Calendar.current
            let targetDay = calendar.startOfDay(for: date)

            // Remove the fast for this day and recalculate streaks (must update on main thread for @Published)
            Task { @MainActor in
                let beforeCount = self.fastingHistory.count
                self.fastingHistory.removeAll { session in
                    calendar.startOfDay(for: session.startTime) == targetDay
                }
                let afterCount = self.fastingHistory.count
                AppLogger.debug("History updated after deletion: \(beforeCount) → \(afterCount)", category: AppLogger.fasting)
                self.saveHistory()

                // Recalculate streaks from history (deleting may break streak)
                self.calculateStreakFromHistory()
            }

            AppLogger.info("Fast deleted successfully", category: AppLogger.fasting)
        }
    }

    private func addToHistory(_ session: FastingSession) {
        AppLogger.debug("Adding session to history: date=\(session.startTime), duration=\(session.duration)h", category: AppLogger.fasting)

        // ROADMAP REQUIREMENT: Handle day-boundary and time zone transitions
        // Following Apple Calendar best practices for timezone-aware date handling
        // Reference: https://developer.apple.com/documentation/foundation/calendar
        let calendar = Calendar.current
        let sessionDay = calendar.startOfDay(for: session.startTime)

        // Log timezone information for debugging day-boundary issues
        let timeZone = calendar.timeZone
        AppLogger.debug("Session timezone: \(timeZone.identifier)", category: AppLogger.fasting)
        AppLogger.debug("Session day (start of day): \(sessionDay)", category: AppLogger.fasting)

        let beforeCount = fastingHistory.count

        // Check if there's already a fast for this day
        if let existingIndex = fastingHistory.firstIndex(where: {
            calendar.startOfDay(for: $0.startTime) == sessionDay
        }) {
            AppLogger.debug("Replacing existing fast for this day", category: AppLogger.fasting)
            // Replace existing fast for this day
            fastingHistory[existingIndex] = session
        } else {
            AppLogger.debug("Adding new fast to history", category: AppLogger.fasting)
            // Add new fast
            fastingHistory.append(session)
        }

        // Sort by date (most recent first)
        fastingHistory.sort { $0.startTime > $1.startTime }

        AppLogger.debug("History count updated: \(beforeCount) → \(fastingHistory.count)", category: AppLogger.fasting)

        // No limit on history - need all data for lifetime statistics and streak calculations
        saveHistory()

        AppLogger.info("Added to history successfully", category: AppLogger.fasting)
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
        AppLogger.debug("Loading fasting history asynchronously", category: AppLogger.fasting)

        // THREAD SAFETY: Use historyQueue instead of global queue for synchronized access
        historyQueue.async { [weak self] in
            guard let self = self else { return }

            AppLogger.debug("Executing history load on background queue", category: AppLogger.fasting)

            // Swift 6 Compliance: Access MainActor-isolated properties within Task block
            Task { @MainActor in
                // Load and decode history on background thread with MainActor access
                guard let history = self.dataStore.safeLoad([FastingSession].self, forKey: self.historyKey) else {
                    AppLogger.debug("No history found or decode failed", category: AppLogger.fasting)
                    return
                }

                let filteredHistory = history.filter { $0.isComplete }.sorted { $0.startTime > $1.startTime }
                AppLogger.debug("History loaded from storage: \(filteredHistory.count) complete fasts", category: AppLogger.fasting)

                // Update @Published property and recalculate streaks on main thread
                self.fastingHistory = filteredHistory
                AppLogger.debug("History updated on main thread", category: AppLogger.fasting)

                // Recalculate streaks after history update
                self.calculateStreakFromHistory()
            }

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
        AppLogger.debug("Starting streak calculation from fasting history", category: AppLogger.fasting)

        // SWIFT CONCURRENCY: Use Task to properly isolate @MainActor data access
        // Ensures streak calculation uses up-to-date history with proper actor isolation
        // Reference: https://developer.apple.com/documentation/swift/mainactor
        Task { @MainActor [weak self] in
            guard let self = self else { return }

            AppLogger.debug("Executing streak calculation on MainActor", category: AppLogger.fasting)

            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())

            // Access fastingHistory directly - we're on MainActor
            let historyCopy = self.fastingHistory
            AppLogger.debug("Processing fasting history: \(historyCopy.count) total sessions", category: AppLogger.fasting)

            // Get all goal-met fasts sorted by date (most recent first)
            let goalMetFasts = historyCopy
                .filter { $0.metGoal }
                .sorted { $0.startTime > $1.startTime }

            AppLogger.debug("Goal-met fasts found: \(goalMetFasts.count) sessions", category: AppLogger.fasting)

            guard !goalMetFasts.isEmpty else {
                AppLogger.debug("No goal-met fasts found, streak = 0", category: AppLogger.fasting)
                self.currentStreak = 0
                self.saveStreak()
                return
            }

            let formatter = DateFormatter()
            formatter.dateStyle = .short
            AppLogger.debug("Most recent goal-met fast: \(formatter.string(from: goalMetFasts[0].startTime))", category: AppLogger.fasting)

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
            AppLogger.info("Streak calculation completed: current=\(currentStreakValue), longest=\(maxStreak)", category: AppLogger.fasting)

            let oldCurrent = self.currentStreak
            let oldLongest = self.longestStreak

            self.currentStreak = currentStreakValue
            self.longestStreak = maxStreak
            self.saveStreak()
            self.saveLongestStreak()

            if oldCurrent != currentStreakValue || oldLongest != maxStreak {
                AppLogger.info("Streak updated: current \(oldCurrent)→\(currentStreakValue), longest \(oldLongest)→\(maxStreak)", category: AppLogger.fasting)
            } else {
                AppLogger.debug("Streak unchanged", category: AppLogger.fasting)
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

            // Industry Standard: Process HealthKit data on MainActor for @Published property access
            Task { @MainActor in
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

                // Sort by start time (most recent first) and save
                self.fastingHistory.sort { $0.startTime > $1.startTime }
                self.saveHistory()

                // Recalculate streaks after sync
                self.calculateStreakFromHistory()

                // Report sync results
                AppLogger.info("HealthKit fasting sync completed: \(newlyAddedCount) new fasting sessions added", category: AppLogger.fasting)
                completion?(newlyAddedCount, nil)
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

        AppLogger.info("Starting historical fasting sync from HealthKit from \(startDate)", category: AppLogger.fasting)

        HealthKitManager.shared.fetchFastingSessions(startDate: startDate) { [weak self] (fastingSessions: [FastingSession]) in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion(0, NSError(domain: "FastingManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "FastingManager instance deallocated"]))
                }
                return
            }

            // Industry Standard: Process historical HealthKit data on MainActor for @Published property access
            Task { @MainActor in
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

                // Sort by start time (most recent first)
                self.fastingHistory.sort { $0.startTime > $1.startTime }
                self.saveHistory()

                // Recalculate streaks after sync
                self.calculateStreakFromHistory()

                // Report actual sync results
                AppLogger.info("Historical HealthKit fasting sync completed: \(newlyAddedCount) new fasting sessions imported from \(fastingSessions.count) total sessions", category: AppLogger.fasting)
                completion(newlyAddedCount, nil)
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

        AppLogger.info("Starting manual fasting sync with anchor reset for deletion detection from \(startDate)", category: AppLogger.fasting)

        HealthKitManager.shared.fetchFastingSessions(startDate: startDate) { [weak self] (fastingSessions: [FastingSession]) in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion(0, NSError(domain: "FastingManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "FastingManager instance deallocated"]))
                }
                return
            }

            // Industry Standard: Manual sync with deletion detection on MainActor for @Published property access
            Task { @MainActor in
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
                AppLogger.info("Manual sync: Removed \(originalCount - self.fastingHistory.count) obsolete fasting sessions", category: AppLogger.fasting)

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

                // Sort by start time (most recent first) and save
                self.fastingHistory.sort { $0.startTime > $1.startTime }
                self.saveHistory()

                // Recalculate streaks after sync
                self.calculateStreakFromHistory()

                // Report comprehensive sync results
                AppLogger.info("Manual HealthKit fasting sync completed: \(addedCount) sessions added, \(originalCount - self.fastingHistory.count) sessions removed, \(fastingSessions.count) total HealthKit sessions", category: AppLogger.fasting)
                completion(addedCount, nil)
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
                        AppLogger.info("Observer-triggered fasting sync: \(count) new fasting sessions added", category: AppLogger.fasting)
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
        AppLogger.info("Setting fasting sync preference to \(enabled)", category: AppLogger.fasting)
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
