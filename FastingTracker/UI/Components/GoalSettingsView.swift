import SwiftUI

struct GoalSettingsView: View {
    @EnvironmentObject var fastingManager: FastingManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedHours: Int = 16
    @State private var selectedMinutes: Int = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Set Your Fasting Goal")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 40)

                VStack(spacing: 10) {
                    Text(formatGoalTime(hours: selectedHours, minutes: selectedMinutes))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)

                    // Apple-standard time duration picker
                    HStack(spacing: 20) {
                        VStack {
                            Text("Hours")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Picker("Hours", selection: $selectedHours) {
                                ForEach(8...48, id: \.self) { hour in
                                    Text("\(hour)").tag(hour)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80, height: 120)
                        }

                        VStack {
                            Text("Minutes")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Picker("Minutes", selection: $selectedMinutes) {
                                ForEach([0, 15, 30, 45], id: \.self) { minute in
                                    Text("\(minute)").tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80, height: 120)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 30)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Popular Goals:")
                        .font(.headline)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            GoalPresetButton(hours: 12, selectedHours: $selectedHours, selectedMinutes: $selectedMinutes)
                            GoalPresetButton(hours: 16, selectedHours: $selectedHours, selectedMinutes: $selectedMinutes)
                            GoalPresetButton(hours: 18, selectedHours: $selectedHours, selectedMinutes: $selectedMinutes)
                            GoalPresetButton(hours: 20, selectedHours: $selectedHours, selectedMinutes: $selectedMinutes)
                            GoalPresetButton(hours: 24, selectedHours: $selectedHours, selectedMinutes: $selectedMinutes)
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer()

                Button(action: {
                    // Convert hours and minutes to total hours
                    let totalHours = Double(selectedHours) + (Double(selectedMinutes) / 60.0)
                    fastingManager.setFastingGoal(hours: totalHours)
                    dismiss()
                }) {
                    Text("Save Goal")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
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
                // Load current goal from FastingManager, converting to hours and minutes
                let totalHours = fastingManager.fastingGoalHours
                selectedHours = Int(totalHours)
                selectedMinutes = Int((totalHours - Double(selectedHours)) * 60.0)
            }
        }
    }

    private func formatGoalTime(hours: Int, minutes: Int) -> String {
        if minutes == 0 {
            return "\(hours)h"
        } else {
            return "\(hours)h \(minutes)m"
        }
    }
}

struct GoalPresetButton: View {
    let hours: Int
    @Binding var selectedHours: Int
    @Binding var selectedMinutes: Int

    var body: some View {
        Button(action: {
            selectedHours = hours
            selectedMinutes = 0  // Reset minutes for popular goals
        }) {
            Text("\(hours)h")
                .font(.headline)
                .foregroundColor(isSelected ? .white : .blue)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
                .cornerRadius(10)
        }
    }

    private var isSelected: Bool {
        selectedHours == hours && selectedMinutes == 0
    }
}