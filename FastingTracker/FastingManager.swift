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

    init() {
        loadGoal()
        loadCurrentSession()
        loadHistory()
        loadStreak()
        loadLongestStreak()

        // Start timer immediately if there's an active session (critical for UI)
        if currentSession != nil {
            startTimer()
        }

        // Recalculate streak asynchronously to avoid blocking app launch
        // This ensures accuracy but doesn't delay the initial UI render
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.calculateStreakFromHistory()
        }
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
        let session = FastingSession(startTime: Date(), goalHours: fastingGoalHours)
        currentSession = session
        saveCurrentSession()
        startTimer()

        // Schedule notification with streak context
        NotificationManager.shared.scheduleGoalNotification(
            for: session,
            goalHours: fastingGoalHours,
            currentStreak: currentStreak,
            longestStreak: longestStreak
        )
    }

    func stopFast() {
        guard var session = currentSession else { return }
        session.endTime = Date()

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
        var session = FastingSession(startTime: startTime, goalHours: goalHours)
        session.endTime = endTime

        // Add to history FIRST (one entry per day)
        addToHistory(session)

        // Then update streak based on goal completion
        // This ensures the new session is included in streak calculations
        updateStreak(for: session)
    }

    func deleteFast(for date: Date) {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)

        // Remove the fast for this day
        fastingHistory.removeAll { session in
            calendar.startOfDay(for: session.startTime) == targetDay
        }

        // Recalculate streaks from history (deleting may break streak)
        calculateStreakFromHistory()

        saveHistory()
    }

    private func addToHistory(_ session: FastingSession) {
        let calendar = Calendar.current
        let sessionDay = calendar.startOfDay(for: session.startTime)

        // Check if there's already a fast for this day
        if let existingIndex = fastingHistory.firstIndex(where: {
            calendar.startOfDay(for: $0.startTime) == sessionDay
        }) {
            // Replace existing fast for this day
            fastingHistory[existingIndex] = session
        } else {
            // Add new fast
            fastingHistory.append(session)
        }

        // Sort by date (most recent first)
        fastingHistory.sort { $0.startTime > $1.startTime }

        // No limit on history - need all data for lifetime statistics and streak calculations
        saveHistory()
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
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get all goal-met fasts sorted by date (most recent first)
        let goalMetFasts = fastingHistory
            .filter { $0.metGoal }
            .sorted { $0.startTime > $1.startTime }

        guard !goalMetFasts.isEmpty else {
            DispatchQueue.main.async { [weak self] in
                self?.currentStreak = 0
                self?.saveStreak()
            }
            return
        }

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
        DispatchQueue.main.async { [weak self] in
            self?.currentStreak = currentStreakValue
            self?.longestStreak = maxStreak
            self?.saveStreak()
            self?.saveLongestStreak()
        }
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
