import SwiftUI

struct SleepTrackingView: View {
    @StateObject private var sleepManager = SleepManager()
    @StateObject private var nudgeManager = HealthKitNudgeManager.shared
    @State private var showingAddSleep = false
    @State private var showingSyncSettings = false
    @State private var showHealthKitNudge = false
    // Removed: @State private var showingHealthDataSelection - unified direct authorization

    // Recommended sleep hours (CDC recommendation for adults)
    private let recommendedSleep: Double = 7.0

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer()
                    .frame(height: 20)

                // HealthKit Nudge for first-time users who skipped onboarding
                // Following Lose It app pattern - contextual banner with single Connect action
                if self.showHealthKitNudge, self.nudgeManager.shouldShowNudge(for: .sleep) {
                    HealthKitNudgeView(
                        dataType: .sleep,
                        onConnect: {
                            // DIRECT AUTHORIZATION: Same pattern as existing sleep sync
                            // Request sleep permissions immediately when user wants to connect
                            print("📱 SleepTrackingView: HealthKit nudge - requesting sleep authorization")
                            HealthKitManager.shared.requestSleepAuthorization { success, error in
                                DispatchQueue.main.async {
                                    if success {
                                        print("✅ SleepTrackingView: Sleep authorization granted from nudge")
                                        // Enable sync automatically when granted from nudge
                                        self.sleepManager.setSyncPreference(true)
                                        // Hide nudge after successful connection
                                        self.showHealthKitNudge = false
                                    } else {
                                        print("❌ SleepTrackingView: Sleep authorization denied from nudge")
                                        // Still hide nudge if user denied (don't keep asking)
                                        self.nudgeManager.dismissNudge(for: .sleep)
                                        self.showHealthKitNudge = false
                                    }
                                }
                            }
                        },
                        onDismiss: {
                            // Mark nudge as dismissed - won't show again
                            self.nudgeManager.dismissNudge(for: .sleep)
                            self.showHealthKitNudge = false
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

                Spacer()
                    .frame(height: 10)

                // Add Sleep Button
                Button(action: {
                    self.showingAddSleep = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                        Text("Log Sleep")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 40)

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
        }
        .navigationTitle("Sleep Tracker")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Show HealthKit nudge for first-time users who skipped onboarding
            // Following Lose It pattern - contextual reminder on first tracker access
            self.showHealthKitNudge = self.nudgeManager.shouldShowNudge(for: .sleep)
            if self.showHealthKitNudge {
                print("📱 SleepTrackingView: Showing HealthKit nudge for first-time user")
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    self.showingSyncSettings = true
                }) {
                    Image(systemName: "gear")
                        .foregroundColor(.purple)
                }
            }
        }
        .sheet(isPresented: self.$showingAddSleep) {
            AddSleepView(sleepManager: self.sleepManager)
        }
        .sheet(isPresented: self.$showingSyncSettings) {
            SleepSyncSettingsView(sleepManager: self.sleepManager)
        }
    }
}

// MARK: - Sleep History Row Component

struct SleepHistoryRow: View {
    let sleep: SleepEntry
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bed.double.fill")
                .font(.system(size: 20))
                .foregroundColor(.purple)
                .frame(width: 40, height: 40)
                .background(Color.purple.opacity(0.15))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(self.formatDate(self.sleep.wakeTime))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("\(self.formatTime(self.sleep.bedTime)) - \(self.formatTime(self.sleep.wakeTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(self.sleep.formattedDuration)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Button(action: self.onDelete) {
                Image(systemName: "trash")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Add Sleep View

struct AddSleepView: View {
    @ObservedObject var sleepManager: SleepManager
    @Environment(\.dismiss) var dismiss

    @State private var bedTime = Calendar.current.date(byAdding: .hour, value: -8, to: Date()) ?? Date()
    @State private var wakeTime = Date()
    @State private var sleepQuality: Int? = nil

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Sleep Times")) {
                    DatePicker("Bed Time", selection: self.$bedTime, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("Wake Time", selection: self.$wakeTime, displayedComponents: [.date, .hourAndMinute])
                }

                Section(header: Text("Sleep Duration")) {
                    if self.wakeTime > self.bedTime {
                        let duration = self.wakeTime.timeIntervalSince(self.bedTime)
                        let hours = Int(duration / 3600)
                        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
                        Text("\(hours) hours \(minutes) minutes")
                            .font(.headline)
                            .foregroundColor(.purple)
                    } else {
                        Text("Wake time must be after bed time")
                            .foregroundColor(.red)
                    }
                }

                Section(
                    header: Text("Sleep Quality (Optional)"),
                    footer: Text("Rate your sleep quality from 1 (poor) to 5 (excellent)")
                ) {
                    Picker("Quality", selection: self.$sleepQuality) {
                        Text("Not rated").tag(nil as Int?)
                        ForEach(1 ... 5, id: \.self) { rating in
                            HStack {
                                Text("\(rating)")
                                Text(String(repeating: "⭐", count: rating))
                            }
                            .tag(rating as Int?)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("Log Sleep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        self.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let entry = SleepEntry(
                            bedTime: bedTime,
                            wakeTime: wakeTime,
                            quality: sleepQuality,
                            source: .manual
                        )
                        self.sleepManager.addSleepEntry(entry)
                        self.dismiss()
                    }
                    .disabled(self.wakeTime <= self.bedTime)
                }
            }
        }
    }
}

// MARK: - Sleep Sync Settings View

struct SleepSyncSettingsView: View {
    @ObservedObject var sleepManager: SleepManager
    @Environment(\.dismiss) var dismiss
    @State private var showingSyncConfirmation = false
    // Removed: @State private var showingHealthDataSelection - unified direct authorization

    var body: some View {
        NavigationView {
            Form {
                Section(
                    header: Text("HealthKit Sync"),
                    footer: Text(
                        "Automatically sync sleep data with Apple Health. This allows you to see sleep tracked by your Apple Watch or other apps."
                    )
                ) {
                    Toggle("Sync with HealthKit", isOn: Binding(
                        get: { self.sleepManager.syncWithHealthKit },
                        set: { newValue in
                            if newValue {
                                // DIRECT AUTHORIZATION: Apple HIG contextual permission pattern
                                // Request sleep permissions immediately when user enables sleep sync
                                // UNIFIED EXPERIENCE: Same pattern as WeightTrackingView
                                print("📱 SleepTrackingView: Requesting sleep authorization directly")
                                HealthKitManager.shared.requestSleepAuthorization { success, error in
                                    DispatchQueue.main.async {
                                        if success {
                                            print("✅ SleepTrackingView: Sleep authorization granted - enabling sync")
                                            self.sleepManager.setSyncPreference(true)
                                        } else {
                                            print("❌ SleepTrackingView: Sleep authorization denied")
                                            self.sleepManager.setSyncPreference(false)
                                        }
                                    }
                                }
                            } else {
                                self.sleepManager.setSyncPreference(false)
                            }
                        }
                    ))
                }

                if self.sleepManager.syncWithHealthKit {
                    Section {
                        Button(action: {
                            self.showingSyncConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .foregroundColor(.purple)
                                Text("Sync from HealthKit Now")
                            }
                        }
                    }
                }

                Section(header: Text("About")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(
                            "Sleep tracking syncs with Apple Health to consolidate data from your Apple Watch, iPhone, and other sleep tracking apps."
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)

                        Text("Manually logged sleep is automatically saved to Apple Health when sync is enabled.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Sleep Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        self.dismiss()
                    }
                }
            }
            .alert("Sync from HealthKit", isPresented: self.$showingSyncConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Sync Now") {
                    self.sleepManager.syncFromHealthKit()
                }
            } message: {
                Text("This will import sleep data from Apple Health for the last 30 days.")
            }
            // Removed: HealthDataSelectionView sheet - unified direct authorization per Apple HIG
        }
    }

    // Removed: handleHealthDataSelection - unified direct authorization pattern
}

#Preview {
    NavigationStack {
        SleepTrackingView()
    }
}
