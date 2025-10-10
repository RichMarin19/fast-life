import SwiftUI

// MARK: - Sleep History Row Component
// Extracted from SleepTrackingView.swift for better code organization
// Following Apple MVVM patterns and SwiftUI component architecture

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
                            if newValue {
                                // DIRECT AUTHORIZATION: Apple HIG contextual permission pattern
                                // Request sleep permissions immediately when user enables sleep sync
                                print("📱 SleepTrackingView: Requesting sleep authorization directly")
                                HealthKitManager.shared.requestSleepAuthorization { success, error in
                                    DispatchQueue.main.async {
                                        if success {
                                            print("✅ SleepTrackingView: Sleep authorization granted - enabling sync")
                                            sleepManager.setSyncPreference(true)
                                        } else {
                                            print("❌ SleepTrackingView: Sleep authorization denied")
                                            sleepManager.setSyncPreference(false)
                                        }
                                    }
                                }
                            } else {
                                sleepManager.setSyncPreference(false)
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

// MARK: - Preview

#Preview("Sleep History Row") {
    SleepHistoryRow(
        sleep: SleepEntry(
            bedTime: Calendar.current.date(byAdding: .hour, value: -8, to: Date()) ?? Date(),
            wakeTime: Date(),
            quality: 4,
            source: .manual
        ),
        onDelete: {}
    )
    .padding()
}

#Preview("Add Sleep View") {
    AddSleepView(sleepManager: SleepManager())
}