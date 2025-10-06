import SwiftUI

struct SleepTrackingView: View {
    @StateObject private var sleepManager = SleepManager()
    @State private var showingAddSleep = false
    @State private var showingSyncSettings = false

    // Recommended sleep hours (CDC recommendation for adults)
    private let recommendedSleep: Double = 7.0

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer()
                    .frame(height: 20)

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
                    Image(systemName: "gear")
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
                Text(formatDate(sleep.wakeTime))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("\(formatTime(sleep.bedTime)) - \(formatTime(sleep.wakeTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(sleep.formattedDuration)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Button(action: onDelete) {
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
                    DatePicker("Bed Time", selection: $bedTime, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("Wake Time", selection: $wakeTime, displayedComponents: [.date, .hourAndMinute])
                }

                Section(header: Text("Sleep Duration")) {
                    if wakeTime > bedTime {
                        let duration = wakeTime.timeIntervalSince(bedTime)
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

                Section(header: Text("Sleep Quality (Optional)"), footer: Text("Rate your sleep quality from 1 (poor) to 5 (excellent)")) {
                    Picker("Quality", selection: $sleepQuality) {
                        Text("Not rated").tag(nil as Int?)
                        ForEach(1...5, id: \.self) { rating in
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
                        dismiss()
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
                        sleepManager.addSleepEntry(entry)
                        dismiss()
                    }
                    .disabled(wakeTime <= bedTime)
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

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("HealthKit Sync"), footer: Text("Automatically sync sleep data with Apple Health. This allows you to see sleep tracked by your Apple Watch or other apps.")) {
                    Toggle("Sync with HealthKit", isOn: Binding(
                        get: { sleepManager.syncWithHealthKit },
                        set: { newValue in
                            if newValue && !HealthKitManager.shared.isSleepAuthorized() {
                                // BLOCKER 5 FIX: Request SLEEP authorization only (granular)
                                // Reference: https://developer.apple.com/documentation/healthkit/protecting_user_privacy
                                print("📱 SleepTrackingView: Requesting SLEEP authorization (granular)...")
                                HealthKitManager.shared.requestSleepAuthorization { success, error in
                                    if success {
                                        print("✅ SleepTrackingView: Sleep authorization granted")
                                        sleepManager.setSyncPreference(true)
                                    } else {
                                        print("❌ SleepTrackingView: Sleep authorization denied")
                                    }
                                }
                            } else {
                                sleepManager.setSyncPreference(newValue)
                            }
                        }
                    ))
                }

                if sleepManager.syncWithHealthKit {
                    Section {
                        Button(action: {
                            showingSyncConfirmation = true
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
                        Text("Sleep tracking syncs with Apple Health to consolidate data from your Apple Watch, iPhone, and other sleep tracking apps.")
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
                        dismiss()
                    }
                }
            }
            .alert("Sync from HealthKit", isPresented: $showingSyncConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Sync Now") {
                    sleepManager.syncFromHealthKit()
                }
            } message: {
                Text("This will import sleep data from Apple Health for the last 30 days.")
            }
        }
    }
}

#Preview {
    NavigationStack {
        SleepTrackingView()
    }
}
