import SwiftUI

// MARK: - Hydration Stats View
// Extracted from HydrationHistoryView.swift for better code organization
// Following Apple MVVM patterns and SwiftUI component architecture

struct HydrationStatsView: View {
    @ObservedObject var hydrationManager: HydrationManager
    let timeRange: HydrationHistoryView.TimeRange

    var body: some View {
        VStack(spacing: 12) {
            Text("Statistics")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                HydrationStatCard(
                    title: "Avg Daily",
                    value: "\(Int(averageDaily())) oz",
                    icon: "chart.bar.fill",
                    color: .cyan
                )

                HydrationStatCard(
                    title: "Total",
                    value: "\(Int(totalOunces())) oz",
                    icon: "drop.fill",
                    color: .blue
                )

                HydrationStatCard(
                    title: "Goal Met",
                    value: "\(goalMetDays())",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private func averageDaily() -> Double {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -timeRange.days, to: Date()) ?? Date()
        let entries = hydrationManager.drinkEntries.filter { $0.date >= cutoffDate }

        if entries.isEmpty { return 0.0 }

        let total = entries.reduce(0.0) { $0 + $1.amount }
        let days = Set(entries.map { calendar.startOfDay(for: $0.date) }).count

        return total / Double(max(days, 1))
    }

    private func totalOunces() -> Double {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -timeRange.days, to: Date()) ?? Date()
        return hydrationManager.drinkEntries
            .filter { $0.date >= cutoffDate }
            .reduce(0.0) { $0 + $1.amount }
    }

    private func goalMetDays() -> Int {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -timeRange.days, to: Date()) ?? Date()
        let entries = hydrationManager.drinkEntries.filter { $0.date >= cutoffDate }

        // Group by day and count days that met goal
        var dailyTotals: [Date: Double] = [:]
        for entry in entries {
            let dayStart = calendar.startOfDay(for: entry.date)
            dailyTotals[dayStart, default: 0.0] += entry.amount
        }

        return dailyTotals.values.filter { $0 >= hydrationManager.dailyGoalOunces }.count
    }
}

// MARK: - Hydration Stat Card Component

struct HydrationStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Drink Type Breakdown View

struct DrinkTypeBreakdownView: View {
    @ObservedObject var hydrationManager: HydrationManager
    let timeRange: HydrationHistoryView.TimeRange

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Drink Breakdown")
                .font(.headline)

            ForEach(DrinkType.allCases, id: \.self) { type in
                HStack {
                    Image(systemName: type.icon)
                        .foregroundColor(colorForType(type))
                        .frame(width: 24)

                    Text(type.rawValue)
                        .font(.subheadline)

                    Spacer()

                    Text("\(Int(totalForType(type))) oz")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("(\(percentageForType(type))%)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private func colorForType(_ type: DrinkType) -> Color {
        switch type {
        case .water: return .cyan
        case .coffee: return .brown
        case .tea: return .green
        }
    }

    private func totalForType(_ type: DrinkType) -> Double {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -timeRange.days, to: Date()) ?? Date()

        return hydrationManager.drinkEntries
            .filter { $0.date >= cutoffDate && $0.type == type }
            .reduce(0.0) { $0 + $1.amount }
    }

    private func percentageForType(_ type: DrinkType) -> Int {
        let total = totalForType(type)
        let allTotal = DrinkType.allCases.reduce(0.0) { $0 + totalForType($1) }

        guard allTotal > 0 else { return 0 }
        return Int((total / allTotal) * 100)
    }
}

// MARK: - Daily Hydration Row View

struct DailyHydrationRowView: View {
    let date: Date
    let totalOunces: Double
    let breakdown: [DrinkType: Double]
    let goalOunces: Double

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDate(date))
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    if let water = breakdown[.water], water > 0 {
                        DrinkBadge(type: .water, amount: water)
                    }
                    if let coffee = breakdown[.coffee], coffee > 0 {
                        DrinkBadge(type: .coffee, amount: coffee)
                    }
                    if let tea = breakdown[.tea], tea > 0 {
                        DrinkBadge(type: .tea, amount: tea)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(totalOunces)) oz")
                    .font(.headline)
                    .fontWeight(.bold)

                if totalOunces >= goalOunces {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("Goal Met")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    Text("\(Int(goalOunces - totalOunces)) oz short")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Drink Badge Component

struct DrinkBadge: View {
    let type: DrinkType
    let amount: Double

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: type.icon)
                .font(.caption2)
            Text("\(Int(amount))")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(colorForType(type))
        .cornerRadius(6)
    }

    private func colorForType(_ type: DrinkType) -> Color {
        switch type {
        case .water: return .cyan
        case .coffee: return .brown
        case .tea: return .green
        }
    }
}

// MARK: - Add/Edit Hydration View
// Large form view for adding daily hydration data with goal setting

struct AddEditHydrationView: View {
    let date: Date
    @ObservedObject var hydrationManager: HydrationManager
    @Environment(\.dismiss) var dismiss

    @State private var waterAmount: String = ""
    @State private var coffeeAmount: String = ""
    @State private var teaAmount: String = ""
    @State private var dailyGoalOunces: Double = 90
    @State private var customGoalText: String = ""
    @State private var isCustomGoal: Bool = false
    @FocusState private var isCustomGoalFocused: Bool

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Date")) {
                    HStack {
                        Text(formatDate(date))
                            .font(.body)
                        Spacer()
                    }
                }

                Section(header: Text("Water")) {
                    HStack {
                        Image(systemName: "drop.fill")
                            .foregroundColor(.cyan)
                        TextField("Amount (oz)", text: $waterAmount)
                            .keyboardType(.decimalPad)
                        Text("oz")
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("Coffee")) {
                    HStack {
                        Image(systemName: "cup.and.saucer.fill")
                            .foregroundColor(.brown)
                        TextField("Amount (oz)", text: $coffeeAmount)
                            .keyboardType(.decimalPad)
                        Text("oz")
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("Tea")) {
                    HStack {
                        Image(systemName: "mug.fill")
                            .foregroundColor(.green)
                        TextField("Amount (oz)", text: $teaAmount)
                            .keyboardType(.decimalPad)
                        Text("oz")
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("Goal")) {
                    VStack(spacing: 16) {
                        Text("\(Int(dailyGoalOunces)) oz")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.cyan)
                            .frame(maxWidth: .infinity)

                        VStack(spacing: 10) {
                            HStack(spacing: 6) {
                                ForEach([60.0, 70.0, 80.0, 90.0, 100.0, 110.0, 120.0], id: \.self) { goal in
                                    Button(action: {
                                        isCustomGoal = false
                                        dailyGoalOunces = goal
                                        customGoalText = ""  // Clear custom text when selecting preset
                                    }) {
                                        Text("\(Int(goal))oz")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(dailyGoalOunces == goal && !isCustomGoal ? .white : .cyan)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(dailyGoalOunces == goal && !isCustomGoal ? Color.cyan : Color(UIColor.secondarySystemGroupedBackground))
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(dailyGoalOunces == goal && !isCustomGoal ? Color.clear : Color.cyan.opacity(0.3), lineWidth: 1)
                                            )
                                    }
                                }
                            }

                            Button(action: {
                                // Always start with empty text field for custom input
                                customGoalText = ""
                                dailyGoalOunces = 0  // Reset display to 0 when entering custom mode
                                isCustomGoal = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isCustomGoalFocused = true
                                }
                            }) {
                                Text("Custom")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(isCustomGoal ? .white : .cyan)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(isCustomGoal ? Color.cyan : Color(UIColor.secondarySystemGroupedBackground))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(isCustomGoal ? Color.clear : Color.cyan.opacity(0.3), lineWidth: 1)
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
                                                dailyGoalOunces = value
                                            }
                                        }
                                        .toolbar {
                                            ToolbarItemGroup(placement: .keyboard) {
                                                Spacer()
                                                Button("Done") {
                                                    isCustomGoalFocused = false
                                                }
                                                .foregroundColor(.cyan)
                                                .fontWeight(.semibold)
                                            }
                                        }
                                    Text("oz")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section {
                    Text("Enter the total amount consumed for each drink type on this day.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Hydration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveHydration()
                        dismiss()
                    }
                    .disabled(!hasValidInput())
                }
            }
            .onAppear {
                dailyGoalOunces = hydrationManager.dailyGoalOunces
                // Check if current goal is a preset value or custom
                let presetGoals = [60.0, 70.0, 80.0, 90.0, 100.0, 110.0, 120.0]
                if !presetGoals.contains(dailyGoalOunces) {
                    isCustomGoal = true
                    customGoalText = String(Int(dailyGoalOunces))
                }
                loadExistingData()
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    private func hasValidInput() -> Bool {
        let water = Double(waterAmount) ?? 0
        let coffee = Double(coffeeAmount) ?? 0
        let tea = Double(teaAmount) ?? 0
        return water > 0 || coffee > 0 || tea > 0
    }

    private func loadExistingData() {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)

        // Get existing drinks for this day
        let dayDrinks = hydrationManager.drinkEntries.filter { entry in
            calendar.isDate(entry.date, inSameDayAs: dayStart)
        }

        // Sum up by type
        var waterTotal = 0.0
        var coffeeTotal = 0.0
        var teaTotal = 0.0

        for drink in dayDrinks {
            switch drink.type {
            case .water: waterTotal += drink.amount
            case .coffee: coffeeTotal += drink.amount
            case .tea: teaTotal += drink.amount
            }
        }

        // Populate fields if data exists
        if waterTotal > 0 { waterAmount = String(Int(waterTotal)) }
        if coffeeTotal > 0 { coffeeAmount = String(Int(coffeeTotal)) }
        if teaTotal > 0 { teaAmount = String(Int(teaTotal)) }
    }

    private func saveHydration() {
        // Update the global daily goal
        hydrationManager.dailyGoalOunces = dailyGoalOunces

        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)

        // Remove existing entries for this day
        hydrationManager.drinkEntries.removeAll { entry in
            calendar.isDate(entry.date, inSameDayAs: dayStart)
        }

        // Add new entries (use noon as the time)
        let entryTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: dayStart) ?? dayStart

        if let water = Double(waterAmount), water > 0 {
            let entry = DrinkEntry(type: .water, amount: water, date: entryTime)
            hydrationManager.addDrinkEntry(entry)
        }

        if let coffee = Double(coffeeAmount), coffee > 0 {
            let entry = DrinkEntry(type: .coffee, amount: coffee, date: entryTime)
            hydrationManager.addDrinkEntry(entry)
        }

        if let tea = Double(teaAmount), tea > 0 {
            let entry = DrinkEntry(type: .tea, amount: tea, date: entryTime)
            hydrationManager.addDrinkEntry(entry)
        }
    }
}

// MARK: - Preview

#Preview("Hydration Stats") {
    HydrationStatsView(
        hydrationManager: HydrationManager(),
        timeRange: .week
    )
    .padding()
}

#Preview("Drink Type Breakdown") {
    DrinkTypeBreakdownView(
        hydrationManager: HydrationManager(),
        timeRange: .week
    )
    .padding()
}