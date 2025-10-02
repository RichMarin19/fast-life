import SwiftUI

struct HydrationTrackingView: View {
    @StateObject private var hydrationManager = HydrationManager()
    @State private var showingGoalSettings = false

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer()
                    .frame(height: 20)

                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 20)
                        .frame(width: 250, height: 250)

                    Circle()
                        .trim(from: 0, to: hydrationManager.todaysProgress())
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: hydrationGradientColors),
                                center: .center,
                                startAngle: .degrees(0),
                                endAngle: .degrees(360)
                            ),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 250, height: 250)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: hydrationManager.todaysProgress())

                    VStack(spacing: 12) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.cyan)

                        // Current Progress
                        VStack(spacing: 4) {
                            Text("Today")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(hydrationManager.todaysTotalOunces())) oz")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                        }

                        // Goal
                        VStack(spacing: 4) {
                            Text("Goal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(hydrationManager.dailyGoalOunces)) oz")
                                .font(.system(size: 24, weight: .semibold, design: .rounded))
                                .foregroundColor(.cyan)
                        }
                    }
                }

                // Progress Percentage
                Text("\(hydrationManager.todaysProgressPercentage())%")
                    .font(.title2)
                    .foregroundColor(.secondary)

                // Goal Settings Button
                Button(action: {
                    showingGoalSettings = true
                }) {
                    HStack {
                        Text("Daily Goal: \(Int(hydrationManager.dailyGoalOunces)) oz")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.cyan)
                    }
                }
                .padding(.bottom, 10)

                Spacer()
                    .frame(height: 10)

                // Log Drink Buttons
                VStack(spacing: 16) {
                    Text("Log a Drink")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 40)

                    HStack(spacing: 16) {
                        // Water Button
                        DrinkButton(
                            type: .water,
                            color: .cyan,
                            action: { hydrationManager.addDrink(type: .water) }
                        )

                        // Coffee Button
                        DrinkButton(
                            type: .coffee,
                            color: .brown,
                            action: { hydrationManager.addDrink(type: .coffee) }
                        )

                        // Tea Button
                        DrinkButton(
                            type: .tea,
                            color: .green,
                            action: { hydrationManager.addDrink(type: .tea) }
                        )
                    }
                    .padding(.horizontal, 40)
                }
                .padding(.bottom, 20)

                // Today's Drinks History
                if !hydrationManager.todaysDrinks().isEmpty {
                    VStack(spacing: 12) {
                        Text("Today's Drinks")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 40)

                        ForEach(hydrationManager.todaysDrinks()) { drink in
                            DrinkHistoryRow(drink: drink, onDelete: {
                                hydrationManager.deleteDrinkEntry(drink)
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
        .navigationTitle("Hydration Tracker")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingGoalSettings) {
            HydrationGoalSettingsView(hydrationManager: hydrationManager)
        }
    }

    // Gradient colors for progress ring - cyan to blue
    private var hydrationGradientColors: [Color] {
        [
            Color.cyan,
            Color.cyan.opacity(0.8),
            Color.blue.opacity(0.6),
            Color.blue
        ]
    }
}

// MARK: - Drink Button Component

struct DrinkButton: View {
    let type: DrinkType
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(color)
                    .cornerRadius(12)

                Text(type.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text("\(Int(type.standardServing)) oz")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// MARK: - Drink History Row Component

struct DrinkHistoryRow: View {
    let drink: DrinkEntry
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: drink.type.icon)
                .font(.system(size: 20))
                .foregroundColor(drinkColor)
                .frame(width: 40, height: 40)
                .background(drinkColor.opacity(0.15))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(drink.type.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(formatTime(drink.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(Int(drink.amount)) oz")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Button(action: onDelete) {
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

    private var drinkColor: Color {
        switch drink.type {
        case .water: return .cyan
        case .coffee: return .brown
        case .tea: return .green
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Goal Settings View

struct HydrationGoalSettingsView: View {
    @ObservedObject var hydrationManager: HydrationManager
    @Environment(\.dismiss) var dismiss
    @State private var goalInput: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Daily Hydration Goal")) {
                    HStack {
                        TextField("Goal (oz)", text: $goalInput)
                            .keyboardType(.numberPad)
                            .onAppear {
                                goalInput = String(Int(hydrationManager.dailyGoalOunces))
                            }
                        Text("oz")
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Text("Recommended daily water intake is 64 oz (8 glasses). Adjust based on your activity level and climate.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Hydration Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let newGoal = Double(goalInput), newGoal > 0 {
                            hydrationManager.updateDailyGoal(newGoal)
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        HydrationTrackingView()
    }
}
