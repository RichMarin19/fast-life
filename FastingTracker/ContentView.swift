import SwiftUI

struct ContentView: View {
    @EnvironmentObject var fastingManager: FastingManager
    @State private var showingGoalSettings = false
    @State private var showingStopConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var showingEditTimes = false
    @State private var showingEditStartTime = false
    @State private var selectedStage: FastingStage?

    @State private var selectedDate: Date?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Spacer()
                        .frame(height: 30)

                    // Fast LIFe Title
                HStack(spacing: 0) {
                    Text("Fast L")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    Text("IF")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                    Text("e")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(.cyan)
                }

                Spacer()
                    .frame(height: 50)

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
                    .cornerRadius(20)
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
                            .foregroundColor(.green)
                        + Text("\(Int(fastingManager.fastingGoalHours))h")
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundColor(.green))

                        // Gear icon visual indicator that this is editable
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
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
                .buttonStyle(.plain)
                .padding(.bottom, 15)

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
                        .background(Color(red: 0.9, green: 0.95, blue: 0.7))
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
                            .cornerRadius(15)
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
                            .background(Color.green)
                            .cornerRadius(15)
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
                                .contentShape(Rectangle())
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
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .onAppear {
                // Check if fasting goal needs to be set
                if fastingManager.fastingGoalHours == 0 {
                    showingGoalSettings = true
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
}

// MARK: - Stop Fast Confirmation View

struct StopFastConfirmationView: View {
    let onEditTimes: () -> Void
    let onStop: () -> Void
    let onDelete: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 30)

            Text("Stop Fast?")
                .font(.title2)
                .fontWeight(.bold)

            Text("Do you want to edit the start/end times\nbefore stopping?")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Spacer()
                .frame(height: 10)

            VStack(spacing: 12) {
                // Edit Times Button
                Button(action: onEditTimes) {
                    Text("Edit Times")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }

                // Stop Button - GREEN, BOLD, LARGER
                Button(action: onStop) {
                    Text("Stop")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }

                // Delete Button
                Button(action: onDelete) {
                    Text("Delete")
                        .font(.headline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                }

                // Cancel Button
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 30)

            Spacer()
        }
    }
}

// MARK: - Goal Settings View

struct GoalSettingsView: View {
    @EnvironmentObject var fastingManager: FastingManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedHours: Double

    init() {
        _selectedHours = State(initialValue: 16)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Set Your Fasting Goal")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 40)

                VStack(spacing: 10) {
                    Text("\(Int(selectedHours)) hours")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)

                    Slider(value: $selectedHours, in: 8...48, step: 1)
                        .padding(.horizontal, 40)
                        .accentColor(.blue)

                    HStack {
                        Text("8h")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("48h")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 40)
                }
                .padding(.vertical, 30)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Popular Goals:")
                        .font(.headline)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            GoalPresetButton(hours: 12, selectedHours: $selectedHours)
                            GoalPresetButton(hours: 16, selectedHours: $selectedHours)
                            GoalPresetButton(hours: 18, selectedHours: $selectedHours)
                            GoalPresetButton(hours: 20, selectedHours: $selectedHours)
                            GoalPresetButton(hours: 24, selectedHours: $selectedHours)
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer()

                Button(action: {
                    // Round to ensure clean whole number hours
                    fastingManager.setFastingGoal(hours: selectedHours.rounded())
                    dismiss()
                }) {
                    Text("Save Goal")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(15)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                selectedHours = fastingManager.fastingGoalHours
            }
        }
    }
}

struct GoalPresetButton: View {
    let hours: Double
    @Binding var selectedHours: Double

    var body: some View {
        Button(action: {
            selectedHours = hours
        }) {
            Text("\(Int(hours))h")
                .font(.headline)
                .foregroundColor(selectedHours == hours ? .white : .blue)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(selectedHours == hours ? Color.blue : Color.blue.opacity(0.1))
                .cornerRadius(10)
        }
    }
}

// MARK: - Edit Fast Times View

struct EditFastTimesView: View {
    @EnvironmentObject var fastingManager: FastingManager
    @Environment(\.dismiss) var dismiss
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var editingStart = false
    @State private var editingEnd = false

    init() {
        let now = Date()
        _startTime = State(initialValue: now)
        _endTime = State(initialValue: now)
    }

    var body: some View {
        ZStack {
            // Soft wellness gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),  // Soft blue-white
                    Color(red: 0.98, green: 0.95, blue: 1.0)   // Soft lavender
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.9))
                    }
                    Spacer()
                    Text("Edit Fast")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    // Invisible spacer for centering
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .opacity(0)
                }
                .padding()
                .background(Color.white.opacity(0.9))

                ScrollView {
                    VStack(spacing: 24) {
                        // Total Duration Card
                        VStack(spacing: 16) {
                            Image(systemName: "timer")
                                .font(.system(size: 40))
                                .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.95))

                            Text("Total Duration")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(hours)")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 0.3, green: 0.5, blue: 0.85))
                                Text("h")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                Text("\(minutes)")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 0.3, green: 0.5, blue: 0.85))
                                Text("m")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .shadow(color: Color(red: 0.4, green: 0.5, blue: 0.9).opacity(0.1), radius: 15, y: 5)
                        )
                        .padding(.top, 16)

                        // Time Adjustment Card
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Adjust Times")
                                .font(.headline)
                                .foregroundColor(.primary)

                            // Start time
                            VStack(spacing: 12) {
                                Button(action: {
                                    withAnimation { editingStart.toggle() }
                                    editingEnd = false
                                }) {
                                    HStack {
                                        HStack(spacing: 12) {
                                            Image(systemName: "play.circle.fill")
                                                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                                                .font(.title3)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Start Time")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                                Text(formatTimeDisplay(startTime))
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                            }
                                        }
                                        Spacer()
                                        Image(systemName: editingStart ? "chevron.up.circle.fill" : "chevron.down.circle")
                                            .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.9))
                                            .font(.title2)
                                    }
                                    .padding()
                                    .background(Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.1))
                                    .cornerRadius(12)
                                }

                                if editingStart {
                                    DatePicker(
                                        "",
                                        selection: $startTime,
                                        displayedComponents: [.date, .hourAndMinute]
                                    )
                                    .datePickerStyle(.graphical)
                                    .labelsHidden()
                                    .transition(.opacity)
                                }
                            }

                            // End time
                            VStack(spacing: 12) {
                                Button(action: {
                                    withAnimation { editingEnd.toggle() }
                                    editingStart = false
                                }) {
                                    HStack {
                                        HStack(spacing: 12) {
                                            Image(systemName: "stop.circle.fill")
                                                .foregroundColor(Color(red: 0.9, green: 0.5, blue: 0.5))
                                                .font(.title3)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("End Time")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                                Text(formatTimeDisplay(endTime))
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                            }
                                        }
                                        Spacer()
                                        Image(systemName: editingEnd ? "chevron.up.circle.fill" : "chevron.down.circle")
                                            .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.9))
                                            .font(.title2)
                                    }
                                    .padding()
                                    .background(Color(red: 0.9, green: 0.5, blue: 0.5).opacity(0.1))
                                    .cornerRadius(12)
                                }

                                if editingEnd {
                                    DatePicker(
                                        "",
                                        selection: $endTime,
                                        displayedComponents: [.date, .hourAndMinute]
                                    )
                                    .datePickerStyle(.graphical)
                                    .labelsHidden()
                                    .transition(.opacity)
                                }
                            }

                            HStack(spacing: 6) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.9))
                                    .font(.caption)
                                Text("Tap to adjust your fasting start and end times")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 4)
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)

                        Spacer()
                            .frame(height: 180)
                    }
                    .padding(.horizontal)
                }
                .scrollIndicators(.hidden)

                // Bottom buttons
                HStack(spacing: 16) {
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }

                    Button(action: {
                        fastingManager.stopFastWithCustomTimes(startTime: startTime, endTime: endTime)
                        dismiss()
                    }) {
                        Text("Save & Stop")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.4, green: 0.7, blue: 0.95),
                                        Color(red: 0.3, green: 0.5, blue: 0.85)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color(red: 0.4, green: 0.5, blue: 0.9).opacity(0.3), radius: 8, y: 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white)
            }
        }
        .onAppear {
            if let session = fastingManager.currentSession {
                startTime = session.startTime
                endTime = Date()
            }
        }
    }

    private var hours: Int {
        let duration = endTime.timeIntervalSince(startTime)
        return Int(duration) / 3600
    }

    private var minutes: Int {
        let duration = endTime.timeIntervalSince(startTime)
        return Int(duration) / 60 % 60
    }

    private func formatTimeDisplay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeString = formatter.string(from: date)

        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today, \(timeString)"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday, \(timeString)"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Edit Start Time View

struct EditStartTimeView: View {
    @EnvironmentObject var fastingManager: FastingManager
    @Environment(\.dismiss) var dismiss
    @State private var startTime: Date
    @State private var editingTime = false
    @State private var editingDuration = false
    @State private var durationHours: Int = 0
    @State private var durationMinutes: Int = 0

    init() {
        _startTime = State(initialValue: Date())
    }

    var body: some View {
        ZStack {
            // Soft wellness gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),  // Soft blue-white
                    Color(red: 0.98, green: 0.95, blue: 1.0)   // Soft lavender
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.9))
                    }
                    Spacer()
                    Text("Edit Start Time")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    // Invisible spacer for centering
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .opacity(0)
                }
                .padding()
                .background(Color.white.opacity(0.9))

                ScrollView {
                    VStack(spacing: 24) {
                        // Current Duration Card - TAPPABLE
                        Button(action: {
                            withAnimation {
                                editingDuration.toggle()
                                if editingDuration {
                                    editingTime = false
                                }
                            }
                        }) {
                            VStack(spacing: 16) {
                                Image(systemName: editingDuration ? "pencil.circle.fill" : "clock.arrow.circlepath")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.95))

                                Text(editingDuration ? "Set Duration" : "Current Duration")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text("\(currentHours)")
                                        .font(.system(size: 48, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(red: 0.3, green: 0.5, blue: 0.85))
                                    Text("h")
                                        .font(.title2)
                                        .foregroundColor(.secondary)
                                    Text("\(currentMinutes)")
                                        .font(.system(size: 48, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(red: 0.3, green: 0.5, blue: 0.85))
                                    Text("m")
                                        .font(.title2)
                                        .foregroundColor(.secondary)
                                }

                                // Tap to edit hint
                                HStack(spacing: 6) {
                                    Image(systemName: editingDuration ? "checkmark.circle.fill" : "hand.tap.fill")
                                        .font(.caption)
                                    Text(editingDuration ? "Tap to confirm" : "Tap to edit duration")
                                        .font(.caption)
                                }
                                .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.9))
                                .padding(.top, 4)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white)
                                    .shadow(color: Color(red: 0.4, green: 0.5, blue: 0.9).opacity(editingDuration ? 0.2 : 0.1), radius: 15, y: 5)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .strokeBorder(
                                        Color(red: 0.4, green: 0.5, blue: 0.9).opacity(editingDuration ? 0.5 : 0),
                                        lineWidth: 2
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 16)

                        // Duration Pickers - Shown when editing duration
                        if editingDuration {
                            VStack(spacing: 20) {
                                Text("Set Fasting Duration")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                HStack(spacing: 20) {
                                    // Hours Picker
                                    VStack(spacing: 8) {
                                        Text("Hours")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)

                                        Picker("Hours", selection: $durationHours) {
                                            ForEach(0..<49) { hour in
                                                Text("\(hour)").tag(hour)
                                            }
                                        }
                                        .pickerStyle(.wheel)
                                        .frame(width: 80, height: 120)
                                        .clipped()
                                    }

                                    // Minutes Picker
                                    VStack(spacing: 8) {
                                        Text("Minutes")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)

                                        Picker("Minutes", selection: $durationMinutes) {
                                            ForEach(0..<60) { minute in
                                                Text("\(minute)").tag(minute)
                                            }
                                        }
                                        .pickerStyle(.wheel)
                                        .frame(width: 80, height: 120)
                                        .clipped()
                                    }
                                }
                                .frame(maxWidth: .infinity)

                                HStack(spacing: 6) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.9))
                                        .font(.caption)
                                    Text("Start time will be calculated automatically")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, 4)
                            }
                            .padding(20)
                            .background(Color.white)
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }

                        // OR divider
                        if !editingDuration {
                            HStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 1)

                                Text("OR")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 12)

                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 1)
                            }
                            .padding(.vertical, 8)
                        }

                        // Time Adjustment Card - Hidden when editing duration
                        if !editingDuration {
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Adjust Start Time")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                // Start time
                                VStack(spacing: 12) {
                                    Button(action: {
                                        withAnimation { editingTime.toggle() }
                                    }) {
                                        HStack {
                                            HStack(spacing: 12) {
                                                Image(systemName: "play.circle.fill")
                                                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                                                    .font(.title3)
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text("Start Time")
                                                        .font(.subheadline)
                                                        .foregroundColor(.secondary)
                                                    Text(formatTimeDisplay(startTime))
                                                        .font(.headline)
                                                        .foregroundColor(.primary)
                                                }
                                            }
                                            Spacer()
                                            Image(systemName: editingTime ? "chevron.up.circle.fill" : "chevron.down.circle")
                                                .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.9))
                                                .font(.title2)
                                        }
                                        .padding()
                                        .background(Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.1))
                                        .cornerRadius(12)
                                    }

                                    if editingTime {
                                        DatePicker(
                                            "",
                                            selection: $startTime,
                                            in: ...Date(),
                                            displayedComponents: [.date, .hourAndMinute]
                                        )
                                        .datePickerStyle(.graphical)
                                        .labelsHidden()
                                        .transition(.opacity)
                                    }
                                }

                                HStack(spacing: 6) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.9))
                                        .font(.caption)
                                    Text("Choose exact date and time when fast started")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, 4)
                            }
                            .padding(20)
                            .background(Color.white)
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }

                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(.horizontal)
                }
                .scrollIndicators(.visible)

                // Bottom buttons
                HStack(spacing: 16) {
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }

                    Button(action: {
                        // Calculate start time based on mode
                        if editingDuration {
                            // Calculate start time from duration
                            let totalSeconds = TimeInterval(durationHours * 3600 + durationMinutes * 60)
                            startTime = Date().addingTimeInterval(-totalSeconds)
                        }

                        // Update the start time without stopping the fast
                        if var session = fastingManager.currentSession {
                            session.startTime = startTime
                            fastingManager.currentSession = session

                            // Persist the updated session to UserDefaults
                            fastingManager.saveCurrentSession()

                            // Reschedule notifications with updated start time
                            NotificationManager.shared.scheduleGoalNotification(
                                for: session,
                                goalHours: fastingManager.fastingGoalHours,
                                currentStreak: fastingManager.currentStreak,
                                longestStreak: fastingManager.longestStreak
                            )
                        }
                        dismiss()
                    }) {
                        Text("Save")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.4, green: 0.7, blue: 0.95),
                                        Color(red: 0.3, green: 0.5, blue: 0.85)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color(red: 0.4, green: 0.5, blue: 0.9).opacity(0.3), radius: 8, y: 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white)
            }
        }
        .onAppear {
            if let session = fastingManager.currentSession {
                startTime = session.startTime
                // Initialize duration pickers with current duration
                let duration = Date().timeIntervalSince(session.startTime)
                durationHours = Int(duration) / 3600
                durationMinutes = Int(duration) / 60 % 60
            }
        }
        .onChange(of: durationHours) { _ in
            updateStartTimeFromDuration()
        }
        .onChange(of: durationMinutes) { _ in
            updateStartTimeFromDuration()
        }
    }

    private var currentHours: Int {
        let duration = Date().timeIntervalSince(startTime)
        return Int(duration) / 3600
    }

    private var currentMinutes: Int {
        let duration = Date().timeIntervalSince(startTime)
        return Int(duration) / 60 % 60
    }

    private func updateStartTimeFromDuration() {
        if editingDuration {
            let totalSeconds = TimeInterval(durationHours * 3600 + durationMinutes * 60)
            startTime = Date().addingTimeInterval(-totalSeconds)
        }
    }

    private func formatTimeDisplay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeString = formatter.string(from: date)

        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today, \(timeString)"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday, \(timeString)"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
            return formatter.string(from: date)
        }
    }
}
