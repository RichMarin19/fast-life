import Charts
import SwiftUI

// MARK: - Mood Tracking View

// Refactored from 488 → ~88 lines (82% reduction)
// Following Apple MVVM patterns and Phase 3a/3b component extraction lessons

struct MoodTrackingView: View {
    @StateObject private var moodManager = MoodManager()
    @State private var showingAddEntry = false
    @State private var selectedTimeRange = 7

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer()
                    .frame(height: 20)

                // Mood & Energy Circles
                MoodEnergyCirclesView(moodManager: self.moodManager)

                // 7-Day Averages
                if let avgMood = moodManager.averageMoodLevel,
                   let avgEnergy = moodManager.averageEnergyLevel {
                    HStack(spacing: 50) {
                        VStack(spacing: 8) {
                            Text("7-Day Avg Mood")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f", avgMood))
                                .font(.title2)
                                .fontWeight(.semibold)
                        }

                        VStack(spacing: 8) {
                            Text("7-Day Avg Energy")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f", avgEnergy))
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.bottom, 10)
                }

                // Graphs Section
                MoodEnergyGraphsView(moodManager: self.moodManager, selectedTimeRange: self.$selectedTimeRange)
                    .padding(.horizontal, 20)

                // Recent Entries
                if !self.moodManager.moodEntries.isEmpty {
                    VStack(spacing: 12) {
                        Text("Recent Entries")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 40)

                        ForEach(Array(self.moodManager.moodEntries.prefix(5))) { entry in
                            MoodEntryRow(entry: entry, onDelete: {
                                self.moodManager.deleteMoodEntry(entry)
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
        .navigationTitle("Mood & Energy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    self.showingAddEntry = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.orange)
                }
            }
        }
        .sheet(isPresented: self.$showingAddEntry) {
            AddMoodEntryView(moodManager: self.moodManager)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MoodTrackingView()
    }
}
