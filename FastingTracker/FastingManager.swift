import Foundation
import Combine

class FastingManager: ObservableObject {
    @Published var currentSession: FastingSession?
    @Published var fastingHistory: [FastingSession] = []
    @Published var elapsedTime: TimeInterval = 0
    @Published var fastingGoalHours: Double = 16
    @Published var currentStreak: Int = 0

    private var timer: AnyCancellable?
    private let userDefaults = UserDefaults.standard
    private let currentSessionKey = "currentFastingSession"
    private let historyKey = "fastingHistory"
    private let goalKey = "fastingGoalHours"
    private let streakKey = "currentStreak"

    init() {
        loadGoal()
        loadCurrentSession()
        loadHistory()
        loadStreak()
        // Recalculate streak from history to ensure accuracy
        calculateStreakFromHistory()
        if currentSession != nil {
            startTimer()
        }
    }

    var remainingTime: TimeInterval {
        let goalSeconds = fastingGoalHours * 3600
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

        // Schedule notification
        NotificationManager.shared.scheduleGoalNotification(for: session, goalHours: fastingGoalHours)
    }

    func stopFast() {
        guard var session = currentSession else { return }
        session.endTime = Date()

        // Update streak based on goal completion
        updateStreak(for: session)

        // Add to history (one entry per day)
        addToHistory(session)

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

        // Update streak based on goal completion (with custom duration)
        updateStreak(for: session)

        // Add to history (one entry per day)
        addToHistory(session)

        currentSession = nil
        clearCurrentSession()
        stopTimer()

        // Cancel notification
        NotificationManager.shared.cancelGoalNotification()
    }

    func addManualFast(startTime: Date, endTime: Date, goalHours: Double) {
        var session = FastingSession(startTime: startTime, goalHours: goalHours)
        session.endTime = endTime

        // Update streak based on goal completion
        updateStreak(for: session)

        // Add to history (one entry per day)
        addToHistory(session)
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

        // Keep last 10
        if fastingHistory.count > 10 {
            fastingHistory = Array(fastingHistory.prefix(10))
        }

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

    private func saveCurrentSession() {
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
            currentStreak = 0
            saveStreak()
            return
        }

        // Start from the most recent goal-met fast
        let mostRecentFast = goalMetFasts[0]
        let mostRecentDay = calendar.startOfDay(for: mostRecentFast.startTime)

        // Calculate days between today and most recent fast
        let daysBetween = calendar.dateComponents([.day], from: mostRecentDay, to: today).day ?? 0

        // Streak is broken if most recent fast is more than 1 day ago
        if daysBetween > 1 {
            currentStreak = 0
            saveStreak()
            return
        }

        var streak = 1
        var currentDay = mostRecentDay

        // Count consecutive days going backwards
        for i in 1..<goalMetFasts.count {
            let fast = goalMetFasts[i]
            let fastDay = calendar.startOfDay(for: fast.startTime)

            // Check if this fast is the day before currentDay
            if let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDay),
               calendar.isDate(fastDay, inSameDayAs: previousDay) {
                streak += 1
                currentDay = fastDay
            } else {
                // Streak is broken
                break
            }
        }

        currentStreak = streak
        saveStreak()
    }

    private func saveStreak() {
        userDefaults.set(currentStreak, forKey: streakKey)
    }

    private func loadStreak() {
        currentStreak = userDefaults.integer(forKey: streakKey)
    }
}
