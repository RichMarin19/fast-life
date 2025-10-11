import Charts
import SwiftUI

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

// MARK: - Mood & Energy Circles

struct MoodEnergyCirclesView: View {
    @ObservedObject var moodManager: MoodManager

    var body: some View {
        HStack(spacing: 40) {
            // Mood Circle
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 20)
                        .frame(width: 140, height: 140)

                    if let latest = moodManager.latestEntry {
                        let progress = Double(latest.moodLevel) / 10.0
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                latest.moodColor,
                                style: StrokeStyle(lineWidth: 20, lineCap: .round)
                            )
                            .frame(width: 140, height: 140)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.5), value: progress)

                        VStack(spacing: 4) {
                            Text(latest.moodEmoji)
                                .font(.system(size: 36))
                            Text("\(latest.moodLevel)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                        }
                    } else {
                        VStack(spacing: 4) {
                            Text("😐")
                                .font(.system(size: 36))
                            Text("--")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Text("Mood")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }

            // Energy Circle
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 20)
                        .frame(width: 140, height: 140)

                    if let latest = moodManager.latestEntry {
                        let progress = Double(latest.energyLevel) / 10.0
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                latest.energyColor,
                                style: StrokeStyle(lineWidth: 20, lineCap: .round)
                            )
                            .frame(width: 140, height: 140)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.5), value: progress)

                        VStack(spacing: 4) {
                            Text(latest.energyEmoji)
                                .font(.system(size: 36))
                            Text("\(latest.energyLevel)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                        }
                    } else {
                        VStack(spacing: 4) {
                            Text("⚡")
                                .font(.system(size: 36))
                            Text("--")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Text("Energy")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Mood & Energy Graphs

struct MoodEnergyGraphsView: View {
    @ObservedObject var moodManager: MoodManager
    @Binding var selectedTimeRange: Int

    var body: some View {
        VStack(spacing: 20) {
            // Time Range Picker
            Picker("Range", selection: self.$selectedTimeRange) {
                Text("7 Days").tag(7)
                Text("30 Days").tag(30)
                Text("90 Days").tag(90)
            }
            .pickerStyle(.segmented)

            // Mood Graph
            VStack(alignment: .leading, spacing: 12) {
                Text("Mood Trend")
                    .font(.headline)
                    .padding(.horizontal, 4)

                if #available(iOS 16.0, *) {
                    let entries = moodManager.entriesForRange(days: selectedTimeRange)
                    if !entries.isEmpty {
                        Chart(entries) { entry in
                            LineMark(
                                x: .value("Date", entry.date),
                                y: .value("Mood", entry.moodLevel)
                            )
                            .foregroundStyle(.orange)
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Date", entry.date),
                                y: .value("Mood", entry.moodLevel)
                            )
                            .foregroundStyle(.orange)
                        }
                        .chartYScale(domain: 0 ... 10)
                        .frame(height: 200)
                    } else {
                        Text("No mood data for this period")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .frame(height: 200)
                    }
                } else {
                    Text("Charts require iOS 16 or later")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .frame(height: 200)
                }
            }

            // Energy Graph
            VStack(alignment: .leading, spacing: 12) {
                Text("Energy Trend")
                    .font(.headline)
                    .padding(.horizontal, 4)

                if #available(iOS 16.0, *) {
                    let entries = moodManager.entriesForRange(days: selectedTimeRange)
                    if !entries.isEmpty {
                        Chart(entries) { entry in
                            LineMark(
                                x: .value("Date", entry.date),
                                y: .value("Energy", entry.energyLevel)
                            )
                            .foregroundStyle(Color("FLPrimary"))
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Date", entry.date),
                                y: .value("Energy", entry.energyLevel)
                            )
                            .foregroundStyle(Color("FLPrimary"))
                        }
                        .chartYScale(domain: 0 ... 10)
                        .frame(height: 200)
                    } else {
                        Text("No energy data for this period")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .frame(height: 200)
                    }
                } else {
                    Text("Charts require iOS 16 or later")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .frame(height: 200)
                }
            }
        }
    }
}

// MARK: - Mood Entry Row

struct MoodEntryRow: View {
    let entry: MoodEntry
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Mood & Energy Emojis
            VStack(spacing: 4) {
                Text(self.entry.moodEmoji)
                    .font(.system(size: 24))
                Text(self.entry.energyEmoji)
                    .font(.system(size: 20))
            }
            .frame(width: 50, height: 50)
            .background(Color.orange.opacity(0.15))
            .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(self.formatDate(self.entry.date))
                    .font(.subheadline)
                    .fontWeight(.medium)
                if let notes = entry.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text("\(self.entry.moodDescription) mood")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Text("M:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(self.entry.moodLevel)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                HStack(spacing: 4) {
                    Text("E:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(self.entry.energyLevel)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }

            Button(action: self.onDelete) {
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
        formatter.dateFormat = "MMM d, yyyy h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Add Mood Entry View

struct AddMoodEntryView: View {
    @ObservedObject var moodManager: MoodManager
    @Environment(\.dismiss) var dismiss

    @State private var moodLevel: Double = 5
    @State private var energyLevel: Double = 5
    @State private var notes: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("How are you feeling?")) {
                    VStack(spacing: 16) {
                        // Mood Slider
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Mood")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(self.moodLevel))")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(self.moodColor(for: Int(self.moodLevel)))
                                Text(self.moodEmoji(for: Int(self.moodLevel)))
                                    .font(.title2)
                            }

                            Slider(value: self.$moodLevel, in: 1 ... 10, step: 1)
                                .tint(.orange)

                            HStack {
                                Text("1")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("10")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)

                        Divider()

                        // Energy Slider
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Energy")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(self.energyLevel))")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(self.energyColor(for: Int(self.energyLevel)))
                                Text(self.energyEmoji(for: Int(self.energyLevel)))
                                    .font(.title2)
                            }

                            Slider(value: self.$energyLevel, in: 1 ... 10, step: 1)
                                .tint(Color("FLPrimary"))

                            HStack {
                                Text("1")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("10")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }

                Section(header: Text("Notes (Optional)")) {
                    TextEditor(text: self.$notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Log Mood & Energy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        self.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let notesText = self.notes.trimmingCharacters(in: .whitespacesAndNewlines)
                        self.moodManager.addMoodEntry(
                            moodLevel: Int(self.moodLevel),
                            energyLevel: Int(self.energyLevel),
                            notes: notesText.isEmpty ? nil : notesText
                        )
                        self.dismiss()
                    }
                }
            }
        }
    }

    private func moodColor(for level: Int) -> Color {
        let tempEntry = MoodEntry(moodLevel: level, energyLevel: 5)
        return tempEntry.moodColor
    }

    private func moodEmoji(for level: Int) -> String {
        let tempEntry = MoodEntry(moodLevel: level, energyLevel: 5)
        return tempEntry.moodEmoji
    }

    private func energyColor(for level: Int) -> Color {
        let tempEntry = MoodEntry(moodLevel: 5, energyLevel: level)
        return tempEntry.energyColor
    }

    private func energyEmoji(for level: Int) -> String {
        let tempEntry = MoodEntry(moodLevel: 5, energyLevel: level)
        return tempEntry.energyEmoji
    }
}

#Preview {
    NavigationStack {
        MoodTrackingView()
    }
}
