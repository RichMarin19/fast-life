import SwiftUI

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
                    Color(UIColor.secondarySystemBackground),  // Soft blue-white
                    Color(UIColor.secondarySystemBackground)   // Soft lavender
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
                            .foregroundColor(Color("FLPrimary"))
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
                                .foregroundColor(Color("FLSecondary"))

                            Text("Total Duration")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(hours)")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(Color("FLPrimary"))
                                Text("h")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                Text("\(minutes)")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(Color("FLPrimary"))
                                Text("m")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: Color("FLPrimary").opacity(0.1), radius: 15, y: 5)
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
                                                .foregroundColor(Color("FLSuccess"))
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
                                            .foregroundColor(Color("FLPrimary"))
                                            .font(.title2)
                                    }
                                    .padding()
                                    .background(Color("FLSuccess").opacity(0.1))
                                    .cornerRadius(8)
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
                                                .foregroundColor(Color.red)
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
                                            .foregroundColor(Color("FLPrimary"))
                                            .font(.title2)
                                    }
                                    .padding()
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(8)
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
                                    .foregroundColor(Color("FLPrimary"))
                                    .font(.caption)
                                Text("Tap to adjust your fasting start and end times")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 4)
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(8)
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
                                RoundedRectangle(cornerRadius: 12)
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
                                        Color("FLSecondary"),
                                        Color("FLPrimary")
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color("FLPrimary").opacity(0.3), radius: 8, y: 4)
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