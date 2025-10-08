import SwiftUI
import Charts

struct WeightTrackingView: View {
    @StateObject private var weightManager = WeightManager()
    @StateObject private var healthKitManager = HealthKitManager.shared
    @StateObject private var nudgeManager = HealthKitNudgeManager.shared
    @State private var showingAddWeight = false
    @State private var showingSettings = false
    @State private var showingFirstTimeSetup = false
    @State private var showingGoalEditor = false  // Quick access goal editor
    @State private var showingTrends = false  // Weight trends detail view
    // Removed: @State private var showingHealthDataSelection - no longer needed with direct authorization
    @State private var selectedTimeRange: WeightTimeRange = .month
    @State private var showGoalLine = false
    @State private var weightGoal: Double = 180.0
    @State private var showHealthKitNudge = false

    // UserDefaults keys for persistence
    private let showGoalLineKey = "showGoalLine"
    private let weightGoalKey = "goalWeight"  // MUST match onboarding key (OnboardingView.swift line 686)

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Large Title: "Weight Tracker" (styled like "Fast LIFe")
                // Per Apple HIG: Use prominent titles for top-level screens
                // Reference: https://developer.apple.com/design/human-interface-guidelines/typography
                if !weightManager.weightEntries.isEmpty {
                    HStack(spacing: 0) {
                        Text("Weight Tr")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                        Text("ac")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                        Text("ker")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.cyan)
                    }
                }

                // HealthKit Nudge for first-time users who skipped onboarding
                // Following Lose It app pattern - contextual banner with single Connect action
                if showHealthKitNudge && nudgeManager.shouldShowNudge(for: .weight) {
                    HealthKitNudgeView(
                        dataType: .weight,
                        onConnect: {
                            // DIRECT AUTHORIZATION: Same pattern as existing weight sync
                            // Request weight permissions immediately when user wants to connect
                            print("📱 WeightTrackingView: HealthKit nudge - requesting weight authorization")
                            HealthKitManager.shared.requestWeightAuthorization { success, error in
                                DispatchQueue.main.async {
                                    if success {
                                        print("✅ WeightTrackingView: Weight authorization granted from nudge")
                                        // Enable sync automatically when granted from nudge
                                        weightManager.syncWithHealthKit = true
                                        // Hide nudge after successful connection
                                        showHealthKitNudge = false
                                    } else {
                                        print("❌ WeightTrackingView: Weight authorization denied from nudge")
                                        // Still hide nudge if user denied (don't keep asking)
                                        nudgeManager.dismissNudge(for: .weight)
                                        showHealthKitNudge = false
                                    }
                                }
                            }
                        },
                        onDismiss: {
                            // Mark nudge as dismissed - won't show again
                            nudgeManager.dismissNudge(for: .weight)
                            showHealthKitNudge = false
                        }
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }

                if weightManager.weightEntries.isEmpty {
                    EmptyWeightStateView(showingAddWeight: $showingAddWeight, healthKitManager: healthKitManager, weightManager: weightManager)
                } else {
                    // Current Weight Card
                    CurrentWeightCard(
                        weightManager: weightManager,
                        weightGoal: weightGoal,
                        showingGoalEditor: $showingGoalEditor,
                        showingAddWeight: $showingAddWeight,
                        showingTrends: $showingTrends
                    )
                    .padding(.horizontal)

                    // Weight Chart
                    WeightChartView(
                        weightManager: weightManager,
                        selectedTimeRange: $selectedTimeRange,
                        showGoalLine: $showGoalLine,
                        weightGoal: $weightGoal
                    )
                    .padding(.horizontal)

                    // Weight Statistics
                    WeightStatsView(weightManager: weightManager)
                        .padding(.horizontal)

                    // Weight History List
                    WeightHistoryListView(weightManager: weightManager)
                        .padding(.horizontal)
                }
            }
            .padding(.bottom)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gear")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddWeight = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddWeight) {
            AddWeightView(weightManager: weightManager)
        }
        .sheet(isPresented: $showingSettings) {
            WeightSettingsView(
                weightManager: weightManager,
                showGoalLine: $showGoalLine,
                weightGoal: $weightGoal
            )
        }
        .sheet(isPresented: $showingGoalEditor) {
            QuickGoalEditorView(weightGoal: $weightGoal)
        }
        .sheet(isPresented: $showingTrends) {
            WeightTrendsView(weightManager: weightManager)
        }
        // Removed: HealthDataSelectionView sheet - using direct authorization per Apple HIG
        .sheet(isPresented: $showingFirstTimeSetup) {
            FirstTimeWeightSetupView(
                weightManager: weightManager,
                weightGoal: $weightGoal,
                showGoalLine: $showGoalLine
            )
        }
        .onAppear {
            // Load saved goal settings from UserDefaults
            loadGoalSettings()

            // Show first-time setup if user has no weight data
            // No delay needed - weightManager loads synchronously in init
            if weightManager.weightEntries.isEmpty {
                showingFirstTimeSetup = true
            }

            // Show HealthKit nudge for first-time users who skipped onboarding
            // Following Lose It pattern - contextual reminder on first tracker access
            showHealthKitNudge = nudgeManager.shouldShowNudge(for: .weight)
            if showHealthKitNudge {
                print("📱 WeightTrackingView: Showing HealthKit nudge for first-time user")
            }

            // Note: Removed auto-authorization logic - now uses nudge banner pattern like HydrationTrackingView
            // User must explicitly tap "Connect" in nudge banner to authorize
            // This follows Lose It app pattern and Apple HIG contextual permission guidelines
        }
        .onChange(of: showGoalLine) { _, _ in
            saveGoalSettings()
        }
        .onChange(of: weightGoal) { _, _ in
            saveGoalSettings()
        }
    }

    // MARK: - Goal Settings Persistence

    private func loadGoalSettings() {
        // Load show goal line preference (default: false)
        showGoalLine = UserDefaults.standard.bool(forKey: showGoalLineKey)

        // Load weight goal (default: 180.0 if not set)
        if let savedGoal = UserDefaults.standard.object(forKey: weightGoalKey) as? Double {
            weightGoal = savedGoal
        }
    }

    func saveGoalSettings() {
        UserDefaults.standard.set(showGoalLine, forKey: showGoalLineKey)
        UserDefaults.standard.set(weightGoal, forKey: weightGoalKey)
    }

    // Removed: handleHealthDataSelection - no longer needed with direct authorization
}

// MARK: - Empty State View

struct EmptyWeightStateView: View {
    @Binding var showingAddWeight: Bool
    let healthKitManager: HealthKitManager
    let weightManager: WeightManager
    // Removed: @State private var showingHealthDataSelection - no longer needed

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "scalemass")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Weight Data Yet")
                .font(.title3)
                .foregroundColor(.secondary)

            Text("Add your first weight entry or sync with Apple Health")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 12) {
                Button(action: { showingAddWeight = true }) {
                    Label("Add Weight Manually", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }

                Button(action: {
                    // DIRECT AUTHORIZATION: Apple HIG contextual permission pattern
                    // Request weight permissions immediately when user wants to sync weight data
                    print("📱 WeightTrackingView (EmptyState): Sync button tapped - requesting weight authorization directly")
                    HealthKitManager.shared.requestWeightAuthorization { success, error in
                        if success {
                            print("✅ WeightTrackingView (EmptyState): Weight authorization granted - starting sync")
                            DispatchQueue.main.async {
                                weightManager.syncFromHealthKit()
                            }
                        } else {
                            print("❌ WeightTrackingView (EmptyState): Weight authorization denied")
                        }
                    }
                }) {
                    Label("Sync with Apple Health", systemImage: "heart.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)
        }
        .frame(maxHeight: .infinity)
        .padding(.top, 60)
        // Removed: HealthDataSelectionView sheet - using direct authorization per Apple HIG
    }

    // Removed: handleHealthDataSelection - no longer needed with direct authorization
}

// MARK: - Current Weight Card

struct CurrentWeightCard: View {
    @ObservedObject var weightManager: WeightManager
    let weightGoal: Double
    @Binding var showingGoalEditor: Bool
    @Binding var showingAddWeight: Bool
    @Binding var showingTrends: Bool

    /// Calculates total weight change from START (first entry) to CURRENT (latest entry)
    /// Returns: (totalChange: Double, isLoss: Bool)
    /// Positive = loss, Negative = gain
    private func calculateTotalProgress() -> (amount: Double, isLoss: Bool)? {
        guard weightManager.weightEntries.count >= 2 else { return nil }

        // Get FIRST entry (start weight from onboarding)
        let sortedEntries = weightManager.weightEntries.sorted { $0.date < $1.date }
        guard let startWeight = sortedEntries.first?.weight,
              let currentWeight = sortedEntries.last?.weight else {
            return nil
        }

        let change = startWeight - currentWeight
        return (amount: abs(change), isLoss: change > 0)
    }

    /// Returns celebration emoji based on weight loss amount
    /// More loss = more exciting emoji! 🎉
    private func celebrationEmoji(for lbs: Double) -> String {
        switch lbs {
        case 0..<1:      return "👍"  // Small loss
        case 1..<2:      return "💪"  // Good loss
        case 2..<3:      return "🌟"  // Great loss
        case 3..<5:      return "🎉"  // Excellent loss
        case 5..<10:     return "🏆"  // Amazing loss
        default:         return "🚀"  // Incredible loss!
        }
    }

    /// Returns gentle message for weight gain - progressively softer as gain increases
    /// Psychology: More gain = MORE supportive, not harsh
    private func gentleGainMessage(for lbs: Double) -> (emoji: String, message: String, color: Color) {
        switch lbs {
        case 0..<1:
            // Tiny fluctuation - totally normal
            return ("💧", "Just water weight", .blue)
        case 1..<2:
            // Small gain - gentle
            return ("🤝", "Small fluctuation, you've got this", .blue)
        case 2..<3:
            // Medium gain - supportive
            return ("💙", "Keep going, progress isn't always linear", .cyan)
        case 3..<5:
            // Larger gain - very supportive
            return ("🌱", "Every journey has ups and downs", .green.opacity(0.7))
        default:
            // Large gain - SUPER gentle and encouraging
            return ("🫂", "You're still on the journey, one day at a time", .purple)
        }
    }

    /// Gets starting weight (first entry from onboarding)
    private func getStartWeight() -> Double? {
        guard weightManager.weightEntries.count >= 1 else { return nil }
        let sortedEntries = weightManager.weightEntries.sorted { $0.date < $1.date }
        return sortedEntries.first?.weight
    }

    /// Calculates weight remaining to reach goal
    private func calculateWeightToGo() -> Double? {
        guard weightManager.weightEntries.count >= 1, weightGoal > 0 else { return nil }
        let sortedEntries = weightManager.weightEntries.sorted { $0.date < $1.date }
        guard let currentWeight = sortedEntries.last?.weight else { return nil }
        let remaining = currentWeight - weightGoal
        return remaining > 0 ? remaining : 0
    }

    /// Calculates progress percentage toward goal weight
    /// Formula: (Starting Weight - Current Weight) / (Starting Weight - Goal Weight) × 100
    /// Returns nil if insufficient data or goal not set
    private func calculateProgressPercentage() -> Double? {
        // Require goal weight to be set
        guard weightGoal > 0 else { return nil }

        // Need at least 2 entries (start and current)
        guard weightManager.weightEntries.count >= 2 else { return nil }

        // Get starting weight (earliest entry) and current weight (latest entry)
        let sortedEntries = weightManager.weightEntries.sorted { $0.date < $1.date }
        guard let startingWeight = sortedEntries.first?.weight,
              let currentWeight = sortedEntries.last?.weight else {
            return nil
        }

        // Calculate progress
        let totalWeightToLose = startingWeight - weightGoal
        let weightLostSoFar = startingWeight - currentWeight

        // Only show progress if:
        // 1. User is trying to lose weight (start > goal)
        // 2. Some progress has been made (current != start)
        // 3. Haven't already passed the goal
        guard totalWeightToLose > 0,
              weightLostSoFar > 0,
              currentWeight > weightGoal else {
            return nil
        }

        let percentage = (weightLostSoFar / totalWeightToLose) * 100.0

        // Cap at 100% even if they've made more progress than expected
        return min(percentage, 100.0)
    }

    var body: some View {
        VStack(spacing: 8) {
            if let latest = weightManager.latestWeight {
                // TAPPABLE Current Weight Section - opens Add Weight sheet
                // Per Apple HIG: "Let people interact with content in ways they find most natural"
                // Reference: https://developer.apple.com/design/human-interface-guidelines/gestures
                VStack(spacing: 6) {
                    // "Current Weight" label
                    Text("Current Weight")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(latest.weight, specifier: "%.1f")")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.86))
                        Text("lbs")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }

                    Text(latest.date, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())  // Make entire area tappable
                .onTapGesture {
                    showingAddWeight = true
                }

                // Weight Change Display - EXCITING, MOTIVATIONAL, CELEBRATORY! 🎉
                // Shows TOTAL progress from START weight to CURRENT weight
                // Per Apple HIG: "Celebrate achievements to encourage healthy behaviors"
                // Reference: https://developer.apple.com/design/human-interface-guidelines/health-and-fitness
                if let progress = calculateTotalProgress() {
                    VStack(spacing: 8) {
                        if progress.isLoss {
                            // WEIGHT LOSS - CELEBRATE! 🎉
                            // TAPPABLE - opens Trends view
                            // Per Apple HIG: "Make it easy for people to drill down into details"
                            HStack(spacing: 8) {
                                // Celebration emoji - dynamic based on amount
                                Text(celebrationEmoji(for: progress.amount))
                                    .font(.system(size: 28))

                                // Weight lost - LARGE and PROUD
                                Text("\(progress.amount, specifier: "%.1f") lbs lost!")
                                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)

                                // Fire emoji for extra motivation
                                Text("🔥")
                                    .font(.system(size: 28))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                // Gradient background - exciting and vibrant
                                LinearGradient(
                                    colors: [Color.green, Color.green.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
                            .contentShape(Rectangle())  // Make entire pill tappable
                            .onTapGesture {
                                showingTrends = true
                            }

                        } else {
                            // WEIGHT GAIN - PROGRESSIVELY GENTLER as gain increases
                            // TAPPABLE - opens Trends view to see patterns
                            // Psychology: More supportive = users stay engaged
                            let gentleMessage = gentleGainMessage(for: progress.amount)

                            HStack(spacing: 8) {
                                // Gentle emoji (changes based on amount)
                                Text(gentleMessage.emoji)
                                    .font(.system(size: 20))

                                // Supportive message (gets softer as gain increases)
                                Text(gentleMessage.message)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(gentleMessage.color)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(gentleMessage.color.opacity(0.08))
                            .cornerRadius(10)
                            .contentShape(Rectangle())  // Make entire message tappable
                            .onTapGesture {
                                showingTrends = true
                            }
                        }
                    }
                    .padding(.top, 8)
                }

                // Goal Display - EXCITING, PROMINENT, MOTIVATIONAL! 🎯
                // ENTIRE PILL IS TAPPABLE for maximum usability
                // Per Apple HIG: "Make controls easy to interact with by giving them ample hit targets"
                // Reference: https://developer.apple.com/design/human-interface-guidelines/buttons
                if weightGoal > 0 {
                    Divider()
                        .padding(.vertical, 4)

                    // Entire pill is tappable - large hit target for better UX
                    Button(action: {
                        showingGoalEditor = true
                    }) {
                        HStack(spacing: 10) {
                            // 🎯 Target emoji for visual excitement
                            Text("🎯")
                                .font(.system(size: 28))

                            // Goal label and value - COMPACT but still EXCITING!
                            (Text("GOAL: ")
                                .font(.system(size: 32, weight: .heavy, design: .rounded))
                                .foregroundColor(.green)
                            + Text("\(Int(weightGoal)) lbs")
                                .font(.system(size: 32, weight: .heavy, design: .rounded))
                                .foregroundColor(.green))

                            // Gear icon visual indicator that this is editable
                            // No longer a separate button - entire pill is tappable
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)  // Reduced for more compact pill
                        .background(
                            // Subtle green background for extra pop
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.green.opacity(0.08))
                        )
                        .overlay(
                            // Green border for emphasis
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.green.opacity(0.3), lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)  // Removes default button styling, keeps custom design

                    // Progress Ring - Beautiful circular visual progress indicator
                    // Inspired by milestone concept with sexy color scheme
                    // Per Apple HIG: "Use visual metaphors to communicate meaning"
                    if let progressPercentage = calculateProgressPercentage(),
                       let progress = calculateTotalProgress(),
                       let startWeight = getStartWeight(),
                       let weightToGo = calculateWeightToGo() {
                        CircularProgressRing(
                            percentage: progressPercentage,
                            weightLost: progress.amount,
                            weightToGo: weightToGo,
                            startWeight: startWeight,
                            goalWeight: weightGoal
                        )
                        .padding(.top, 8)
                    }
                }

                if let bmi = latest.bmi {
                    HStack(spacing: 16) {
                        VStack {
                            Text("BMI")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(bmi, specifier: "%.1f")")
                                .font(.headline)
                        }

                        if let bodyFat = latest.bodyFat {
                            VStack {
                                Text("Body Fat")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(bodyFat, specifier: "%.1f")%")
                                    .font(.headline)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Weight Chart View

enum WeightTimeRange: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case threeMonths = "3 Months"
    case year = "Year"
    case all = "All"

    var days: Int? {
        switch self {
        case .day: return 1
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .year: return 365
        case .all: return nil
        }
    }
}

struct WeightChartView: View {
    @ObservedObject var weightManager: WeightManager
    @Binding var selectedTimeRange: WeightTimeRange
    @Binding var showGoalLine: Bool
    @Binding var weightGoal: Double

    @State private var selectedDate: Date?

    var filteredEntries: [WeightEntry] {
        let calendar = Calendar.current

        // Special handling for Day view: show current calendar day (12am to now)
        if selectedTimeRange == .day {
            let startOfToday = calendar.startOfDay(for: Date())
            return weightManager.weightEntries.filter { $0.date >= startOfToday }
        }

        // For other views: use rolling time window (last N days)
        guard let days = selectedTimeRange.days else {
            return weightManager.weightEntries
        }

        let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return weightManager.weightEntries.filter { $0.date >= cutoffDate }
    }

    // MARK: - Daily Averaged Entries for Week/Month/3Months/Year/All View

    /// For Week/Month/3Months/Year/All view: Groups entries by calendar day and averages weights for each day
    /// This ensures one data point per day even if multiple weigh-ins occurred
    var dailyAveragedEntries: [WeightEntry] {
        let calendar = Calendar.current

        // Group entries by calendar day
        let groupedByDay = Dictionary(grouping: filteredEntries) { entry in
            calendar.startOfDay(for: entry.date)
        }

        // Calculate average weight for each day
        let averagedEntries = groupedByDay.map { (day, entries) -> WeightEntry in
            let avgWeight = entries.reduce(0.0) { $0 + $1.weight } / Double(entries.count)
            let avgBMI = entries.compactMap { $0.bmi }.isEmpty ? nil : entries.compactMap { $0.bmi }.reduce(0.0, +) / Double(entries.compactMap { $0.bmi }.count)
            let avgBodyFat = entries.compactMap { $0.bodyFat }.isEmpty ? nil : entries.compactMap { $0.bodyFat }.reduce(0.0, +) / Double(entries.compactMap { $0.bodyFat }.count)

            // Use the most recent entry's metadata for the day
            let mostRecentEntry = entries.sorted { $0.date > $1.date }.first!

            return WeightEntry(
                id: mostRecentEntry.id,
                date: day, // Use start of day for consistent X-axis positioning
                weight: avgWeight,
                bmi: avgBMI,
                bodyFat: avgBodyFat,
                source: mostRecentEntry.source
            )
        }

        // Sort by date (oldest to newest for chart rendering)
        return averagedEntries.sorted { $0.date < $1.date }
    }

    /// Returns the appropriate data set based on selected time range
    var chartData: [WeightEntry] {
        switch selectedTimeRange {
        case .day:
            // Day view: Show ALL individual data points (no averaging)
            return filteredEntries
        case .week, .month, .threeMonths, .year, .all:
            // Week/Month/3Months/Year/All view: Show daily averaged data (one point per day)
            return dailyAveragedEntries
        }
    }

    /// Find the weight entry closest to the selected date
    var selectedEntry: WeightEntry? {
        guard let selectedDate = selectedDate else { return nil }

        return chartData.min(by: { entry1, entry2 in
            abs(entry1.date.timeIntervalSince(selectedDate)) < abs(entry2.date.timeIntervalSince(selectedDate))
        })
    }

    /// Get current time range label for display (e.g., "September 2025" for Month view)
    var timeRangeLabel: String? {
        guard selectedTimeRange == .month else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }

    // Progress percentage calculation moved to CurrentWeightCard
    // Removed duplicate function to keep code DRY (Don't Repeat Yourself)

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Weight Chart")
                    .font(.headline)
                Spacer()
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(WeightTimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.menu)
            }

            // Display current time range (Month/Year) for Month view
            if let label = timeRangeLabel {
                Text(label)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.86))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Progress percentage moved to CurrentWeightCard (below goal pill)
            // This keeps related information grouped together per Apple HIG

            if !chartData.isEmpty {
                Chart {
                    ForEach(chartData) { entry in
                        LineMark(
                            x: .value("Date", entry.date),
                            y: .value("Weight", entry.weight)
                        )
                        .foregroundStyle(Color(red: 0.2, green: 0.6, blue: 0.86))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", entry.date),
                            y: .value("Weight", entry.weight)
                        )
                        .foregroundStyle(Color(red: 0.2, green: 0.6, blue: 0.86))
                    }

                    if showGoalLine {
                        RuleMark(y: .value("Goal", weightGoal))
                            .foregroundStyle(.green)
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                            .annotation(position: .top, alignment: .trailing) {
                                Text("Goal")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                    }

                    // Selection indicator: vertical line at selected point
                    if let selectedEntry = selectedEntry {
                        RuleMark(x: .value("Selected", selectedEntry.date))
                            .foregroundStyle(.gray.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            .annotation(position: .top, alignment: .center) {
                                VStack(spacing: 4) {
                                    Text("\(selectedEntry.weight, specifier: "%.1f") lbs")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(red: 0.2, green: 0.6, blue: 0.86))
                                        .cornerRadius(6)
                                }
                            }
                    }
                }
                .frame(height: 250)
                .chartXAxis {
                    if selectedTimeRange == .day {
                        // Day view: Show 3-hour increments starting from 6am
                        AxisMarks(values: dayXAxisValues) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(xAxisLabel(for: date))
                                        .font(.caption2)
                                }
                                AxisGridLine()
                                AxisTick()
                            }
                        }
                    } else if selectedTimeRange == .week {
                        // Week view: Show all 7 days
                        AxisMarks(values: weekXAxisValues) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(xAxisLabel(for: date))
                                        .font(.caption2)
                                }
                                AxisGridLine()
                                AxisTick()
                            }
                        }
                    } else if selectedTimeRange == .month {
                        // Month view: Adaptive marks based on data range
                        AxisMarks(values: monthXAxisValues) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(xAxisLabel(for: date))
                                        .font(.caption2)
                                }
                                AxisGridLine()
                                AxisTick()
                            }
                        }
                    } else if selectedTimeRange == .threeMonths {
                        // 3 Months view: Show 12 marks (4 per month)
                        AxisMarks(values: threeMonthsXAxisValues) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(xAxisLabel(for: date))
                                        .font(.caption2)
                                }
                                AxisGridLine()
                                AxisTick()
                            }
                        }
                    } else if selectedTimeRange == .year {
                        // Year view: Show 12 marks (one per month)
                        AxisMarks(values: yearXAxisValues) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(xAxisLabel(for: date))
                                        .font(.caption2)
                                }
                                AxisGridLine()
                                AxisTick()
                            }
                        }
                    } else if selectedTimeRange == .all {
                        // All view: Adaptive marks based on data span
                        AxisMarks(values: allXAxisValues) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(xAxisLabel(for: date))
                                        .font(.caption2)
                                }
                                AxisGridLine()
                                AxisTick()
                            }
                        }
                    } else {
                        // Fallback: automatic marks
                        AxisMarks(values: .automatic) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(xAxisLabel(for: date))
                                        .font(.caption2)
                                }
                                AxisGridLine()
                                AxisTick()
                            }
                        }
                    }
                }
                .chartYAxis {
                    if selectedTimeRange == .day {
                        // Day view: Show fewer marks with "lbs" suffix
                        AxisMarks(position: .leading, values: dayYAxisValues) { value in
                            if let weight = value.as(Double.self) {
                                AxisValueLabel {
                                    Text("\(Int(weight)) lbs")
                                        .font(.caption2)
                                }
                            }
                            AxisGridLine()
                            AxisTick()
                        }
                    } else if selectedTimeRange == .week {
                        // Week view: Show weight values at 1lb intervals with "lbs" suffix
                        AxisMarks(position: .leading, values: weekYAxisValues) { value in
                            if let weight = value.as(Double.self) {
                                AxisValueLabel {
                                    Text("\(Int(weight)) lbs")
                                        .font(.caption2)
                                }
                            }
                            AxisGridLine()
                            AxisTick()
                        }
                    } else if selectedTimeRange == .month {
                        // Month view: Show 10 evenly-spaced marks with "lbs" suffix
                        AxisMarks(position: .leading, values: monthYAxisValues) { value in
                            if let weight = value.as(Double.self) {
                                AxisValueLabel {
                                    Text("\(Int(round(weight))) lbs")
                                        .font(.caption2)
                                }
                            }
                            AxisGridLine()
                            AxisTick()
                        }
                    } else if selectedTimeRange == .threeMonths {
                        // 3 Months view: Show 10 evenly-spaced marks with "lbs" suffix
                        AxisMarks(position: .leading, values: threeMonthsYAxisValues) { value in
                            if let weight = value.as(Double.self) {
                                AxisValueLabel {
                                    Text("\(Int(round(weight))) lbs")
                                        .font(.caption2)
                                }
                            }
                            AxisGridLine()
                            AxisTick()
                        }
                    } else if selectedTimeRange == .year {
                        // Year view: Show 10 evenly-spaced marks with "lbs" suffix
                        AxisMarks(position: .leading, values: yearYAxisValues) { value in
                            if let weight = value.as(Double.self) {
                                AxisValueLabel {
                                    Text("\(Int(round(weight))) lbs")
                                        .font(.caption2)
                                }
                            }
                            AxisGridLine()
                            AxisTick()
                        }
                    } else if selectedTimeRange == .all {
                        // All view: Show 10 evenly-spaced marks with "lbs" suffix
                        AxisMarks(position: .leading, values: allYAxisValues) { value in
                            if let weight = value.as(Double.self) {
                                AxisValueLabel {
                                    Text("\(Int(round(weight))) lbs")
                                        .font(.caption2)
                                }
                            }
                            AxisGridLine()
                            AxisTick()
                        }
                    } else {
                        AxisMarks(position: .leading)
                    }
                }
                .chartYScale(domain: yAxisDomain)
                .modifier(XAxisScaleModifier(domain: xAxisDomain))
                .chartXSelection(value: $selectedDate)
            } else {
                Text("No data for selected time range")
                    .foregroundColor(.secondary)
                    .frame(height: 250)
            }

            // Selected data point details
            if let selectedEntry = selectedEntry {
                VStack(spacing: 8) {
                    Divider()

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Selected Point")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("\(selectedEntry.weight, specifier: "%.1f") lbs")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.86))

                            HStack(spacing: 8) {
                                Text(selectedEntry.date, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                if let displayTime = selectedEntryDisplayTime {
                                    Text("•")
                                        .foregroundColor(.secondary)
                                    Text(displayTime, style: .time)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        Spacer()

                        if selectedEntry.bmi != nil || selectedEntry.bodyFat != nil {
                            VStack(alignment: .trailing, spacing: 4) {
                                if let bmi = selectedEntry.bmi {
                                    HStack(spacing: 4) {
                                        Text("BMI:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("\(bmi, specifier: "%.1f")")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }
                                }

                                if let bodyFat = selectedEntry.bodyFat {
                                    HStack(spacing: 4) {
                                        Text("Body Fat:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("\(bodyFat, specifier: "%.1f")%")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                        }

                        Button(action: {
                            selectedDate = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .font(.title3)
                        }
                    }
                }
                .transition(.opacity)
            }

            Toggle("Show Goal Line", isOn: $showGoalLine)
                .font(.subheadline)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - X-Axis Labels

    private func xAxisLabel(for date: Date) -> String {
        let calendar = Calendar.current

        switch selectedTimeRange {
        case .day:
            // Show hour for Day view (e.g., "12am", "1am", "2pm")
            let formatter = DateFormatter()
            formatter.dateFormat = "ha" // Hour with am/pm
            return formatter.string(from: date).lowercased()

        case .week:
            // Show month/day for last 7 days (e.g., "Sep 24", "Sep 25", "Oct 1")
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d" // "Sep 24", "Oct 1"
            return formatter.string(from: date)

        case .month:
            // Show day of month (1, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30)
            let day = calendar.component(.day, from: date)
            return "\(day)"

        case .threeMonths:
            // Show month/day for 3 months
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            return formatter.string(from: date)

        case .year:
            // Show month abbreviation (Jan, Feb, Mar...)
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            return formatter.string(from: date)

        case .all:
            // Show month/year for all time
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yy"
            return formatter.string(from: date)
        }
    }


    // MARK: - X-Axis Domain for Day View

    /// Returns the X-axis date range for Day/Month view
    /// Day view: 6am to 12am (midnight) by default, adjusts if entries before 6am
    /// Month view: Extends slightly beyond data range for easier point selection
    var xAxisDomain: ClosedRange<Date>? {
        let calendar = Calendar.current

        switch selectedTimeRange {
        case .day:
            guard !chartData.isEmpty else { return nil }

            let today = calendar.startOfDay(for: Date())

            // Default start: 6am today
            guard let defaultStart = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: today) else {
                return nil
            }

            // Default end: 12am (midnight) next day
            guard let defaultEnd = calendar.date(byAdding: .day, value: 1, to: today) else {
                return nil
            }

            // Find the earliest entry time
            let dates = chartData.map { $0.date }
            guard let minDate = dates.min() else { return nil }

            // If earliest entry is before 6am, adjust start time to that entry
            let rangeStart = min(defaultStart, minDate)

            // Always end at midnight (12am next day)
            return rangeStart...defaultEnd

        case .month:
            guard !chartData.isEmpty else { return nil }

            // Extend domain by 1 day on each side for easier point selection
            let dates = chartData.map { $0.date }
            guard let minDate = dates.min(), let maxDate = dates.max() else { return nil }

            guard let rangeStart = calendar.date(byAdding: .day, value: -1, to: minDate),
                  let rangeEnd = calendar.date(byAdding: .day, value: 1, to: maxDate) else {
                return nil
            }

            return rangeStart...rangeEnd

        case .threeMonths:
            guard !chartData.isEmpty else { return nil }

            // Extend domain by 2 days on each side for easier point selection
            let dates = chartData.map { $0.date }
            guard let minDate = dates.min(), let maxDate = dates.max() else { return nil }

            guard let rangeStart = calendar.date(byAdding: .day, value: -2, to: minDate),
                  let rangeEnd = calendar.date(byAdding: .day, value: 2, to: maxDate) else {
                return nil
            }

            return rangeStart...rangeEnd

        case .year:
            guard !chartData.isEmpty else { return nil }

            // Extend domain by 3 days on each side for easier point selection
            let dates = chartData.map { $0.date }
            guard let minDate = dates.min(), let maxDate = dates.max() else { return nil }

            guard let rangeStart = calendar.date(byAdding: .day, value: -3, to: minDate),
                  let rangeEnd = calendar.date(byAdding: .day, value: 3, to: maxDate) else {
                return nil
            }

            return rangeStart...rangeEnd

        case .all:
            guard !chartData.isEmpty else { return nil }

            // Extend domain by 5 days on each side for easier point selection
            let dates = chartData.map { $0.date }
            guard let minDate = dates.min(), let maxDate = dates.max() else { return nil }

            guard let rangeStart = calendar.date(byAdding: .day, value: -5, to: minDate),
                  let rangeEnd = calendar.date(byAdding: .day, value: 5, to: maxDate) else {
                return nil
            }

            return rangeStart...rangeEnd

        default:
            return nil
        }
    }

    // MARK: - X-Axis Values for Day View

    /// Generates X-axis time marks every 3 hours starting from 6am (or earlier if data exists)
    var dayXAxisValues: [Date] {
        guard selectedTimeRange == .day, let domain = xAxisDomain else { return [] }

        let calendar = Calendar.current
        let startDate = domain.lowerBound
        let endDate = domain.upperBound

        var values: [Date] = []

        // Get the starting hour (e.g., 6 for 6am, or earlier if adjusted)
        let startHour = calendar.component(.hour, from: startDate)

        // Round down to nearest 3-hour mark if needed
        let adjustedStartHour = (startHour / 3) * 3

        // Get today's midnight as reference
        let today = calendar.startOfDay(for: Date())

        // Generate marks every 3 hours from adjusted start to midnight (24:00)
        var currentHour = adjustedStartHour
        while currentHour <= 24 {
            if let date = calendar.date(bySettingHour: currentHour % 24, minute: 0, second: 0, of: currentHour < 24 ? today : calendar.date(byAdding: .day, value: 1, to: today)!) {
                if date >= startDate && date <= endDate {
                    values.append(date)
                }
            }
            currentHour += 3
        }

        return values
    }

    // MARK: - X-Axis Values for Week View

    /// Generates X-axis marks for each of the last 7 days
    var weekXAxisValues: [Date] {
        guard selectedTimeRange == .week else { return [] }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Generate last 7 days (including today)
        var values: [Date] = []
        for daysAgo in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) {
                values.append(date)
            }
        }

        return values
    }

    /// Generates X-axis marks for Month view: Adaptive based on data range
    /// Shows 6-10 evenly-spaced dates depending on how much data exists
    var monthXAxisValues: [Date] {
        guard selectedTimeRange == .month else { return [] }
        guard !chartData.isEmpty else { return [] }

        let calendar = Calendar.current
        let dates = chartData.map { $0.date }
        guard let minDate = dates.min(), let maxDate = dates.max() else { return [] }

        // Calculate the number of days in the actual data range
        let daysBetween = calendar.dateComponents([.day], from: minDate, to: maxDate).day ?? 0

        // Determine number of marks based on data range
        // 1-7 days: show every day (or every other day)
        // 8-15 days: show ~6 marks
        // 16-30 days: show ~8 marks
        let numberOfMarks: Int
        if daysBetween <= 7 {
            numberOfMarks = max(daysBetween + 1, 4) // Show all days, minimum 4 marks
        } else if daysBetween <= 15 {
            numberOfMarks = 6
        } else {
            numberOfMarks = 8
        }

        // Generate evenly-spaced dates
        var values: [Date] = []
        let interval = Double(daysBetween) / Double(numberOfMarks - 1)

        for i in 0..<numberOfMarks {
            let daysToAdd = Int(round(Double(i) * interval))
            if let date = calendar.date(byAdding: .day, value: daysToAdd, to: calendar.startOfDay(for: minDate)) {
                values.append(date)
            }
        }

        return values
    }

    /// Generates X-axis marks for 3 Months view: 12 marks over last 90 days (4 per month)
    /// Creates marks at ~7-8 day intervals for balanced visual spacing
    var threeMonthsXAxisValues: [Date] {
        guard selectedTimeRange == .threeMonths else { return [] }
        guard !chartData.isEmpty else { return [] }

        let calendar = Calendar.current
        let dates = chartData.map { $0.date }
        guard let minDate = dates.min(), let maxDate = dates.max() else { return [] }

        // Calculate the number of days in the actual data range
        let daysBetween = calendar.dateComponents([.day], from: minDate, to: maxDate).day ?? 0

        // For 3 months view, always show 12 marks (4 per month) for consistency
        // This creates ~7-8 day intervals across 90 days
        let numberOfMarks = 12

        // Generate evenly-spaced dates
        var values: [Date] = []
        let interval = Double(daysBetween) / Double(numberOfMarks - 1)

        for i in 0..<numberOfMarks {
            let daysToAdd = Int(round(Double(i) * interval))
            if let date = calendar.date(byAdding: .day, value: daysToAdd, to: calendar.startOfDay(for: minDate)) {
                values.append(date)
            }
        }

        return values
    }

    /// Generates X-axis marks for Year view: 12 marks (one per month) over last 365 days
    /// Shows month abbreviations for clear temporal reference
    var yearXAxisValues: [Date] {
        guard selectedTimeRange == .year else { return [] }
        guard !chartData.isEmpty else { return [] }

        let calendar = Calendar.current
        let dates = chartData.map { $0.date }
        guard let minDate = dates.min(), let maxDate = dates.max() else { return [] }

        // Calculate number of months in data range
        let monthsBetween = calendar.dateComponents([.month], from: minDate, to: maxDate).month ?? 0

        // Always show 12 marks for Year view (one per month)
        let numberOfMarks = 12

        // Generate evenly-spaced dates across the data range
        var values: [Date] = []
        let interval = Double(monthsBetween) / Double(numberOfMarks - 1)

        for i in 0..<numberOfMarks {
            let monthsToAdd = Int(round(Double(i) * interval))
            if let date = calendar.date(byAdding: .month, value: monthsToAdd, to: calendar.startOfDay(for: minDate)) {
                values.append(date)
            }
        }

        return values
    }

    /// Generates X-axis marks for All view: Adaptive based on total data span
    /// Scales from months to years depending on data range
    var allXAxisValues: [Date] {
        guard selectedTimeRange == .all else { return [] }
        guard !chartData.isEmpty else { return [] }

        let calendar = Calendar.current
        let dates = chartData.map { $0.date }
        guard let minDate = dates.min(), let maxDate = dates.max() else { return [] }

        // Calculate the span in months
        let monthsBetween = calendar.dateComponents([.month], from: minDate, to: maxDate).month ?? 0

        // Determine appropriate number of marks and interval type
        let numberOfMarks: Int
        let intervalComponent: Calendar.Component

        if monthsBetween <= 12 {
            // Less than a year: show monthly marks (up to 12)
            numberOfMarks = min(monthsBetween + 1, 12)
            intervalComponent = .month
        } else if monthsBetween <= 36 {
            // 1-3 years: show ~12 marks at quarterly intervals
            numberOfMarks = 12
            intervalComponent = .month
        } else {
            // 3+ years: show ~12 marks at larger intervals
            numberOfMarks = 12
            intervalComponent = .month
        }

        // Generate evenly-spaced dates
        var values: [Date] = []
        let interval = Double(monthsBetween) / Double(numberOfMarks - 1)

        for i in 0..<numberOfMarks {
            let unitsToAdd = Int(round(Double(i) * interval))
            if let date = calendar.date(byAdding: intervalComponent, value: unitsToAdd, to: calendar.startOfDay(for: minDate)) {
                values.append(date)
            }
        }

        return values
    }

    /// For Week/Month/3Months/Year/All view: Returns actual time if day has single entry, nil if multiple entries
    /// This ensures we show accurate weigh-in times or omit time for averaged data
    var selectedEntryDisplayTime: Date? {
        guard let selectedEntry = selectedEntry else { return nil }

        // For Day view (without averaging), always show the actual time
        guard selectedTimeRange == .week || selectedTimeRange == .month || selectedTimeRange == .threeMonths || selectedTimeRange == .year || selectedTimeRange == .all else {
            return selectedEntry.date
        }

        // For Week/Month/3Months/Year/All view: Check how many entries exist for the selected day
        let calendar = Calendar.current
        let selectedDay = calendar.startOfDay(for: selectedEntry.date)

        let entriesForDay = filteredEntries.filter { entry in
            calendar.isDate(entry.date, inSameDayAs: selectedDay)
        }

        // If exactly one entry for this day, return its actual time
        // If multiple entries (averaged), return nil to hide time
        return entriesForDay.count == 1 ? entriesForDay.first?.date : nil
    }

    // MARK: - Y-Axis Values

    /// For Day view: Generates 5-6 evenly-spaced values for cleaner Y-axis
    private var dayYAxisValues: [Double] {
        let domain = yAxisDomain
        let min = domain.lowerBound
        let max = domain.upperBound

        // Create ~5 marks: every 2 lbs for 10lb range
        let step = 2.0
        return stride(from: min, through: max, by: step).map { $0 }
    }

    /// For Week view: Generates evenly-spaced values at 1lb intervals for 5lb range
    private var weekYAxisValues: [Double] {
        let domain = yAxisDomain
        let min = domain.lowerBound
        let max = domain.upperBound

        // Round boundaries to whole pounds to ensure axis marks align properly
        let minRounded = ceil(min)
        let maxRounded = floor(max)

        // Use 1lb steps for 5lb range (cleaner, easier to read)
        let step = 1.0
        return stride(from: minRounded, through: maxRounded, by: step).map { $0 }
    }

    /// For Month view: Generates 10 evenly-spaced Y-axis marks
    private var monthYAxisValues: [Double] {
        let domain = yAxisDomain
        let min = domain.lowerBound
        let max = domain.upperBound

        // Generate 10 evenly-spaced values (11 marks including min and max)
        let range = max - min
        let step = range / 10.0

        return stride(from: min, through: max, by: step).map { $0 }
    }

    /// For 3 Months view: Generates 10 evenly-spaced Y-axis marks
    private var threeMonthsYAxisValues: [Double] {
        let domain = yAxisDomain
        let min = domain.lowerBound
        let max = domain.upperBound

        // Generate 10 evenly-spaced values for clean visualization
        let range = max - min
        let step = range / 10.0

        return stride(from: min, through: max, by: step).map { $0 }
    }

    /// For Year view: Generates 10 evenly-spaced Y-axis marks
    private var yearYAxisValues: [Double] {
        let domain = yAxisDomain
        let min = domain.lowerBound
        let max = domain.upperBound

        // Generate 10 evenly-spaced values for year-long trends
        let range = max - min
        let step = range / 10.0

        return stride(from: min, through: max, by: step).map { $0 }
    }

    /// For All view: Generates 10 evenly-spaced Y-axis marks
    private var allYAxisValues: [Double] {
        let domain = yAxisDomain
        let min = domain.lowerBound
        let max = domain.upperBound

        // Generate 10 evenly-spaced values for all-time view
        let range = max - min
        let step = range / 10.0

        return stride(from: min, through: max, by: step).map { $0 }
    }

    // MARK: - Y-Axis Domain

    private var yAxisDomain: ClosedRange<Double> {
        guard !chartData.isEmpty else {
            return 0...200 // Default range
        }

        let weights = chartData.map { $0.weight }
        let minWeight = weights.min() ?? 0
        let maxWeight = weights.max() ?? 200

        switch selectedTimeRange {
        case .day:
            // For Day view: 10lb range (average ± 5 lbs) with 1lb increments
            // Calculate average weight for the day
            let avgWeight = weights.reduce(0.0, +) / Double(weights.count)

            // Create 10lb range: 5 lbs above and 5 lbs below average
            let rangeMin = round(avgWeight) - 5
            let rangeMax = round(avgWeight) + 5

            return rangeMin...rangeMax

        case .week:
            // For Week view: Default 5lb range (average ± 2.5 lbs), adaptive if needed
            // Calculate average weight for the week
            let avgWeight = weights.reduce(0.0, +) / Double(weights.count)

            // Default 5lb range: 2.5 lbs above and below average
            // Round to whole numbers to ensure goal line aligns with axis marks
            let centerWeight = round(avgWeight)
            let defaultRangeMin = centerWeight - 2.5
            let defaultRangeMax = centerWeight + 2.5

            // Check if actual data fits within default range
            let dataRange = maxWeight - minWeight

            if dataRange <= 5 {
                // Data fits within 5lb range, use default
                return defaultRangeMin...defaultRangeMax
            } else {
                // Data exceeds 5lb range, expand adaptively
                // Add 10% padding to actual data range
                let padding = dataRange * 0.1
                let rangeMin = floor(minWeight - padding)
                let rangeMax = ceil(maxWeight + padding)
                return rangeMin...rangeMax
            }

        case .month:
            // For Month view: Adaptive range based on weight fluctuation over 30 days
            // With dynamic adjustment when goal line is shown
            let dataRange = maxWeight - minWeight

            if showGoalLine {
                // Goal line is shown: Start Y-axis just below goal weight
                // Determine appropriate padding based on relationship between data and goal
                let highestValue = max(maxWeight, weightGoal)

                // Start 5-20 lbs below goal depending on data spread
                let belowGoalPadding: Double
                if dataRange < 5 {
                    belowGoalPadding = 5.0 // Small fluctuation: 5 lb padding
                } else if dataRange < 10 {
                    belowGoalPadding = 10.0 // Moderate fluctuation: 10 lb padding
                } else {
                    belowGoalPadding = 20.0 // Large fluctuation: 20 lb padding
                }

                let rangeMin = weightGoal - belowGoalPadding
                let rangeMax = max(highestValue + 2, rangeMin + 10) // Ensure at least 10lb range

                return rangeMin...rangeMax
            } else {
                // No goal line: Center on data with adaptive padding
                let padding = max(dataRange * 0.15, 3.0) // At least 3 lbs padding
                let rangeMin = floor(minWeight - padding)
                let rangeMax = ceil(maxWeight + padding)

                return rangeMin...rangeMax
            }

        case .threeMonths:
            // For 3 Months view: Similar to Month view but with slightly more range
            // Adaptive based on 90-day weight fluctuation with goal line support
            let dataRange = maxWeight - minWeight

            if showGoalLine {
                // Goal line is shown: Start Y-axis below goal weight
                let highestValue = max(maxWeight, weightGoal)

                // Adaptive padding based on data spread
                let belowGoalPadding: Double
                if dataRange < 5 {
                    belowGoalPadding = 8.0 // Small fluctuation: 8 lb padding
                } else if dataRange < 10 {
                    belowGoalPadding = 15.0 // Moderate fluctuation: 15 lb padding
                } else {
                    belowGoalPadding = 25.0 // Large fluctuation: 25 lb padding
                }

                let rangeMin = weightGoal - belowGoalPadding
                let rangeMax = max(highestValue + 3, rangeMin + 15) // Ensure at least 15lb range

                return rangeMin...rangeMax
            } else {
                // No goal line: Center on data with adaptive padding
                let padding = max(dataRange * 0.2, 5.0) // At least 5 lbs padding (20% for longer range)
                let rangeMin = floor(minWeight - padding)
                let rangeMax = ceil(maxWeight + padding)

                return rangeMin...rangeMax
            }

        case .year:
            // For Year view: Adaptive based on 365-day weight fluctuation
            // Shows broader trends with goal line support
            let dataRange = maxWeight - minWeight

            if showGoalLine {
                // Goal line shown: Position Y-axis below goal for year-long journey view
                let highestValue = max(maxWeight, weightGoal)

                // Adaptive padding for year-long data
                let belowGoalPadding: Double
                if dataRange < 10 {
                    belowGoalPadding = 15.0 // Small fluctuation over year: 15 lb padding
                } else if dataRange < 20 {
                    belowGoalPadding = 25.0 // Moderate fluctuation: 25 lb padding
                } else {
                    belowGoalPadding = 35.0 // Large fluctuation: 35 lb padding
                }

                let rangeMin = weightGoal - belowGoalPadding
                let rangeMax = max(highestValue + 5, rangeMin + 20) // Ensure at least 20lb range

                return rangeMin...rangeMax
            } else {
                // No goal line: Center on data with generous padding for year view
                let padding = max(dataRange * 0.25, 8.0) // At least 8 lbs padding (25% for year)
                let rangeMin = floor(minWeight - padding)
                let rangeMax = ceil(maxWeight + padding)

                return rangeMin...rangeMax
            }

        case .all:
            // For All view: Maximally adaptive based on entire dataset
            // Scales from months to years of data
            let dataRange = maxWeight - minWeight

            if showGoalLine {
                // Goal line shown: Adaptive positioning for all-time view
                let highestValue = max(maxWeight, weightGoal)

                // Very adaptive padding for potentially multi-year data
                let belowGoalPadding: Double
                if dataRange < 15 {
                    belowGoalPadding = 20.0 // Smaller all-time range: 20 lb padding
                } else if dataRange < 30 {
                    belowGoalPadding = 30.0 // Medium range: 30 lb padding
                } else {
                    belowGoalPadding = 40.0 // Large range: 40 lb padding
                }

                let rangeMin = weightGoal - belowGoalPadding
                let rangeMax = max(highestValue + 5, rangeMin + 25) // Ensure at least 25lb range

                return rangeMin...rangeMax
            } else {
                // No goal line: Maximum adaptive padding for all-time trends
                let padding = max(dataRange * 0.3, 10.0) // At least 10 lbs padding (30% for all-time)
                let rangeMin = floor(minWeight - padding)
                let rangeMax = ceil(maxWeight + padding)

                return rangeMin...rangeMax
            }
        }
    }
}

// MARK: - Weight Statistics View

struct WeightStatsView: View {
    @ObservedObject var weightManager: WeightManager

    var body: some View {
        VStack(spacing: 12) {
            Text("Statistics")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                WeightChangeStatCard(
                    title: "7-Day Change",
                    weightChange: weightManager.weightChange(since: Calendar.current.date(byAdding: .day, value: -7, to: Date())!)
                )

                WeightChangeStatCard(
                    title: "30-Day Change",
                    weightChange: weightManager.weightChange(since: Calendar.current.date(byAdding: .day, value: -30, to: Date())!)
                )

                StatCard(
                    title: "Average Weight",
                    value: weightManager.averageWeight
                        .map { String(format: "%.1f lbs", $0) } ?? "N/A",
                    icon: "chart.bar",
                    color: .orange
                )

                StatCard(
                    title: "Total Entries",
                    value: "\(weightManager.weightEntries.count)",
                    icon: "number",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct WeightChangeStatCard: View {
    let title: String
    let weightChange: Double?

    var body: some View {
        VStack(spacing: 8) {
            if let change = weightChange {
                // Arrow icon based on gain/loss
                Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.title2)
                    .foregroundColor(change >= 0 ? .red : .green)

                // Weight change value with arrow
                HStack(spacing: 4) {
                    Text(String(format: "%.1f lbs", abs(change)))
                        .font(.title3)
                        .fontWeight(.bold)
                    Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .foregroundColor(change >= 0 ? .red : .green)
            } else {
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundColor(.gray)

                Text("N/A")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
            }

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

// MARK: - Weight History List View

struct WeightHistoryListView: View {
    @ObservedObject var weightManager: WeightManager

    var body: some View {
        VStack(spacing: 12) {
            Text("Weight History")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(Array(weightManager.weightEntries.prefix(10))) { entry in
                WeightHistoryRow(entry: entry, weightManager: weightManager)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            weightManager.deleteWeightEntry(entry)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                Divider()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct WeightHistoryRow: View {
    let entry: WeightEntry
    let weightManager: WeightManager
    @State private var showingDeleteAlert = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(entry.date, style: .date)
                        .font(.headline)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(entry.date, style: .time)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 8) {
                    Text(entry.source.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let bmi = entry.bmi {
                        Text("BMI: \(bmi, specifier: "%.1f")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let bodyFat = entry.bodyFat {
                        Text("BF: \(bodyFat, specifier: "%.1f")%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Text("\(entry.weight, specifier: "%.1f") lbs")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.86))
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive, action: { showingDeleteAlert = true }) {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete Weight Entry", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                weightManager.deleteWeightEntry(entry)
            }
        } message: {
            Text("Are you sure you want to delete this weight entry?")
        }
    }
}

// MARK: - View Modifier for Conditional X-Axis Scale

struct XAxisScaleModifier: ViewModifier {
    let domain: ClosedRange<Date>?

    func body(content: Content) -> some View {
        if let domain = domain {
            content.chartXScale(domain: domain)
        } else {
            content
        }
    }
}

// MARK: - First Time Weight Setup View

struct FirstTimeWeightSetupView: View {
    @ObservedObject var weightManager: WeightManager
    @Binding var weightGoal: Double
    @Binding var showGoalLine: Bool
    @Environment(\.dismiss) var dismiss

    @State private var currentWeightString: String = ""
    @State private var goalWeightString: String = ""
    @State private var showError: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "scalemass.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.86))

                        Text("Welcome to Weight Tracking")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text("Let's get started by setting up your weight goals")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)

                    // Current Weight Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Weight")
                            .font(.headline)
                            .foregroundColor(.primary)

                        HStack {
                            TextField("Enter weight", text: $currentWeightString)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)

                            Text("lbs")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)

                    // Goal Weight Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Goal Weight")
                            .font(.headline)
                            .foregroundColor(.primary)

                        HStack {
                            TextField("Enter goal", text: $goalWeightString)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)

                            Text("lbs")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)

                    // Error message
                    if showError {
                        Text("Please enter valid weights")
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    // Get Started Button
                    Button(action: saveAndContinue) {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.2, green: 0.6, blue: 0.86))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled() // Prevent dismissal without entering data
        }
    }

    private func saveAndContinue() {
        // Validate inputs
        guard let currentWeight = Double(currentWeightString),
              let goalWeight = Double(goalWeightString),
              currentWeight > 0,
              goalWeight > 0 else {
            showError = true
            return
        }

        // Save current weight entry
        let entry = WeightEntry(
            id: UUID(),
            date: Date(),
            weight: currentWeight,
            bmi: nil,
            bodyFat: nil,
            source: .manual
        )
        weightManager.addWeightEntry(entry)

        // Save goal weight
        weightGoal = goalWeight

        // Enable goal line by default
        showGoalLine = true

        // Dismiss the sheet
        dismiss()
    }
}

// MARK: - Quick Goal Editor View

/// Simplified goal editor for quick access from Current Weight card
/// Per Apple HIG: "Provide shortcuts to frequently performed tasks"
/// Reference: https://developer.apple.com/design/human-interface-guidelines/user-interaction
struct QuickGoalEditorView: View {
    @Binding var weightGoal: Double
    @Environment(\.dismiss) var dismiss

    @State private var goalText: String = ""
    @State private var showError: Bool = false
    @FocusState private var isTextFieldFocused: Bool  // Auto-focus for keyboard
    @State private var hasAppeared: Bool = false  // Prevent re-triggering focus

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "target")
                        .font(.system(size: 60))
                        .foregroundColor(.green)

                    Text("Set Your Goal Weight")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Choose your target weight")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)

                // Goal Weight Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Goal Weight")
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack {
                        TextField("Enter goal", text: $goalText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .focused($isTextFieldFocused)  // Bind focus state

                        Text("lbs")
                            .font(.title)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                // Error message
                if showError {
                    Text("Please enter a valid weight")
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveGoal()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                // Pre-fill with current goal
                goalText = String(Int(weightGoal))
            }
            .task {
                // Only run focus logic ONCE per sheet presentation
                // Prevents notification loop from repeated focus changes
                // Reference: https://developer.apple.com/documentation/swiftui/view/task(priority:_:)
                guard !hasAppeared else { return }
                hasAppeared = true

                // Delay keyboard to let sheet animation complete first
                // 0.4s = sheet animation (0.3s) + small buffer (0.1s)
                try? await Task.sleep(nanoseconds: 400_000_000)
                isTextFieldFocused = true
            }
        }
    }

    private func saveGoal() {
        // Validate input
        guard let newGoal = Double(goalText), newGoal > 0 else {
            showError = true
            return
        }

        // Save to binding (automatically saves to UserDefaults via parent view)
        weightGoal = newGoal

        // Dismiss sheet
        dismiss()
    }
}

// MARK: - Circular Progress Ring (Milestone Style)

/// Beautiful circular progress indicator inspired by milestone design
/// Blue→Green gradient shows progression visually
/// Per Apple HIG: "Use visual metaphors to make abstract concepts tangible"
/// Reference: https://developer.apple.com/design/human-interface-guidelines/charts
struct CircularProgressRing: View {
    let percentage: Double
    let weightLost: Double
    let weightToGo: Double?
    let startWeight: Double?
    let goalWeight: Double

    var body: some View {
        VStack(spacing: 16) {
            // Title
            Text("Your Progress Journey")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            // Circular Progress Ring (WIDER!)
            ZStack {
                // Background circle (gray)
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 14)
                    .frame(width: 200, height: 200)

                // Progress arc (BLUE → GREEN gradient - shows progression!)
                Circle()
                    .trim(from: 0, to: CGFloat(percentage / 100))
                    .stroke(
                        AngularGradient(
                            colors: [Color.blue, Color.cyan, Color.green],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360 * (percentage / 100))
                        ),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: percentage)

                // Center content
                VStack(spacing: 4) {
                    // Milestone emoji (dynamic based on percentage)
                    Text(milestoneEmoji(for: percentage))
                        .font(.system(size: 36))

                    // Large percentage
                    Text("\(percentage, specifier: "%.0f")%")
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundColor(progressColor(for: percentage))

                    // "COMPLETE" label
                    Text("COMPLETE")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                        .tracking(1)
                }
            }

            // Stats below ring
            HStack(spacing: 24) {
                // Weight Lost (left)
                VStack(spacing: 2) {
                    Text("\(weightLost, specifier: "%.1f") lbs")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                    Text("LOST")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                        .tracking(0.5)
                }

                // Divider
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 35)

                // Weight To Go (right)
                if let toGo = weightToGo, toGo > 0 {
                    VStack(spacing: 2) {
                        Text("\(toGo, specifier: "%.1f") lbs")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                        Text("TO GO")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                            .tracking(0.5)
                    }
                }
            }

            // 10 Milestone Dots (like Image 2!)
            VStack(spacing: 8) {
                // Dots row
                HStack(spacing: 12) {
                    ForEach(1...10, id: \.self) { milestone in
                        Circle()
                            .fill(milestoneColor(for: milestone, percentage: percentage))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }

                // Progress text
                Text("\(milestonesCompleted(for: percentage)) OF 10 MILESTONES COMPLETE")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .tracking(0.5)
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
    }

    /// Returns motivational emoji based on progress percentage
    private func milestoneEmoji(for percentage: Double) -> String {
        switch percentage {
        case 0..<10:    return "🌱"
        case 10..<25:   return "💪"
        case 25..<50:   return "⭐️"
        case 50..<75:   return "🔥"
        case 75..<90:   return "🏆"
        case 90..<100:  return "🚀"
        default:        return "👑"
        }
    }

    /// Returns color for percentage text based on progress
    private func progressColor(for percentage: Double) -> Color {
        switch percentage {
        case 0..<33:    return .blue
        case 33..<66:   return .cyan
        default:        return .green
        }
    }

    /// Returns how many milestones are completed (0-10)
    private func milestonesCompleted(for percentage: Double) -> Int {
        return Int((percentage / 100) * 10)
    }

    /// Returns color for each milestone dot matching the ring's gradient
    /// Creates smooth blue → cyan → green progression like the circular ring
    private func milestoneColor(for milestone: Int, percentage: Double) -> Color {
        let completed = milestonesCompleted(for: percentage)

        if milestone <= completed {
            // Filled dots: smooth gradient matching ring (blue → cyan → green)
            // Distribute colors evenly across 10 milestones
            switch milestone {
            case 1...3:
                return .blue
            case 4...6:
                return .cyan
            case 7...10:
                return .green
            default:
                return .blue
            }
        } else {
            // Empty dots: light gray
            return Color.gray.opacity(0.2)
        }
    }
}

// MARK: - Weight Trends View

/// Shows weight change trends over different time periods
/// Per Apple HIG: "Help people see patterns in data by presenting information clearly"
/// Reference: https://developer.apple.com/design/human-interface-guidelines/charts
struct WeightTrendsView: View {
    @ObservedObject var weightManager: WeightManager
    @Environment(\.dismiss) private var dismiss

    /// Calculate weight change over a specific number of days
    /// Returns (amount: Double, isLoss: Bool) or nil if insufficient data
    private func calculateTrend(days: Int?) -> (amount: Double, isLoss: Bool)? {
        guard weightManager.weightEntries.count >= 2 else { return nil }

        let sortedEntries = weightManager.weightEntries.sorted { $0.date < $1.date }

        if let days = days {
            // Calculate trend for specific period
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            let recentEntries = sortedEntries.filter { $0.date >= cutoffDate }

            guard recentEntries.count >= 2,
                  let firstWeight = recentEntries.first?.weight,
                  let lastWeight = recentEntries.last?.weight else {
                return nil
            }

            let change = firstWeight - lastWeight
            return (amount: abs(change), isLoss: change > 0)
        } else {
            // All-time trend (first to latest)
            guard let firstWeight = sortedEntries.first?.weight,
                  let lastWeight = sortedEntries.last?.weight else {
                return nil
            }

            let change = firstWeight - lastWeight
            return (amount: abs(change), isLoss: change > 0)
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Motivational header with emoji
                    // Per Apple HIG: Use large titles for top-level information
                    VStack(spacing: 8) {
                        Text("📈 Your Progress Story")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text("See how far you've come!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)

                    // Trends Grid - Centered for visual balance
                    // Per Apple HIG: Use alignment to improve scannability
                    VStack(spacing: 16) {
                        // Row 1: 7 days and 30 days
                        HStack(spacing: 16) {
                            TrendCard(title: "7 DAYS", trend: calculateTrend(days: 7))
                            TrendCard(title: "30 DAYS", trend: calculateTrend(days: 30))
                        }

                        // Row 2: 90 days and All Time
                        HStack(spacing: 16) {
                            TrendCard(title: "90 DAYS", trend: calculateTrend(days: 90))
                            TrendCard(title: "ALL TIME", trend: calculateTrend(days: nil))
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            .navigationTitle("Weight Trends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Trend Card Component

/// Individual card showing weight trend for a time period
/// EXCITING, MOTIVATIONAL design with gradients and emojis!
/// Per Apple HIG: "Use visual design to communicate the feeling you want people to experience"
/// Reference: https://developer.apple.com/design/human-interface-guidelines/visual-design
struct TrendCard: View {
    let title: String
    let trend: (amount: Double, isLoss: Bool)?

    var body: some View {
        VStack(spacing: 8) {
            if let trend = trend {
                // Top: Celebration emoji (EXCITING!)
                Text(trendEmoji(for: trend))
                    .font(.system(size: 40))
                    .padding(.top, 8)

                // Middle: HUGE number + lbs (IMPACTFUL!)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(String(format: "%.1f", trend.amount))
                        .font(.system(size: 60, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text("lbs")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }

                // Status pill (like weight lost pill!)
                Text(trend.isLoss ? "LOST" : "GAINED")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.3))
                    )

                // Period label (clear but subtle)
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.bottom, 4)
            } else {
                // No data state
                Text("📊")
                    .font(.system(size: 40))
                    .padding(.top, 8)

                Text("--")
                    .font(.system(size: 60, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))

                Text("NO DATA")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                    )

                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardGradient)
        )
        .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
    }

    /// Vibrant gradient background - EXCITING!
    /// Different gradient per time period for visual distinction
    private var cardGradient: LinearGradient {
        guard let trend = trend else {
            // No data: Gray gradient
            return LinearGradient(
                colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        if trend.isLoss {
            // Loss: Use time-period specific gradients for visual distinction
            switch title {
            case "7 DAYS":
                // Recent: Blue gradient
                return LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case "30 DAYS":
                // Medium: Cyan gradient
                return LinearGradient(
                    colors: [Color.cyan, Color.cyan.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case "90 DAYS":
                // Long-term: Green gradient
                return LinearGradient(
                    colors: [Color.green, Color.green.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case "ALL TIME":
                // Lifetime: Gold/yellow gradient (achievement!)
                return LinearGradient(
                    colors: [Color.orange, Color.yellow.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            default:
                // Fallback: Green
                return LinearGradient(
                    colors: [Color.green, Color.green.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        } else {
            // Gain: Red gradient (but gentle)
            return LinearGradient(
                colors: [Color.red.opacity(0.8), Color.red.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    /// Shadow color matches card gradient
    private var shadowColor: Color {
        guard let trend = trend else {
            return Color.gray.opacity(0.3)
        }

        if trend.isLoss {
            switch title {
            case "7 DAYS":
                return Color.blue.opacity(0.3)
            case "30 DAYS":
                return Color.cyan.opacity(0.3)
            case "90 DAYS":
                return Color.green.opacity(0.3)
            case "ALL TIME":
                return Color.orange.opacity(0.3)
            default:
                return Color.green.opacity(0.3)
            }
        } else {
            return Color.red.opacity(0.3)
        }
    }

    /// Dynamic emoji based on trend - CELEBRATION!
    private func trendEmoji(for trend: (amount: Double, isLoss: Bool)) -> String {
        if trend.isLoss {
            // Celebration emojis for weight loss!
            switch trend.amount {
            case 0..<1:
                return "👍"  // Small progress
            case 1..<2:
                return "💪"  // Good progress
            case 2..<3:
                return "⭐️"  // Great progress
            case 3..<5:
                return "🔥"  // Excellent progress
            case 5..<10:
                return "🏆"  // Amazing progress
            default:
                return "🚀"  // Incredible progress!
            }
        } else {
            // Gentle supportive emojis for weight gain
            switch trend.amount {
            case 0..<1:
                return "💧"  // Just water weight
            case 1..<2:
                return "🤝"  // Small fluctuation
            case 2..<5:
                return "💙"  // Keep going
            default:
                return "🫂"  // Still on the journey
            }
        }
    }
}

#Preview {
    WeightTrackingView()
}
