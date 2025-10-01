import SwiftUI

struct ContentView: View {
    @EnvironmentObject var fastingManager: FastingManager
    @State private var showingGoalSettings = false
    @State private var showingStopConfirmation = false
    @State private var showingEditTimes = false

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()

                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 20)
                        .frame(width: 250, height: 250)

                    Circle()
                        .trim(from: 0, to: fastingManager.progress)
                        .stroke(fastingManager.isActive ? Color.blue : Color.gray,
                               style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .frame(width: 250, height: 250)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: fastingManager.progress)

                    VStack(spacing: 12) {
                        Image(systemName: "clock")
                            .font(.system(size: 40))
                            .foregroundColor(fastingManager.isActive ? .blue : .gray)

                        // Elapsed Time
                        VStack(spacing: 4) {
                            Text("Fasting")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formattedElapsedTime)
                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                        }

                        // Countdown Time
                        VStack(spacing: 4) {
                            Text("Remaining")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formattedRemainingTime)
                                .font(.system(size: 28, weight: .semibold, design: .monospaced))
                                .foregroundColor(fastingManager.remainingTime > 0 ? .blue : .green)
                        }
                    }
                }

                // Progress Percentage
                Text("\(Int(fastingManager.progress * 100))%")
                    .font(.title2)
                    .foregroundColor(.secondary)

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

                // Goal Display and Settings
                HStack {
                    Text("Goal: \(Int(fastingManager.fastingGoalHours))h")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Button(action: {
                        showingGoalSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.blue)
                    }
                    .disabled(fastingManager.isActive)
                }

                Spacer()

                // Start/Stop Button
                Button(action: {
                    if fastingManager.isActive {
                        showingStopConfirmation = true
                    } else {
                        fastingManager.startFast()
                    }
                }) {
                    Text(fastingManager.isActive ? "Stop Fast" : "Start Fast")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(fastingManager.isActive ? Color.red : Color.green)
                        .cornerRadius(15)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            .navigationTitle("Fast lIFe")
            .sheet(isPresented: $showingGoalSettings) {
                GoalSettingsView()
                    .environmentObject(fastingManager)
            }
            .sheet(isPresented: $showingEditTimes) {
                EditFastTimesView()
                    .environmentObject(fastingManager)
            }
            .alert("Stop Fast?", isPresented: $showingStopConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Edit Times", role: .none) {
                    showingEditTimes = true
                }
                Button("Stop", role: .destructive) {
                    fastingManager.stopFast()
                }
            } message: {
                Text("Do you want to edit the start/end times before stopping?")
            }
        }
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
                    fastingManager.setFastingGoal(hours: selectedHours)
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
