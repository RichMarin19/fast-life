import Charts
import SwiftUI

// MARK: - Sleep Time Range

// Following WeightTrackingView pattern for consistent time range selection
enum SleepTimeRange: String, CaseIterable {
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

// MARK: - Sleep Tracking View

// Refactored from 437 → ~88 lines (80% reduction)
// Following Apple MVVM patterns and Phase 3a/3b/3c component extraction lessons

struct SleepTrackingView: View {
    @StateObject private var sleepManager = SleepManager()
    @StateObject private var nudgeManager = HealthKitNudgeManager.shared
    @State private var showingAddSleep = false
    @State private var showingSyncSettings = false
    @State private var showHealthKitNudge = false
    @State private var selectedTimeRange: SleepTimeRange = .week

    // Recommended sleep hours (CDC recommendation for adults)
    private let recommendedSleep: Double = 7.0

    private var healthKitNudgeView: AnyView? {
        if self.showHealthKitNudge, self.nudgeManager.shouldShowNudge(for: .sleep) {
            return AnyView(
                HealthKitNudgeView(
                    dataType: .sleep,
                    onConnect: {
                        print("📱 SleepTrackingView: HealthKit nudge - requesting sleep authorization")
                        HealthKitManager.shared.requestSleepAuthorization { success, error in
                            DispatchQueue.main.async {
                                if success {
                                    print("✅ SleepTrackingView: Sleep authorization granted from nudge")
                                    self.sleepManager.setSyncPreference(true)
                                    self.showHealthKitNudge = false
                                } else {
                                    print("❌ SleepTrackingView: Sleep authorization denied from nudge")
                                    self.nudgeManager.dismissNudge(for: .sleep)
                                    self.showHealthKitNudge = false
                                }
                            }
                        }
                    },
                    onDismiss: {
                        self.nudgeManager.dismissNudge(for: .sleep)
                        self.showHealthKitNudge = false
                    }
                )
            )
        }
        return nil
    }

    var body: some View {
        TrackerScreenShell(
            title: ("Sleep Tr", "ac", "ker"), // Matching Weight Tracker gradient pattern
            hasData: !self.sleepManager.sleepEntries.isEmpty,
            nudge: self.healthKitNudgeView,
            settingsAction: { self.showingSyncSettings = true } // Matching gear icon functionality
        ) {
            // Sleep Progress Ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 20)
                    .frame(width: 250, height: 250)

                // Sleep progress ring
                if let lastNight = sleepManager.lastNightSleep {
                    let sleepHours = lastNight.duration / 3600
                    let progress = min(sleepHours / self.recommendedSleep, 1.0)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            sleepHours >= self.recommendedSleep ? Color.green : Color.purple,
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 250, height: 250)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: progress)
                }

                VStack(spacing: 12) {
                    Image(systemName: "bed.double.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.purple)

                    // Last night's sleep
                    VStack(spacing: 4) {
                        Text("Last Night")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let lastNight = sleepManager.lastNightSleep {
                            Text(String(format: "%.1f hrs", lastNight.duration / 3600))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                        } else {
                            Text("No data")
                                .font(.system(size: 24, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }

                    // Recommended
                    VStack(spacing: 4) {
                        Text("Goal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(self.recommendedSleep)) hrs")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundColor(.purple)
                    }
                }
            }

            // Sleep Stats
            if let avgSleep = sleepManager.averageSleepHours {
                HStack(spacing: 40) {
                    VStack(spacing: 8) {
                        Text("7-Day Avg")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f hrs", avgSleep))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }

                    if let trend = sleepManager.sleepTrend {
                        VStack(spacing: 8) {
                            Text("Trend")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack(spacing: 4) {
                                Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                                    .font(.caption)
                                    .foregroundColor(trend >= 0 ? .green : .red)
                                Text(String(format: "%.1f hrs", abs(trend)))
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(trend >= 0 ? .green : .red)
                            }
                        }
                    }
                }
                .padding(.bottom, 10)
            }

            // Add Sleep Button (positioned above charts for better UX flow)
            Button(action: {
                self.showingAddSleep = true
            }) {
                Text("Log Sleep")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 20)

            // Sleep Optimization Charts (More user-friendly than Apple Health)
            // Following Apple 2025 industry standard: display charts with basic data, not just detailed stages
            if let lastNight = sleepManager.lastNightSleep {
                VStack(spacing: 20) {
                    // Show stage breakdown chart only when detailed stage data exists
                    if !lastNight.stages.isEmpty {
                        // Sleep Stage Breakdown Chart (Pie chart with quality score)
                        SleepStageBreakdownChart(sleepEntry: lastNight)
                            .padding(.horizontal, 40)
                    }

                    // Sleep Duration Chart (Apple Health style with brainwave colors) - works with basic duration data
                    if self.sleepManager.sleepEntries.count >= 2 {
                        VStack(spacing: 0) {
                            // Time Range Selector (matching Weight Tracker exactly)
                            HStack {
                                Text("Sleep Duration")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Spacer()

                                Menu {
                                    ForEach(SleepTimeRange.allCases, id: \.self) { range in
                                        Button(range.rawValue) {
                                            self.selectedTimeRange = range
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(self.selectedTimeRange.rawValue)
                                            .font(.subheadline)
                                            .foregroundColor(.purple)
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(.purple)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.purple.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal, 40)
                            .padding(.bottom, 12)

                            SleepBarChart(
                                sleepEntries: self.sleepManager.sleepEntries,
                                timeRange: self.selectedTimeRange
                            )
                            .padding(.horizontal, 40)
                        }
                    }

                    // Sleep Consistency Analysis (Bedtime/wake time optimization) - works with basic timing data
                    if self.sleepManager.sleepEntries.count >= 3 {
                        SleepConsistencyChart(sleepEntries: Array(self.sleepManager.sleepEntries.prefix(7)))
                            .padding(.horizontal, 40)
                    }
                }
                .padding(.bottom, 30)
            }

            // Sleep Stage Timeline (Apple Health style)
            // Show detailed stage breakdown for last night's sleep if available
            if let lastNight = sleepManager.lastNightSleep, !lastNight.stages.isEmpty {
                VStack(spacing: 0) {
                    Text("Sleep Stages")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 16)

                    SleepStageTimelineView(sleepEntry: lastNight)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 20)
            }

            Spacer()
                .frame(height: 10)

            // Recent Sleep History
            if !self.sleepManager.sleepEntries.isEmpty {
                VStack(spacing: 12) {
                    Text("Recent Sleep")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 40)

                    ForEach(Array(self.sleepManager.sleepEntries.prefix(5))) { entry in
                        SleepHistoryRow(sleep: entry, onDelete: {
                            self.sleepManager.deleteSleepEntry(entry)
                        })
                        .padding(.horizontal, 40)
                    }
                }
                .padding(.bottom, 20)
            }

            Spacer()
                .frame(height: 20)
        }
        .sheet(isPresented: self.$showingAddSleep) {
            AddSleepView(sleepManager: self.sleepManager)
        }
        .sheet(isPresented: self.$showingSyncSettings) {
            SleepSyncSettingsView(sleepManager: self.sleepManager)
        }
        .onAppear {
            self.showHealthKitNudge = self.nudgeManager.shouldShowNudge(for: .sleep)
            if self.showHealthKitNudge {
                print("📱 SleepTrackingView: Showing HealthKit nudge for first-time user")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SleepTrackingView()
    }
}
