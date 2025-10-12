import SwiftUI

struct TotalStatsView: View {
    @EnvironmentObject var fastingManager: FastingManager

    var body: some View {
        let completedSessions = fastingManager.fastingHistory.filter { $0.isComplete }
        // Count all days with ≥14 hours OR goal met
        let totalDays = completedSessions.filter { $0.duration >= 14 * 3600 || $0.metGoal }.count
        let totalDaysToGoal = completedSessions.filter { $0.metGoal }.count
        let totalHours = completedSessions.reduce(0.0) { $0 + $1.duration / 3600 }
        let longestStreak = fastingManager.longestStreak

        VStack(spacing: 16) {
            // First row
            HStack(spacing: 16) {
                // Total Days (≥14h or goal met)
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.title2)
                        .foregroundColor(Color("FLSecondary"))
                    Text("\(totalDays)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Lifetime Days Fasted")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)

                // Total Hours
                VStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .foregroundColor(Color("FLSuccess"))
                    Text("\(Int(totalHours))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Lifetime Hours Fasted")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
            }

            // Second row
            HStack(spacing: 16) {
                // Days to Goal
                VStack(spacing: 8) {
                    Image(systemName: "target")
                        .font(.title2)
                        .foregroundColor(Color.orange)
                    Text("\(totalDaysToGoal)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Lifetime Days Fasted to Goal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)

                // Longest Streak
                VStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundColor(Color.orange)
                    Text("\(longestStreak)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Longest Lifetime Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
            }

            // Third row - Average Hours Per Fast (centered)
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .font(.title2)
                        .foregroundColor(Color.purple)
                    Text(averageHoursText)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Average Hours Per Fast")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                Spacer()
            }
        }
    }

    // Calculate average hours per fast session
    private var averageHoursText: String {
        let completedSessions = fastingManager.fastingHistory.filter { $0.isComplete }
        let totalDays = completedSessions.filter { $0.duration >= 14 * 3600 || $0.metGoal }.count
        let totalHours = completedSessions.reduce(0.0) { $0 + $1.duration / 3600 }

        // Avoid division by zero
        guard totalDays > 0 else { return "0" }

        let average = totalHours / Double(totalDays)
        return String(format: "%.1f", average)
    }
}