import SwiftUI

struct AddEditFastView: View {
    let date: Date
    @EnvironmentObject var fastingManager: FastingManager
    @Environment(\.dismiss) var dismiss

    @State private var hours: Int = 16
    @State private var minutes: Int = 0
    @State private var goalHours: Double = 16
    @State private var startTime: Date
    @State private var showingDeleteAlert = false
    @State private var customGoalText: String = ""
    @State private var isCustomGoal: Bool = false
    @FocusState private var isCustomGoalFocused: Bool

    private var existingSession: FastingSession?

    init(date: Date, fastingManager: FastingManager) {
        self.date = date

        // Check if there's an existing fast for this date
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        self.existingSession = fastingManager.fastingHistory.first(where: {
            calendar.startOfDay(for: $0.startTime) == targetDay
        })

        // Initialize with existing data or defaults
        if let existing = existingSession {
            _startTime = State(initialValue: existing.startTime)
            _hours = State(initialValue: Int(existing.duration / 3600))
            _minutes = State(initialValue: Int(existing.duration / 60) % 60)
            _goalHours = State(initialValue: existing.goalHours ?? 16)
        } else {
            // Default to 6 PM on the selected date
            let startOfDay = calendar.startOfDay(for: date)
            let defaultStart = calendar.date(byAdding: .hour, value: 18, to: startOfDay) ?? date
            _startTime = State(initialValue: defaultStart)
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Text(existingSession == nil ? "Add Fast" : "Edit Fast")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(formattedDate)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)

                    // Start Time Picker
                    VStack(spacing: 12) {
                        Text("Start Time")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        DatePicker("", selection: $startTime, displayedComponents: [.hourAndMinute])
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                    .padding(.horizontal)

                    // Duration Display
                    VStack(spacing: 16) {
                        Text("Fast Duration")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("\(hours)h \(minutes)m")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundColor(durationColor)
                    }

                    // Duration Pickers
                    HStack(spacing: 40) {
                        // Hours Picker
                        VStack(spacing: 12) {
                            Text("Hours")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Picker("Hours", selection: $hours) {
                                ForEach(0..<49) { hour in
                                    Text("\(hour)").tag(hour)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100, height: 150)
                        }

                        // Minutes Picker
                        VStack(spacing: 12) {
                            Text("Minutes")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Picker("Minutes", selection: $minutes) {
                                ForEach(0..<60) { minute in
                                    Text("\(minute)").tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100, height: 150)
                        }
                    }
                    .padding()

                    Divider()
                        .padding(.horizontal)

                    // Goal Picker
                    VStack(spacing: 20) {
                        VStack(spacing: 8) {
                            Text("Goal")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            Text("\(Int(goalHours)) hours")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(Color("FLSecondary"))
                        }

                        VStack(spacing: 12) {
                            HStack(spacing: 6) {
                                ForEach([8.0, 12.0, 14.0, 16.0, 18.0, 20.0, 24.0, 36.0, 48.0], id: \.self) { goal in
                                    Button(action: {
                                        isCustomGoal = false
                                        goalHours = goal
                                        customGoalText = ""  // Clear custom text when selecting preset
                                    }) {
                                        Text("\(Int(goal))h")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(goalHours == goal && !isCustomGoal ? .white : Color("FLSecondary"))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(goalHours == goal && !isCustomGoal ? Color("FLSecondary") : Color(UIColor.secondarySystemGroupedBackground))
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(goalHours == goal && !isCustomGoal ? Color.clear : Color("FLSecondary").opacity(0.3), lineWidth: 1)
                                            )
                                    }
                                }
                            }

                            Button(action: {
                                // Always start with empty text field for custom input
                                customGoalText = ""
                                goalHours = 0  // Reset display to 0 when entering custom mode
                                isCustomGoal = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isCustomGoalFocused = true
                                }
                            }) {
                                Text("Custom")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(isCustomGoal ? .white : Color("FLSecondary"))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(isCustomGoal ? Color("FLSecondary") : Color(UIColor.secondarySystemGroupedBackground))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(isCustomGoal ? Color.clear : Color("FLSecondary").opacity(0.3), lineWidth: 1)
                                    )
                            }

                            if isCustomGoal {
                                HStack(spacing: 8) {
                                    TextField("Enter goal", text: $customGoalText)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.center)
                                        .font(.system(size: 20, weight: .semibold))
                                        .focused($isCustomGoalFocused)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .background(Color(UIColor.secondarySystemGroupedBackground))
                                        .cornerRadius(8)
                                        .onChange(of: customGoalText) { _, newValue in
                                            if let value = Double(newValue), value > 0 {
                                                goalHours = value
                                            }
                                        }
                                        .toolbar {
                                            ToolbarItemGroup(placement: .keyboard) {
                                                Spacer()
                                                Button("Done") {
                                                    isCustomGoalFocused = false
                                                }
                                                .foregroundColor(Color("FLSecondary"))
                                                .fontWeight(.semibold)
                                            }
                                        }
                                    Text("hours")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)

                    // Save Button
                    Button(action: saveFast) {
                        Text("Save Fast")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color("FLSecondary"), Color("FLSecondary")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    .disabled(hours == 0 && minutes == 0)
                    .opacity((hours == 0 && minutes == 0) ? 0.5 : 1.0)

                    // Delete Button (only show if editing existing fast)
                    if existingSession != nil {
                        Button(action: { showingDeleteAlert = true }) {
                            Text("Delete Fast")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                    }

                    Spacer().frame(height: 40)
                }
            }
            .background(Color.gray.opacity(0.05).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            goalHours = fastingManager.fastingGoalHours
            // Check if current goal is a preset value or custom
            let presetGoals = [8.0, 12.0, 14.0, 16.0, 18.0, 20.0, 24.0, 36.0, 48.0]
            if !presetGoals.contains(goalHours) {
                isCustomGoal = true
                customGoalText = String(Int(goalHours))
            }
        }
        .alert("Delete Fast", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteFast()
            }
        } message: {
            Text("Are you sure you want to delete this fast? This action cannot be undone.")
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    private var totalDurationHours: Double {
        Double(hours) + Double(minutes) / 60.0
    }

    private var durationColor: Color {
        if totalDurationHours >= goalHours {
            return Color("FLSuccess")
        } else {
            return Color.orange
        }
    }

    private func saveFast() {
        guard hours > 0 || minutes > 0 else { return }

        // Calculate end time based on start time and duration
        let totalSeconds = TimeInterval(hours * 3600 + minutes * 60)
        let endTime = startTime.addingTimeInterval(totalSeconds)

        fastingManager.addManualFast(startTime: startTime, endTime: endTime, goalHours: goalHours)
        dismiss()
    }

    private func deleteFast() {
        fastingManager.deleteFast(for: date)
        dismiss()
    }
}

// Identifiable wrapper for sheet presentation
