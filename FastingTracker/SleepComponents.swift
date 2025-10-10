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
    @State private var isSyncing: Bool = false
    @State private var showingSyncAlert: Bool = false
    @State private var syncMessage: String = ""

    // Industry standard: One-time historical import choice tracking
    // Following Apple iCloud, MyFitnessPal patterns - ask once, then auto-sync forever
    private let userDefaults = UserDefaults.standard
    private let hasCompletedInitialImportKey = "sleepHasCompletedInitialImport"

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
                            // Industry standard: Check if user already made initial import choice
                            // Following Weight Settings successful pattern
                            if hasCompletedInitialImport() {
                                // User already made choice - proceed with regular sync
                                performRegularSync()
                            } else {
                                // First time - show historical import choice dialog
                                showingSyncConfirmation = true
                            }
                        }) {
                            HStack {
                                if isSyncing {
                                    ProgressView()
                                        .padding(.trailing, 4)
                                } else {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .foregroundColor(.purple)
                                }
                                Text(isSyncing ? "Syncing..." : "Sync from HealthKit Now")
                            }
                        }
                        .disabled(isSyncing)
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
            .alert("Import Sleep Data", isPresented: $showingSyncConfirmation) {
                // Following Weight tracker successful pattern - user choice for import scope
                // Industry standards (MyFitnessPal/Lose It): Always let user choose import type
                Button("Import All Historical Data") {
                    performHistoricalSync()
                }
                Button("Future Data Only") {
                    performFutureSync()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Choose how to sync your sleep data with Apple Health. You can import all your historical sleep entries or start fresh with only future entries.")
            }
            .alert("Sync Status", isPresented: $showingSyncAlert) {
                Button("OK") { }
            } message: {
                Text(syncMessage)
            }
        }
    }

    // MARK: - Sync Methods
    // Following Weight Settings successful pattern for manual sync with user feedback

    private func performHistoricalSync() {
        // INDUSTRY STANDARD FIX: Use comprehensive sync to ensure all entries are captured
        // Following MyFitnessPal pattern: Once user chooses historical import, maintain comprehensive scope
        // Use 2-year lookback to ensure we capture all possible historical sleep data
        let startDate = Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()

        isSyncing = true

        // Use anchored sync with anchor reset for deletion detection
        // Following Apple HealthKit Programming Guide: Use anchored query with reset for manual sync
        sleepManager.syncFromHealthKitWithReset(startDate: startDate) { syncedCount, error in
            DispatchQueue.main.async {
                self.isSyncing = false

                if let error = error {
                    // Handle sync errors with user-friendly messages
                    self.syncMessage = error.localizedDescription
                    self.showingSyncAlert = true
                    AppLogger.error("Sleep sync failed", category: AppLogger.sleep, error: error)
                } else {
                    // Report accurate sync results based on actual HealthKit data transfer
                    if syncedCount > 0 {
                        self.syncMessage = "Successfully synced \(syncedCount) new sleep entries from Apple Health with detailed stage analysis."
                    } else {
                        // Could mean: no new data, no permission, or all data already synced
                        let hasPermission = HealthKitManager.shared.isSleepAuthorized()
                        if hasPermission {
                            self.syncMessage = "Sleep data is up to date. No new entries found in Apple Health."
                        } else {
                            self.syncMessage = "Permission denied. Enable sleep access in Settings → Privacy & Security → Health → Data Access & Devices → Fast LIFe → Turn on Sleep Analysis."
                        }
                    }
                    self.showingSyncAlert = true

                    // Mark initial import as completed - user made their choice
                    self.markInitialImportCompleted()

                    AppLogger.info("Sleep sync completed: \(syncedCount) new entries", category: AppLogger.sleep)
                }
            }
        }
    }

    private func performFutureSync() {
        // Future sync: Start from today going forward
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()

        isSyncing = true

        // Use regular sync (no anchor reset) for future-only sync
        sleepManager.syncFromHealthKit(startDate: startDate)

        // Provide immediate feedback since regular sync doesn't have completion handler
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isSyncing = false
            self.syncMessage = "Future sleep sync enabled. New sleep entries will be automatically synced from Apple Health."
            self.showingSyncAlert = true

            // Mark initial import as completed - user made their choice
            self.markInitialImportCompleted()

            AppLogger.info("Future-only sleep sync configured", category: AppLogger.sleep)
        }
    }

    /// Perform regular sync for users who already completed initial import choice
    /// Following Weight Settings successful pattern for repeat syncs
    private func performRegularSync() {
        // Use comprehensive sync with anchor reset for manual sync (industry standard)
        let startDate = Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()

        isSyncing = true

        // Use anchored sync with reset for deletion detection
        sleepManager.syncFromHealthKitWithReset(startDate: startDate) { syncedCount, error in
            DispatchQueue.main.async {
                self.isSyncing = false

                if let error = error {
                    self.syncMessage = error.localizedDescription
                    self.showingSyncAlert = true
                    AppLogger.error("Sleep regular sync failed", category: AppLogger.sleep, error: error)
                } else {
                    if syncedCount > 0 {
                        self.syncMessage = "Successfully synced \(syncedCount) sleep entries from Apple Health."
                    } else {
                        self.syncMessage = "Sleep data is up to date. No new entries found in Apple Health."
                    }
                    self.showingSyncAlert = true
                    AppLogger.info("Sleep regular sync completed: \(syncedCount) entries", category: AppLogger.sleep)
                }
            }
        }
    }

    // MARK: - One-Time Setup Helper

    /// Check if user has completed initial historical import choice
    /// Following industry standard: One-time setup, then seamless auto-sync
    private func hasCompletedInitialImport() -> Bool {
        return userDefaults.bool(forKey: hasCompletedInitialImportKey)
    }

    /// Mark initial import as completed (user made their choice)
    /// Following Apple iCloud, MyFitnessPal pattern: Remember user choice permanently
    private func markInitialImportCompleted() {
        userDefaults.set(true, forKey: hasCompletedInitialImportKey)
        AppLogger.info("Marked sleep initial import as completed", category: AppLogger.sleep)
    }
}

// MARK: - Sleep Stage Timeline Component
// Following Apple Health design pattern for sleep stage visualization
// Replicates the horizontal bar chart with color-coded sleep stages

struct SleepStageTimelineView: View {
    let sleepEntry: SleepEntry

    var body: some View {
        VStack(spacing: 16) {
            // Main timeline chart
            SleepTimelineChart(sleepEntry: sleepEntry)

            // Stage duration summary (Apple Health pattern)
            StageSummaryView(stageDurations: sleepEntry.stageDurations)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

struct SleepTimelineChart: View {
    let sleepEntry: SleepEntry

    // Calculate timeline parameters
    private var totalDuration: TimeInterval {
        sleepEntry.wakeTime.timeIntervalSince(sleepEntry.bedTime)
    }

    private var timeLabels: [String] {
        // Generate time labels like Apple Health (11 PM, 2 AM, 5 AM, 8 AM)
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"

        var labels: [String] = []
        let startTime = sleepEntry.bedTime
        let interval: TimeInterval = totalDuration / 4 // 4 time points

        for i in 0...4 {
            let time = startTime.addingTimeInterval(interval * TimeInterval(i))
            labels.append(formatter.string(from: time))
        }
        return labels
    }

    var body: some View {
        VStack(spacing: 8) {
            // Sleep stage title and duration
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TIME ASLEEP")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)

                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        let duration = sleepEntry.duration
                        let hours = Int(duration / 3600)
                        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)

                        Text("\(hours)")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                        Text("hr")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("\(minutes)")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                        Text("min")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }

                    Text(formatDateRange(sleepEntry.bedTime, sleepEntry.wakeTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Info button (like Apple Health)
                Button(action: {}) {
                    Image(systemName: "info.circle")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }

            // Timeline bars (4 rows like Apple Health)
            VStack(spacing: 4) {
                StageTimelineRow(title: "Awake", stageType: .awake, sleepEntry: sleepEntry)
                StageTimelineRow(title: "REM", stageType: .rem, sleepEntry: sleepEntry)
                StageTimelineRow(title: "Core", stageType: .core, sleepEntry: sleepEntry)
                StageTimelineRow(title: "Deep", stageType: .deep, sleepEntry: sleepEntry)
            }
            .padding(.vertical, 8)

            // Time labels at bottom
            HStack {
                ForEach(0..<timeLabels.count, id: \.self) { index in
                    if index == 0 {
                        Text(timeLabels[index])
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    } else if index == timeLabels.count - 1 {
                        Text(timeLabels[index])
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text(timeLabels[index])
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
        }
    }

    private func formatDateRange(_ bedTime: Date, _ wakeTime: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: bedTime)
    }
}

struct StageTimelineRow: View {
    let title: String
    let stageType: SleepStageType
    let sleepEntry: SleepEntry

    var body: some View {
        HStack(spacing: 8) {
            // Stage label
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .leading)

            // Timeline bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    Rectangle()
                        .fill(Color(.systemGray6))
                        .frame(height: 20)
                        .cornerRadius(2)

                    // Stage segments
                    ForEach(sleepEntry.stages.filter { $0.type == stageType }, id: \.id) { stage in
                        let startOffset = offsetForTime(stage.startTime, in: geometry.size.width)
                        let width = widthForDuration(stage.duration, in: geometry.size.width)

                        Rectangle()
                            .fill(colorForStageType(stageType))
                            .frame(width: width, height: 20)
                            .cornerRadius(2)
                            .offset(x: startOffset)
                    }
                }
            }
            .frame(height: 20)
        }
    }

    private func offsetForTime(_ time: Date, in totalWidth: CGFloat) -> CGFloat {
        let totalDuration = sleepEntry.wakeTime.timeIntervalSince(sleepEntry.bedTime)
        let timeOffset = time.timeIntervalSince(sleepEntry.bedTime)
        return CGFloat(timeOffset / totalDuration) * totalWidth
    }

    private func widthForDuration(_ duration: TimeInterval, in totalWidth: CGFloat) -> CGFloat {
        let totalDuration = sleepEntry.wakeTime.timeIntervalSince(sleepEntry.bedTime)
        return CGFloat(duration / totalDuration) * totalWidth
    }

    private func colorForStageType(_ stageType: SleepStageType) -> Color {
        switch stageType {
        case .awake: return Color.orange
        case .rem: return Color.cyan.opacity(0.7)
        case .core: return Color.blue
        case .deep: return Color.blue.opacity(0.8)
        case .inBed: return Color.gray.opacity(0.3)
        }
    }
}

struct StageSummaryView: View {
    let stageDurations: StageDurations

    var body: some View {
        VStack(spacing: 8) {
            // Section tabs (like Apple Health)
            HStack(spacing: 0) {
                StageSummaryTab(title: "Stages", isSelected: true)
                StageSummaryTab(title: "Amounts", isSelected: false)
                StageSummaryTab(title: "Comparisons", isSelected: false)
                Spacer()
            }

            // Stage duration list
            VStack(spacing: 12) {
                StageDurationRow(
                    color: .orange,
                    title: "Awake",
                    duration: stageDurations.formatted(stageDurations.awake)
                )

                StageDurationRow(
                    color: .cyan.opacity(0.7),
                    title: "REM",
                    duration: stageDurations.formatted(stageDurations.rem)
                )

                StageDurationRow(
                    color: .blue,
                    title: "Core",
                    duration: stageDurations.formatted(stageDurations.core)
                )

                StageDurationRow(
                    color: .blue.opacity(0.8),
                    title: "Deep",
                    duration: stageDurations.formatted(stageDurations.deep)
                )
            }
        }
    }
}

struct StageSummaryTab: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Button(action: {}) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .primary : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color(.systemGray6) : Color.clear)
                )
        }
    }
}

struct StageDurationRow: View {
    let color: Color
    let title: String
    let duration: String

    var body: some View {
        HStack(spacing: 12) {
            // Color indicator
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()

            Text(duration)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
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

#Preview("Sleep Stage Timeline") {
    // Create sample sleep entry with detailed stage data
    let bedTime = Calendar.current.date(byAdding: .hour, value: -8, to: Date()) ?? Date()
    let wakeTime = Date()

    let sampleStages = [
        SleepStage(startTime: bedTime, endTime: bedTime.addingTimeInterval(30*60), type: .inBed),
        SleepStage(startTime: bedTime.addingTimeInterval(30*60), endTime: bedTime.addingTimeInterval(90*60), type: .core),
        SleepStage(startTime: bedTime.addingTimeInterval(90*60), endTime: bedTime.addingTimeInterval(120*60), type: .deep),
        SleepStage(startTime: bedTime.addingTimeInterval(120*60), endTime: bedTime.addingTimeInterval(180*60), type: .core),
        SleepStage(startTime: bedTime.addingTimeInterval(180*60), endTime: bedTime.addingTimeInterval(210*60), type: .rem),
        SleepStage(startTime: bedTime.addingTimeInterval(210*60), endTime: bedTime.addingTimeInterval(240*60), type: .awake),
        SleepStage(startTime: bedTime.addingTimeInterval(240*60), endTime: bedTime.addingTimeInterval(360*60), type: .core),
        SleepStage(startTime: bedTime.addingTimeInterval(360*60), endTime: bedTime.addingTimeInterval(420*60), type: .deep),
        SleepStage(startTime: bedTime.addingTimeInterval(420*60), endTime: wakeTime, type: .rem)
    ]

    let sampleSleep = SleepEntry(
        bedTime: bedTime,
        wakeTime: wakeTime,
        quality: 4,
        source: .healthKit,
        stages: sampleStages
    )

    SleepStageTimelineView(sleepEntry: sampleSleep)
        .padding()
}