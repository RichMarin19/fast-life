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
    private let userDefaults = UserDefaults.standard
    private let currentSessionKey = "currentFastingSession"
    private let historyKey = "fastingHistory"
    private let goalKey = "fastingGoalHours"
    private let streakKey = "currentStreak"
    private let longestStreakKey = "longestStreak"

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

        // Start timer immediately if there's an active session (critical for Timer tab UI)
        if currentSession != nil {
            startTimer()
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

    func startFast() {
        print("\n⏱️  === START FAST ===")
        print("Goal: \(fastingGoalHours)h")
        print("Current Streak: \(currentStreak)")

        let session = FastingSession(startTime: Date(), goalHours: fastingGoalHours)
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

        print("✅ Fast started successfully")
        print("=========================\n")
    }

    func stopFast() {
        print("\n🛑 === STOP FAST ===")
        guard var session = currentSession else {
            print("❌ No active session to stop")
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

        var session = FastingSession(startTime: startTime, goalHours: goalHours)
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

        let calendar = Calendar.current
        let sessionDay = calendar.startOfDay(for: session.startTime)

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
        if let encoded = try? JSONEncoder().encode(session) {
            userDefaults.set(encoded, forKey: currentSessionKey)
        }
    }

    private func loadCurrentSession() {
        guard let data = userDefaults.data(forKey: currentSessionKey),
              let session = try? JSONDecoder().decode(FastingSession.self, from: data) else {
            return
        }
        currentSession = session
    }

    private func clearCurrentSession() {
        userDefaults.removeObject(forKey: currentSessionKey)
    }

    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(fastingHistory) {
            userDefaults.set(encoded, forKey: historyKey)
        }
    }

    private func loadHistory() {
        guard let data = userDefaults.data(forKey: historyKey),
              let history = try? JSONDecoder().decode([FastingSession].self, from: data) else {
            return
        }
        // Filter out any incomplete sessions from history (safety check)
        fastingHistory = history.filter { $0.isComplete }.sorted { $0.startTime > $1.startTime }
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
            guard let data = self.userDefaults.data(forKey: self.historyKey),
                  let history = try? JSONDecoder().decode([FastingSession].self, from: data) else {
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
        userDefaults.set(hours, forKey: goalKey)
    }

    private func loadGoal() {
        let savedGoal = userDefaults.double(forKey: goalKey)
        if savedGoal > 0 {
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
        userDefaults.set(currentStreak, forKey: streakKey)
    }

    private func loadStreak() {
        currentStreak = userDefaults.integer(forKey: streakKey)
    }

    private func saveLongestStreak() {
        userDefaults.set(longestStreak, forKey: longestStreakKey)
    }

    private func loadLongestStreak() {
        longestStreak = userDefaults.integer(forKey: longestStreakKey)
    }
}
