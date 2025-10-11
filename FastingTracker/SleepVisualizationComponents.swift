import Charts
import SwiftUI

// MARK: - Sleep Bar Chart (Apple Health Style)

// Stacked bar chart showing sleep duration with brainwave-based colors
// Following neuroscience standards for sleep stage visualization

struct SleepBarChart: View {
    let sleepEntries: [SleepEntry]
    let timeRange: SleepTimeRange

    // Brainwave-based color scheme (scientifically accurate)
    private let stageColors: [SleepStageType: Color] = [
        .deep: Color.purple, // Delta waves (0.5-4 Hz) - deep purple
        .rem: Color.cyan, // Beta/Gamma waves - bright cyan (active brain)
        .core: Color.blue, // Alpha waves (8-12 Hz) - blue (relaxed)
        .awake: Color.orange, // Beta waves (13-30 Hz) - orange (alert)
    ]

    var body: some View {
        VStack(spacing: 16) {
            // Chart Header with Time Range Selector
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sleep Duration")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(self.timeRange.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Stacked Bar Chart
            Chart(self.filteredEntries, id: \.id) { entry in
                ForEach(entry.stageBreakdown, id: \.type) { stage in
                    BarMark(
                        x: .value("Date", entry.wakeTime),
                        y: .value("Duration", stage.duration / 3600), // Convert to hours
                        stacking: .standard
                    )
                    .foregroundStyle(self.stageColors[stage.type] ?? .gray)
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: max(1, (self.timeRange.days ?? 30) / 7))) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    AxisGridLine()
                    AxisTick()
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let hours = value.as(Double.self) {
                            Text("\(Int(hours))h")
                        }
                    }
                    AxisGridLine()
                }
            }

            // Legend with brainwave science explanation
            HStack(spacing: 16) {
                ForEach([SleepStageType.deep, .rem, .core, .awake], id: \.self) { stage in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(self.stageColors[stage] ?? .gray)
                            .frame(width: 8, height: 8)
                        Text(stage.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }

    // Filter entries based on selected time range
    private var filteredEntries: [SleepEntry] {
        guard let days = timeRange.days else { return self.sleepEntries }
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return self.sleepEntries.filter { $0.wakeTime >= cutoffDate }.prefix(days).map { $0 }
    }
}

// MARK: - Sleep Stage Breakdown Extension

// Helper extension for stacked bar chart data processing

extension SleepEntry {
    var stageBreakdown: [StageBreakdown] {
        // If no detailed stages, create basic breakdown from duration
        if stages.isEmpty {
            return [
                StageBreakdown(type: .core, duration: duration * 0.85), // Assume most is core sleep
                StageBreakdown(type: .awake, duration: duration * 0.15), // Small awake portion
            ]
        }

        // Group stages by type and sum durations
        var breakdown: [SleepStageType: TimeInterval] = [:]
        for stage in stages {
            let duration = stage.endTime.timeIntervalSince(stage.startTime)
            breakdown[stage.type, default: 0] += duration
        }

        return breakdown.map { StageBreakdown(type: $0.key, duration: $0.value) }
            .filter { $0.duration > 0 }
            .sorted { $0.type.sortOrder < $1.type.sortOrder }
    }
}

struct StageBreakdown {
    let type: SleepStageType
    let duration: TimeInterval
}

extension SleepStageType {
    var displayName: String {
        switch self {
        case .deep: return "Deep"
        case .rem: return "REM"
        case .core: return "Core"
        case .awake: return "Awake"
        case .inBed: return "In Bed"
        }
    }

    var sortOrder: Int {
        switch self {
        case .deep: return 0
        case .rem: return 1
        case .core: return 2
        case .awake: return 3
        case .inBed: return 4
        }
    }
}

// MARK: - Sleep Optimization Visualization Components

// User-friendly sleep charts designed for actionable insights and optimization
// Following Fast LIFe design patterns with clear, intuitive visualizations

// MARK: - Sleep Stage Breakdown Chart

// Pie chart showing sleep stage distribution - much clearer than Apple's timeline

struct SleepStageBreakdownChart: View {
    let sleepEntry: SleepEntry

    // Sleep optimization benchmarks (based on sleep research)
    private let optimalRanges = [
        "Deep": 0.15 ... 0.25, // 15-25% deep sleep is optimal
        "REM": 0.20 ... 0.25, // 20-25% REM sleep is optimal
        "Core": 0.45 ... 0.65, // 45-65% core sleep is normal
        "Awake": 0.00 ... 0.05, // <5% awake time is good
    ]

    var body: some View {
        VStack(spacing: 16) {
            // Chart Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sleep Quality")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(self.sleepEntry.formattedDuration)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                }
                Spacer()

                // Overall sleep score
                SleepQualityScore(sleepEntry: self.sleepEntry)
            }

            HStack(spacing: 20) {
                // Pie Chart
                Chart(self.stageData, id: \.stage) { data in
                    SectorMark(
                        angle: .value("Duration", data.percentage),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .foregroundStyle(data.color)
                }
                .frame(width: 120, height: 120)

                // Stage Breakdown with Optimization Status
                VStack(spacing: 8) {
                    ForEach(self.stageData, id: \.stage) { data in
                        SleepStageRow(
                            stage: data.stage,
                            duration: data.duration,
                            percentage: data.percentage,
                            isOptimal: data.isOptimal,
                            color: data.color
                        )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }

    // Computed sleep stage data with optimization status
    private var stageData: [StageData] {
        let stages = self.sleepEntry.stageDurations
        let totalDuration = self.sleepEntry.duration

        return [
            StageData(
                stage: "Deep",
                duration: stages.deep,
                percentage: stages.deep / totalDuration,
                color: .blue,
                isOptimal: self.optimalRanges["Deep"]!.contains(stages.deep / totalDuration)
            ),
            StageData(
                stage: "REM",
                duration: stages.rem,
                percentage: stages.rem / totalDuration,
                color: .cyan,
                isOptimal: self.optimalRanges["REM"]!.contains(stages.rem / totalDuration)
            ),
            StageData(
                stage: "Core",
                duration: stages.core,
                percentage: stages.core / totalDuration,
                color: .indigo,
                isOptimal: self.optimalRanges["Core"]!.contains(stages.core / totalDuration)
            ),
            StageData(
                stage: "Awake",
                duration: stages.awake,
                percentage: stages.awake / totalDuration,
                color: .orange,
                isOptimal: self.optimalRanges["Awake"]!.contains(stages.awake / totalDuration)
            ),
        ].filter { $0.duration > 0 } // Only show stages that occurred
    }
}

// MARK: - Supporting Components

struct StageData {
    let stage: String
    let duration: TimeInterval
    let percentage: Double
    let color: Color
    let isOptimal: Bool
}

struct SleepStageRow: View {
    let stage: String
    let duration: TimeInterval
    let percentage: Double
    let isOptimal: Bool
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            // Stage color indicator
            Circle()
                .fill(self.color)
                .frame(width: 8, height: 8)

            // Stage name
            Text(self.stage)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 35, alignment: .leading)

            // Duration
            Text(self.formattedDuration)
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 45, alignment: .leading)

            // Percentage
            Text("\(Int(self.percentage * 100))%")
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 30, alignment: .leading)

            // Optimization indicator
            Image(systemName: self.isOptimal ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.caption)
                .foregroundColor(self.isOptimal ? .green : .yellow)
        }
    }

    private var formattedDuration: String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct SleepQualityScore: View {
    let sleepEntry: SleepEntry

    var body: some View {
        VStack(spacing: 4) {
            Text("\(self.qualityScore)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(self.scoreColor)

            Text("Score")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(
            Circle()
                .fill(self.scoreColor.opacity(0.1))
        )
    }

    // Calculate sleep quality score (0-100) based on stage optimization
    private var qualityScore: Int {
        let stages = self.sleepEntry.stageDurations
        let totalDuration = self.sleepEntry.duration

        guard totalDuration > 0 else { return 0 }

        var score = 0

        // Deep sleep score (25 points max)
        let deepPercentage = stages.deep / totalDuration
        if deepPercentage >= 0.20 {
            score += 25
        } else if deepPercentage >= 0.15 {
            score += 20
        } else if deepPercentage >= 0.10 {
            score += 15
        } else {
            score += 10
        }

        // REM sleep score (25 points max)
        let remPercentage = stages.rem / totalDuration
        if remPercentage >= 0.20 {
            score += 25
        } else if remPercentage >= 0.15 {
            score += 20
        } else if remPercentage >= 0.10 {
            score += 15
        } else {
            score += 10
        }

        // Sleep efficiency score (25 points max) - less awake time is better
        let awakePercentage = stages.awake / totalDuration
        if awakePercentage <= 0.05 {
            score += 25
        } else if awakePercentage <= 0.10 {
            score += 20
        } else if awakePercentage <= 0.15 {
            score += 15
        } else {
            score += 10
        }

        // Duration score (25 points max) - 7-9 hours is optimal
        let hours = totalDuration / 3600
        if hours >= 7, hours <= 9 {
            score += 25
        } else if hours >= 6, hours <= 10 {
            score += 20
        } else if hours >= 5, hours <= 11 {
            score += 15
        } else {
            score += 10
        }

        return min(score, 100)
    }

    private var scoreColor: Color {
        switch self.qualityScore {
        case 80 ... 100: return .green
        case 60 ... 79: return .yellow
        default: return .red
        }
    }
}

// MARK: - Sleep Trend Chart

// Line chart showing sleep quality trends over time for optimization insights

struct SleepTrendChart: View {
    let sleepEntries: [SleepEntry]
    let timeRange: TimeRange

    enum TimeRange: String, CaseIterable {
        case week = "7D"
        case month = "1M"
        case threeMonths = "3M"

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            }
        }

        var title: String {
            switch self {
            case .week: return "Week"
            case .month: return "Month"
            case .threeMonths: return "3 Months"
            }
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Chart Header
            HStack {
                Text("Sleep Quality Trends")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Text(self.timeRange.title)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.1))
                    .foregroundColor(.purple)
                    .clipShape(Capsule())
            }

            // Trend Chart
            Chart(self.chartData, id: \.date) { data in
                LineMark(
                    x: .value("Date", data.date),
                    y: .value("Quality Score", data.qualityScore)
                )
                .foregroundStyle(.purple)
                .lineStyle(StrokeStyle(lineWidth: 2))

                AreaMark(
                    x: .value("Date", data.date),
                    y: .value("Quality Score", data.qualityScore)
                )
                .foregroundStyle(.purple.opacity(0.1))
            }
            .frame(height: 120)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: self.timeRange.days / 7)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    AxisGridLine()
                    AxisTick()
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let score = value.as(Int.self) {
                            Text("\(score)")
                        }
                    }
                    AxisGridLine()
                }
            }
            .chartYScale(domain: 0 ... 100)

            // Trend Summary
            SleepTrendSummary(chartData: self.chartData)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }

    // FIXED: Computed chart data with corrected Calendar API usage
    private var chartData: [TrendDataPoint] {
        let filteredEntries = self.sleepEntries.filter { entry in
            let daysAgo = abs(entry.wakeTime.timeIntervalSince(Date()))
            return daysAgo <= TimeInterval(self.timeRange.days * 24 * 3600)
        }

        return filteredEntries.map { entry in
            TrendDataPoint(
                date: entry.wakeTime,
                qualityScore: self.calculateQualityScore(for: entry)
            )
        }.sorted { $0.date < $1.date }
    }

    private func calculateQualityScore(for entry: SleepEntry) -> Int {
        // Same scoring algorithm as SleepQualityScore
        let stages = entry.stageDurations
        let totalDuration = entry.duration

        guard totalDuration > 0 else { return 0 }

        var score = 0

        // Deep sleep (25 points)
        let deepPercentage = stages.deep / totalDuration
        if deepPercentage >= 0.20 { score += 25 }
        else if deepPercentage >= 0.15 { score += 20 }
        else if deepPercentage >= 0.10 { score += 15 }
        else { score += 10 }

        // REM sleep (25 points)
        let remPercentage = stages.rem / totalDuration
        if remPercentage >= 0.20 { score += 25 }
        else if remPercentage >= 0.15 { score += 20 }
        else if remPercentage >= 0.10 { score += 15 }
        else { score += 10 }

        // Sleep efficiency (25 points)
        let awakePercentage = stages.awake / totalDuration
        if awakePercentage <= 0.05 { score += 25 }
        else if awakePercentage <= 0.10 { score += 20 }
        else if awakePercentage <= 0.15 { score += 15 }
        else { score += 10 }

        // Duration (25 points)
        let hours = totalDuration / 3600
        if hours >= 7, hours <= 9 { score += 25 }
        else if hours >= 6, hours <= 10 { score += 20 }
        else if hours >= 5, hours <= 11 { score += 15 }
        else { score += 10 }

        return min(score, 100)
    }
}

struct TrendDataPoint {
    let date: Date
    let qualityScore: Int
}

struct SleepTrendSummary: View {
    let chartData: [TrendDataPoint]

    var body: some View {
        HStack(spacing: 20) {
            // Average score
            VStack(spacing: 2) {
                Text("\(self.averageScore)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text("Avg Score")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Trend direction
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: self.trendDirection.icon)
                        .font(.caption)
                        .foregroundColor(self.trendDirection.color)
                    Text("\(abs(self.trendChange))")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(self.trendDirection.color)
                }
                Text("Trend")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Best night
            VStack(spacing: 2) {
                Text("\(self.bestScore)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                Text("Best")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var averageScore: Int {
        guard !self.chartData.isEmpty else { return 0 }
        return self.chartData.map(\.qualityScore).reduce(0, +) / self.chartData.count
    }

    private var bestScore: Int {
        self.chartData.map(\.qualityScore).max() ?? 0
    }

    private var trendChange: Int {
        guard self.chartData.count >= 2 else { return 0 }
        let firstHalf = self.chartData.prefix(self.chartData.count / 2).map(\.qualityScore)
        let secondHalf = self.chartData.suffix(self.chartData.count / 2).map(\.qualityScore)

        let firstAvg = firstHalf.reduce(0, +) / firstHalf.count
        let secondAvg = secondHalf.reduce(0, +) / secondHalf.count

        return secondAvg - firstAvg
    }

    private var trendDirection: (icon: String, color: Color) {
        if self.trendChange > 0 {
            return ("arrow.up.right", .green)
        } else if self.trendChange < 0 {
            return ("arrow.down.right", .red)
        } else {
            return ("arrow.right", .gray)
        }
    }
}

// MARK: - Sleep Consistency Metrics

// Critical for sleep optimization - consistent schedules improve sleep quality significantly

struct SleepConsistencyChart: View {
    let sleepEntries: [SleepEntry]

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sleep Consistency")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Schedule optimization")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Overall consistency score
                ConsistencyScore(score: self.overallConsistencyScore)
            }

            HStack(spacing: 16) {
                // Bedtime consistency
                ConsistencyMetric(
                    title: "Bedtime",
                    variance: self.bedtimeVariance,
                    averageTime: self.averageBedtime,
                    isGood: self.bedtimeVariance < 3600 // < 1 hour variance is good
                )

                Divider()
                    .frame(height: 40)

                // Wake time consistency
                ConsistencyMetric(
                    title: "Wake Time",
                    variance: self.waketimeVariance,
                    averageTime: self.averageWaketime,
                    isGood: self.waketimeVariance < 3600 // < 1 hour variance is good
                )
            }

            // Optimization tips
            SleepOptimizationTips(
                bedtimeVariance: self.bedtimeVariance,
                waketimeVariance: self.waketimeVariance
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }

    // MARK: - Computed Properties

    private var recentEntries: [SleepEntry] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return self.sleepEntries.filter { $0.wakeTime >= sevenDaysAgo }.prefix(7).map { $0 }
    }

    private var bedtimeVariance: TimeInterval {
        guard self.recentEntries.count >= 2 else { return 0 }

        let bedtimes = self.recentEntries.map(\.bedTime)
        let avgBedtime = bedtimes.reduce(Date(timeIntervalSince1970: 0)) { result, date in
            Date(timeIntervalSince1970: result.timeIntervalSince1970 + date
                .timeIntervalSince1970 / Double(bedtimes.count))
        }

        let variances = bedtimes.map { abs($0.timeIntervalSince(avgBedtime)) }
        return variances.reduce(0, +) / Double(variances.count)
    }

    private var waketimeVariance: TimeInterval {
        guard self.recentEntries.count >= 2 else { return 0 }

        let waketimes = self.recentEntries.map(\.wakeTime)
        let avgWaketime = waketimes.reduce(Date(timeIntervalSince1970: 0)) { result, date in
            Date(timeIntervalSince1970: result.timeIntervalSince1970 + date
                .timeIntervalSince1970 / Double(waketimes.count))
        }

        let variances = waketimes.map { abs($0.timeIntervalSince(avgWaketime)) }
        return variances.reduce(0, +) / Double(variances.count)
    }

    private var averageBedtime: Date {
        guard !self.recentEntries.isEmpty else { return Date() }
        let totalInterval = self.recentEntries.map(\.bedTime).reduce(0) { $0 + $1.timeIntervalSince1970 }
        return Date(timeIntervalSince1970: totalInterval / Double(self.recentEntries.count))
    }

    private var averageWaketime: Date {
        guard !self.recentEntries.isEmpty else { return Date() }
        let totalInterval = self.recentEntries.map(\.wakeTime).reduce(0) { $0 + $1.timeIntervalSince1970 }
        return Date(timeIntervalSince1970: totalInterval / Double(self.recentEntries.count))
    }

    private var overallConsistencyScore: Int {
        let bedtimeScore = self
            .bedtimeVariance < 1800 ? 50 :
            max(0, 50 - Int(self.bedtimeVariance / 120)) // 30min = 50, decreases by 1 per 2min
        let waketimeScore = self.waketimeVariance < 1800 ? 50 : max(0, 50 - Int(self.waketimeVariance / 120))
        return bedtimeScore + waketimeScore
    }
}

struct ConsistencyScore: View {
    let score: Int

    var body: some View {
        VStack(spacing: 2) {
            Text("\(self.score)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(self.scoreColor)
            Text("Score")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(self.scoreColor.opacity(0.1))
        )
    }

    private var scoreColor: Color {
        switch self.score {
        case 80 ... 100: return .green
        case 60 ... 79: return .yellow
        default: return .orange
        }
    }
}

struct ConsistencyMetric: View {
    let title: String
    let variance: TimeInterval
    let averageTime: Date
    let isGood: Bool

    var body: some View {
        VStack(spacing: 8) {
            // Title and status
            HStack(spacing: 4) {
                Text(self.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Image(systemName: self.isGood ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(self.isGood ? .green : .orange)
            }

            // Average time
            Text(self.formatTime(self.averageTime))
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            // Variance
            Text("±\(self.formatVariance(self.variance))")
                .font(.caption)
                .foregroundColor(self.isGood ? .green : .orange)
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatVariance(_ variance: TimeInterval) -> String {
        let minutes = Int(variance / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(remainingMinutes)m"
        }
    }
}

struct SleepOptimizationTips: View {
    let bedtimeVariance: TimeInterval
    let waketimeVariance: TimeInterval

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Optimization Tips")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                ForEach(self.optimizationTips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                            .foregroundColor(.purple)
                        Text(tip)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.yellow.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var optimizationTips: [String] {
        var tips: [String] = []

        if self.bedtimeVariance > 3600 { // > 1 hour
            tips.append("Try to go to bed within 30 minutes of the same time each night")
        }

        if self.waketimeVariance > 3600 { // > 1 hour
            tips.append("Set a consistent wake time, even on weekends, to regulate your circadian rhythm")
        }

        if self.bedtimeVariance < 1800, self.waketimeVariance < 1800 { // Both good
            tips.append("Great consistency! This stable schedule supports optimal sleep quality")
        }

        if tips.isEmpty {
            tips.append("Maintain your current schedule - consistency is key to better sleep")
        }

        return tips
    }
}
