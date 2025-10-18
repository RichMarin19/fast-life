import SwiftUI

struct ContentView: View {
    @EnvironmentObject var fastingManager: FastingManager
    @StateObject private var nudgeManager = HealthKitNudgeManager.shared
    @State private var showingGoalSettings = false
    @State private var showingStopConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var showingEditTimes = false
    @State private var showingEditStartTime = false
    @State private var selectedStage: FastingStage?
    @State private var showHealthKitNudge = false
    @State private var showingSyncOptions = false

    @State private var selectedDate: Date?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Spacer()
                        .frame(height: 30)

                    healthKitNudgeSection
                    titleSection
                    timerSection
            }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        // TODO: Add settings functionality
                        AppLogger.debug("Settings tapped", category: AppLogger.ui)
                    }
                }
            }
            .onAppear {
                // Check if fasting goal needs to be set
                if fastingManager.fastingGoalHours == 0 {
                    showingGoalSettings = true
                }

                // Show HealthKit nudge for first-time users who skipped onboarding
                // Following Lose It pattern - contextual reminder on main screen
                showHealthKitNudge = nudgeManager.shouldShowNudge(for: .fasting)
                if showHealthKitNudge {
                    AppLogger.info("Showing HealthKit nudge for first-time user", category: AppLogger.ui)
                }
            }
            .sheet(isPresented: $showingGoalSettings) {
                GoalSettingsView()
                    .environmentObject(fastingManager)
            }
            .sheet(isPresented: $showingEditStartTime) {
                EditStartTimeView()
                    .environmentObject(fastingManager)
            }
            .sheet(isPresented: $showingEditTimes) {
                EditFastTimesView()
                    .environmentObject(fastingManager)
            }
            .sheet(isPresented: $showingStopConfirmation) {
                StopFastConfirmationView(
                    onEditTimes: {
                        showingStopConfirmation = false
                        showingEditTimes = true
                    },
                    onStop: {
                        showingStopConfirmation = false
                        fastingManager.stopFast()
                    },
                    onDelete: {
                        showingStopConfirmation = false
                        showingDeleteConfirmation = true
                    },
                    onCancel: {
                        showingStopConfirmation = false
                    }
                )
                .presentationDetents([.height(400)])
            }
            .sheet(isPresented: $showingSyncOptions) {
                FastingSyncOptionsView(
                    onSyncAll: {
                        // CRITICAL: Dismiss modal FIRST, then request authorization after delay
                        // Apple's HealthKit dialog can't present while another modal is open
                        showingSyncOptions = false
                        showHealthKitNudge = false

                        // Small delay to ensure modal is fully dismissed before authorization
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            syncAllFastingData()
                        }
                    },
                    onSyncFuture: {
                        // CRITICAL: Dismiss modal FIRST, then request authorization after delay
                        showingSyncOptions = false
                        showHealthKitNudge = false

                        // Small delay to ensure modal is fully dismissed before authorization
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            syncFutureFastingData()
                        }
                    },
                    onCancel: {
                        showingSyncOptions = false
                    }
                )
                .presentationDetents([.height(350)])
            }
            .alert("Are you sure?", isPresented: $showingDeleteConfirmation) {
                Button("Yes", role: .destructive) {
                    fastingManager.deleteFast()
                }
                Button("No", role: .cancel) { }
            } message: {
                Text("This will permanently delete the current fast without saving it to history.")
            }
            .sheet(item: $selectedStage) { stage in
                FastingStageDetailView(stage: stage)
            }
            .sheet(item: selectedIdentifiableDate) { identifiableDate in
                AddEditFastView(date: identifiableDate.date, fastingManager: fastingManager)
                    .environmentObject(fastingManager)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenStageDetail"))) { notification in
                // Handle deep linking from stage notification tap
                // Reference: https://developer.apple.com/documentation/combine/notificationcenter/publisher
                if let stageHour = notification.userInfo?["stageHour"] as? Int {
                    // Find the stage that matches this hour
                    if let stage = FastingStage.all.first(where: { $0.startHour == stageHour }) {
                        selectedStage = stage
                    }
                }
            }
        }
    }

    // MARK: - View Components (SwiftUI Performance Optimization)

    @ViewBuilder
    private var healthKitNudgeSection: some View {
        // HealthKit Nudge for first-time users who skipped onboarding
        // Following Apple HIG: Important information at top of screen
        // Industry standard: Contextual permissions above primary content
        if showHealthKitNudge && nudgeManager.shouldShowNudge(for: .fasting) {
            FastingHealthKitNudgeView(
                onConnect: {
                    // CORRECTED FLOW: Request basic HealthKit authorization first
                    // Following Apple HIG: "Request permission immediately before you need it"
                    requestBasicHealthKitAccess()
                },
                onDismiss: {
                    // Temporary dismiss - will show again in 5 visits
                    nudgeManager.dismissNudge(for: .fasting)
                    showHealthKitNudge = false
                },
                onPermanentDismiss: {
                    // Permanent dismiss - never show again
                    nudgeManager.permanentlyDismissTimerNudge()
                    showHealthKitNudge = false
                }
            )
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    @ViewBuilder
    private var titleSection: some View {
        // Fast LIFe Title
        HStack(spacing: 0) {
            Text("Fast L")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundColor(Color("FLPrimary"))
            Text("IF")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundColor(Color("FLSuccess"))
            Text("e")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundColor(Color("FLSecondary"))
        }

        Spacer()
            .frame(height: showHealthKitNudge && nudgeManager.shouldShowNudge(for: .fasting) ? 20 : 50)
    }

    @ViewBuilder
    private var timerSection: some View {
        // Progress Ring with Educational Stage Icons
        ZStack {
            // Educational stage icons positioned around the circle
            ForEach(FastingStage.relevantStages(for: fastingManager.fastingGoalHours)) { stage in
                let midpointHour = Double(stage.startHour + stage.endHour) / 2.0
                let angle = (midpointHour / 24.0) * 360.0 - 90.0 // -90 to start at top
                let radius: CGFloat = 160
                let x = radius * cos(angle * .pi / 180)
                let y = radius * sin(angle * .pi / 180)

                Button(action: {
                    selectedStage = stage
                }) {
                    Text(stage.icon)
                        .font(.system(size: 36))
                        .background(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 50, height: 50)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                }
                .offset(x: x, y: y)
            }

            // Timer Circle
            ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 20)
                .frame(width: 250, height: 250)

            Circle()
                .trim(from: 0, to: fastingManager.progress)
                .stroke(
                    fastingManager.isActive ?
                    AngularGradient(
                        gradient: Gradient(colors: progressGradientColors),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ) : AngularGradient(
                        gradient: Gradient(colors: [Color.gray, Color.gray]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .frame(width: 250, height: 250)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: fastingManager.progress)

            VStack(spacing: 12) {
                Image(systemName: "clock")
                    .font(.system(size: 40))
                    .foregroundColor(fastingManager.isActive ? .blue : .gray)

                // Elapsed Time - Tappable to edit
                Button(action: {
                    if fastingManager.isActive {
                        showingEditStartTime = true
                    }
                }) {
                    VStack(spacing: 4) {
                        Text("Fasting")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formattedElapsedTime)
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(fastingManager.isActive ? .primary : .gray)
                    }
                }
                .buttonStyle(.plain)
                .disabled(!fastingManager.isActive)

                // Countdown Time
                VStack(spacing: 4) {
                    Text("Remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formattedRemainingTime)
                        .font(.system(size: 28, weight: .semibold, design: .monospaced))
                        .foregroundColor(fastingManager.isActive ? progressColor : .gray)
                }
            }
            }
        }

        // Progress Percentage
        Text("\(Int(fastingManager.progress * 100))%")
            .font(.title2)
            .foregroundColor(.secondary)
            .padding(.top, 10)
            .padding(.bottom, 40)

        // Streak Display
        if fastingManager.currentStreak > 0 {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("\(fastingManager.currentStreak) day\(fastingManager.currentStreak == 1 ? "" : "s") streak")
                    .font(.headline)
                    .foregroundColor(.orange)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }

        // Goal Display - Styled like Weight Tracker for consistency
        // Per Apple HIG: Use consistent design patterns across features
        // Reference: https://developer.apple.com/design/human-interface-guidelines/consistency
        Button(action: {
            showingGoalSettings = true
        }) {
            HStack(spacing: 10) {
                // 🎯 Target emoji for visual excitement
                Text("🎯")
                    .font(.system(size: 28))

                // Goal label and value - COMPACT but still EXCITING!
                (Text("GOAL: ")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(Color("FLSuccess"))
                + Text("\(Int(fastingManager.fastingGoalHours))h")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(Color("FLSuccess")))

                // Gear icon visual indicator that this is editable
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color("FLWarning"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                // Subtle green background for extra pop
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("FLSuccess").opacity(0.08))
            )
            .overlay(
                // Green border for emphasis
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color("FLSuccess").opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .padding(.bottom, 8)  // Reduced from 15 to 8 - raises button area

        // Buttons
        if fastingManager.isActive {
            // Start Time Display with Edit (inline style like competitor)
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                Text("Start")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    showingEditStartTime = true
                }) {
                    HStack(spacing: 8) {
                        Text(formatStartTimeDisplay())
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Image(systemName: "pencil")
                            .font(.subheadline)
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 40)

            // Goal End Time Display
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                Text("Goal End")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 8) {
                    Text(formatGoalEndTimeDisplay())
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color("FLWarning"))
                .cornerRadius(8)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 5)

            // Stop Fast Button
            Button(action: {
                showingStopConfirmation = true
            }) {
                Text("Stop Fast")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 40)
        } else {
            // Start Fast Button
            Button(action: {
                fastingManager.startFast()
            }) {
                Text("Start Fast")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("FLSuccess"))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 40)
        }

        // MARK: - Embedded History Content (like Weight Tracker pattern)

        if !fastingManager.fastingHistory.isEmpty {
            // Calendar View (FIRST - Visual Streak!)
            StreakCalendarView(selectedDate: $selectedDate)
                .environmentObject(fastingManager)
                .padding()

            // Lifetime Stats Cards
            TotalStatsView()
                .environmentObject(fastingManager)
                .padding()

            // Progress Chart
            FastingGraphView()
                .environmentObject(fastingManager)
                .padding()

            // Recent Fasts List
            VStack(spacing: 0) {
                Text("Recent Fasts")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.bottom, 10)

                ForEach(fastingManager.fastingHistory.filter { $0.isComplete }) { session in
                    HistoryRowView(session: session)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .contentShape(RoundedRectangle(cornerRadius: 12))
                        .onTapGesture {
                            selectedDate = session.startTime
                        }
                    Divider()
                        .padding(.horizontal)
                }
            }
            .padding(.bottom, 20)
        }
    }

    // Identifiable date wrapper for sheet presentation
    private var selectedIdentifiableDate: Binding<IdentifiableDate?> {
        Binding(
            get: { selectedDate.map { IdentifiableDate(date: $0) } },
            set: { selectedDate = $0?.date }
        )
    }

    private var formattedElapsedTime: String {
        let hours = Int(fastingManager.elapsedTime) / 3600
        let minutes = Int(fastingManager.elapsedTime) / 60 % 60
        let seconds = Int(fastingManager.elapsedTime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private var formattedRemainingTime: String {
        let remaining = fastingManager.remainingTime
        let hours = Int(remaining) / 3600
        let minutes = Int(remaining) / 60 % 60
        let seconds = Int(remaining) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func formatStartTimeDisplay() -> String {
        guard let session = fastingManager.currentSession else { return "" }

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeString = formatter.string(from: session.startTime)

        let calendar = Calendar.current
        if calendar.isDateInToday(session.startTime) {
            return "Today, \(timeString)"
        } else if calendar.isDateInYesterday(session.startTime) {
            return "Yesterday, \(timeString)"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
            return formatter.string(from: session.startTime)
        }
    }

    private func formatGoalEndTimeDisplay() -> String {
        guard let session = fastingManager.currentSession else { return "" }

        // Calculate goal end time: start time + goal hours
        let goalSeconds = fastingManager.fastingGoalHours * 3600
        let goalEndTime = session.startTime.addingTimeInterval(goalSeconds)

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeString = formatter.string(from: goalEndTime)

        let calendar = Calendar.current
        if calendar.isDateInToday(goalEndTime) {
            return "Today, \(timeString)"
        } else if calendar.isDateInTomorrow(goalEndTime) {
            return "Tomorrow, \(timeString)"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
            return formatter.string(from: goalEndTime)
        }
    }

    // Gradient colors for progress ring - transitions through stages
    private var progressGradientColors: [Color] {
        [
            Color(red: 0.2, green: 0.6, blue: 0.9),   // 0%: Blue (start)
            Color(red: 0.2, green: 0.7, blue: 0.8),   // 25%: Teal
            Color(red: 0.2, green: 0.8, blue: 0.7),   // 50%: Cyan
            Color(red: 0.3, green: 0.8, blue: 0.5),   // 75%: Green-teal
            Color(red: 0.4, green: 0.9, blue: 0.4),   // 90%: Vibrant green
            Color(red: 0.3, green: 0.85, blue: 0.3)   // 100%: Celebration green
        ]
    }

    // Dynamic color for "Remaining" text based on progress
    private var progressColor: Color {
        let progress = fastingManager.progress

        if progress < 0.25 {
            return Color(red: 0.2, green: 0.6, blue: 0.9)
        } else if progress < 0.50 {
            return Color(red: 0.2, green: 0.7, blue: 0.8)
        } else if progress < 0.75 {
            return Color(red: 0.2, green: 0.8, blue: 0.7)
        } else if progress < 0.90 {
            return Color(red: 0.3, green: 0.8, blue: 0.5)
        } else if progress < 1.0 {
            return Color(red: 0.4, green: 0.9, blue: 0.4)
        } else {
            return Color(red: 0.3, green: 0.85, blue: 0.3)
        }
    }

    // MARK: - HealthKit Sync Methods

    /// Sync all historical fasting data with HealthKit
    /// Following same pattern as AdvancedView.swift comprehensive sync
    private func syncAllFastingData() {
        AppLogger.info("Starting sync all fasting data from nudge", category: AppLogger.healthKit)
        AppLogger.debug("About to request fasting authorization", category: AppLogger.healthKit)

        HealthKitManager.shared.requestFastingAuthorization { success, error in
            DispatchQueue.main.async {
                if success {
                    AppLogger.info("Fasting authorization granted - syncing all historical data", category: AppLogger.healthKit)

                    // IMPORTANT: Auto-dismiss nudge when user enables HealthKit
                    // Following Apple HIG - don't continue showing permission requests after granted
                    nudgeManager.handleAuthorizationGranted(for: .fasting)

                    // Sync all completed fasting sessions to HealthKit
                    let completedSessions = fastingManager.fastingHistory.filter { $0.isComplete }
                    AppLogger.debug("Found \(completedSessions.count) completed sessions to sync", category: AppLogger.healthKit)

                    if !completedSessions.isEmpty {
                        // Export sessions to HealthKit (same as AdvancedView logic)
                        for session in completedSessions {
                            HealthKitManager.shared.saveFastingSession(session) { success, error in
                                if success {
                                    AppLogger.debug("Synced session: \(session.startTime)", category: AppLogger.healthKit)
                                } else {
                                    AppLogger.error("Failed to sync session", category: AppLogger.healthKit, error: error)
                                }
                            }
                        }
                        // Update sync timestamp
                        HealthKitManager.shared.updateFastingSyncStatus(success: true)
                    }
                } else {
                    AppLogger.info("Fasting authorization denied from nudge", category: AppLogger.healthKit)
                }
            }
        }
    }

    /// Sync future fasting data only with HealthKit
    /// Following same pattern as onboarding "Sync Future Data Only"
    private func syncFutureFastingData() {
        AppLogger.info("Starting sync future fasting data from nudge", category: AppLogger.healthKit)

        HealthKitManager.shared.requestFastingAuthorization { success, error in
            DispatchQueue.main.async {
                if success {
                    AppLogger.info("Fasting authorization granted - syncing future data only", category: AppLogger.healthKit)

                    // IMPORTANT: Auto-dismiss nudge when user enables HealthKit
                    // Following Apple HIG - don't continue showing permission requests after granted
                    nudgeManager.handleAuthorizationGranted(for: .fasting)

                    // Just enable sync for future sessions, don't export historical data
                    // Update sync timestamp to mark sync as enabled
                    HealthKitManager.shared.updateFastingSyncStatus(success: true)
                } else {
                    AppLogger.info("Fasting authorization denied from nudge", category: AppLogger.healthKit)
                }
            }
        }
    }

    // MARK: - Corrected Authorization Flow

    /// Request basic HealthKit authorization first, then show sync options
    /// Following Apple HIG: "Request permission immediately before you need it"
    /// Industry standard: Basic permissions before feature-specific choices
    private func requestBasicHealthKitAccess() {
        AppLogger.info("Requesting basic HealthKit authorization before sync options", category: AppLogger.healthKit)

        // Request basic workout write permission (minimum needed for fasting sync)
        HealthKitManager.shared.requestFastingAuthorization { success, error in
            DispatchQueue.main.async {
                if success {
                    AppLogger.info("Basic HealthKit authorization granted - showing sync options", category: AppLogger.healthKit)
                    // NOW show sync options after getting basic permission
                    showingSyncOptions = true
                } else {
                    AppLogger.info("Basic HealthKit authorization denied", category: AppLogger.healthKit)
                    // Show user-friendly message about HealthKit permissions
                    // Don't show sync options since we don't have basic access
                }
            }
        }
    }
}