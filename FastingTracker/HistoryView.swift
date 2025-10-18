import SwiftUI
import Charts

struct HistoryView: View {
    @EnvironmentObject var fastingManager: FastingManager
    @State private var selectedDate: Date?

    private var selectedIdentifiableDate: Binding<IdentifiableDate?> {
        Binding(
            get: { selectedDate.map { IdentifiableDate(date: $0) } },
            set: { selectedDate = $0?.date }
        )
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if fastingManager.fastingHistory.isEmpty {
                        EmptyHistoryView()
                    } else {
                        // Streak Calendar Visualization (First)
                        StreakCalendarView(selectedDate: $selectedDate)
                            .environmentObject(fastingManager)
                            .padding()

                        // Fasting Graph (Second)
                        FastingGraphView()
                            .environmentObject(fastingManager)
                            .padding()

                        // Total Stats Card (Third)
                        TotalStatsView()
                            .environmentObject(fastingManager)
                            .padding()

                        // History List
                        HistoryListView(selectedDate: $selectedDate)
                            .environmentObject(fastingManager)
                    }
                }
            }
            .navigationTitle("History")
            .sheet(item: selectedIdentifiableDate) { identifiableDate in
                AddEditFastView(date: identifiableDate.date, fastingManager: fastingManager)
                    .environmentObject(fastingManager)
            }
        }
    }
}

struct EmptyHistoryView: View {
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 20) {
                Image(systemName: "clock.badge.questionmark")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("No fasting history yet")
                    .font(.title3)
                    .foregroundColor(.secondary)
                Text("Start your first fast to see it here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxHeight: .infinity)
            Spacer()
        }
    }
}

struct HistoryListView: View {
    @EnvironmentObject var fastingManager: FastingManager
    @Binding var selectedDate: Date?

    var body: some View {
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
                    .contentShape(RoundedRectangle(cornerRadius: 8))
                    .onTapGesture {
                        selectedDate = session.startTime
                    }
                Divider()
                    .padding(.horizontal)
            }
        }
    }
}

