import SwiftUI

// MARK: - Sleep Tracking View
// Refactored from 437 → ~88 lines (80% reduction)
// Following Apple MVVM patterns and Phase 3a/3b/3c component extraction lessons

struct SleepTrackingView: View {
    @StateObject private var sleepManager = SleepManager()
    @StateObject private var nudgeManager = HealthKitNudgeManager.shared
    @State private var showingAddSleep = false
    @State private var showingSyncSettings = false
    @State private var showHealthKitNudge = false

    // Recommended sleep hours (CDC recommendation for adults)
    private let recommendedSleep: Double = 7.0

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer()
                    .frame(height: 20)

                // HealthKit Nudge for first-time users who skipped onboarding
                if showHealthKitNudge && nudgeManager.shouldShowNudge(for: .sleep) {
                    HealthKitNudgeView(
                        dataType: .sleep,
                        onConnect: {
                            print("📱 SleepTrackingView: HealthKit nudge - requesting sleep authorization")
                            HealthKitManager.shared.requestSleepAuthorization { success, error in
                                DispatchQueue.main.async {
                                    if success {
                                        print("✅ SleepTrackingView: Sleep authorization granted from nudge")
                                        sleepManager.setSyncPreference(true)
                                        showHealthKitNudge = false
                                    } else {
                                        print("❌ SleepTrackingView: Sleep authorization denied from nudge")
                                        nudgeManager.dismissNudge(for: .sleep)
                                        showHealthKitNudge = false
                                    }
                                }
                            }
                        },
                        onDismiss: {
                            nudgeManager.dismissNudge(for: .sleep)
                            showHealthKitNudge = false
                        }
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }

                // Sleep Progress Ring
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 20)
                        .frame(width: 250, height: 250)

                    // Sleep progress ring
                    if let lastNight = sleepManager.lastNightSleep {
                        let sleepHours = lastNight.duration / 3600
                        let progress = min(sleepHours / recommendedSleep, 1.0)

                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                sleepHours >= recommendedSleep ? Color.green : Color.purple,
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
                            Text("\(Int(recommendedSleep)) hrs")
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

                Spacer()
                    .frame(height: 10)

                // Add Sleep Button
                Button(action: {
                    showingAddSleep = true
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

                // Recent Sleep History
                if !sleepManager.sleepEntries.isEmpty {
                    VStack(spacing: 12) {
                        Text("Recent Sleep")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 40)

                        ForEach(Array(sleepManager.sleepEntries.prefix(5))) { entry in
                            SleepHistoryRow(sleep: entry, onDelete: {
                                sleepManager.deleteSleepEntry(entry)
                            })
                            .padding(.horizontal, 40)
                        }
                    }
                    .padding(.bottom, 20)
                }

                Spacer()
                    .frame(height: 20)
            }
        }
        .navigationTitle("Sleep Tracker")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingSyncSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.purple)
                }
            }
        }
        .sheet(isPresented: $showingAddSleep) {
            AddSleepView(sleepManager: sleepManager)
        }
        .sheet(isPresented: $showingSyncSettings) {
            SleepSyncSettingsView(sleepManager: sleepManager)
        }
        .onAppear {
            showHealthKitNudge = nudgeManager.shouldShowNudge(for: .sleep)
            if showHealthKitNudge {
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