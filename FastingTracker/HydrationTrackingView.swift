import SwiftUI

struct HydrationTrackingView: View {
    @StateObject private var hydrationManager = HydrationManager()
    @StateObject private var nudgeManager = HealthKitNudgeManager.shared

    // PHASE 1: Unit preferences integration
    // Following Apple's reactive UI pattern for settings changes
    // Reference: https://developer.apple.com/documentation/swiftui/observedobject
    @StateObject private var appSettings = AppSettings.shared
    @State private var showingGoalSettings = false
    @State private var showingDrinkPicker = false
    @State private var selectedDrinkType: DrinkType = .water
    @State private var showHealthKitNudge = false

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer()
                    .frame(height: 20)

                // HealthKit Nudge for first-time users who skipped onboarding
                // Following Lose It app pattern - contextual banner with single Connect action
                if showHealthKitNudge && nudgeManager.shouldShowNudge(for: .hydration) {
                    HealthKitNudgeView(
                        dataType: .hydration,
                        onConnect: {
                            // DIRECT AUTHORIZATION: Same pattern as existing hydration sync
                            // Request hydration permissions immediately when user wants to connect
                            print("📱 HydrationTrackingView: HealthKit nudge - requesting hydration authorization")
                            HealthKitManager.shared.requestHydrationAuthorization { success, error in
                                DispatchQueue.main.async {
                                    if success {
                                        print("✅ HydrationTrackingView: Hydration authorization granted from nudge")
                                        // Enable sync automatically when granted from nudge
                                        // Note: HydrationManager doesn't have enableSync() method yet
                                        // For now, we'll just hide the nudge
                                        showHealthKitNudge = false
                                    } else {
                                        print("❌ HydrationTrackingView: Hydration authorization denied from nudge")
                                        // Still hide nudge if user denied (don't keep asking)
                                        nudgeManager.dismissNudge(for: .hydration)
                                        showHealthKitNudge = false
                                    }
                                }
                            }
                        },
                        onDismiss: {
                            // Mark nudge as dismissed - won't show again
                            nudgeManager.dismissNudge(for: .hydration)
                            showHealthKitNudge = false
                        }
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }

                // Progress Ring (Multi-colored by drink type)
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 20)
                        .frame(width: 250, height: 250)

                    // Water segment (cyan)
                    Circle()
                        .trim(from: 0, to: hydrationManager.todaysProgressByType(.water))
                        .stroke(Color.cyan, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .frame(width: 250, height: 250)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: hydrationManager.todaysProgressByType(.water))

                    // Coffee segment (brown) - starts after water
                    Circle()
                        .trim(
                            from: hydrationManager.todaysProgressByType(.water),
                            to: hydrationManager.todaysProgressByType(.water) + hydrationManager.todaysProgressByType(.coffee)
                        )
                        .stroke(Color.brown, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .frame(width: 250, height: 250)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: hydrationManager.todaysProgressByType(.coffee))

                    // Tea segment (green) - starts after water + coffee
                    Circle()
                        .trim(
                            from: hydrationManager.todaysProgressByType(.water) + hydrationManager.todaysProgressByType(.coffee),
                            to: hydrationManager.todaysProgress()
                        )
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .frame(width: 250, height: 250)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: hydrationManager.todaysProgressByType(.tea))

                    VStack(spacing: 12) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.cyan)

                        // Current Progress
                        VStack(spacing: 4) {
                            Text("Today")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(hydrationManager.todaysTotalInPreferredUnit())) \(hydrationManager.currentUnitAbbreviation)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                        }

                        // Goal
                        VStack(spacing: 4) {
                            Text("Goal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(hydrationManager.dailyGoalInPreferredUnit())) \(hydrationManager.currentUnitAbbreviation)")
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
                        Text("Daily Goal: \(Int(hydrationManager.dailyGoalInPreferredUnit())) \(hydrationManager.currentUnitAbbreviation)")
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
                            action: {
                                selectedDrinkType = .water
                                showingDrinkPicker = true
                            }
                        )

                        // Coffee Button
                        DrinkButton(
                            type: .coffee,
                            color: .brown,
                            action: {
                                selectedDrinkType = .coffee
                                showingDrinkPicker = true
                            }
                        )

                        // Tea Button
                        DrinkButton(
                            type: .tea,
                            color: .green,
                            action: {
                                selectedDrinkType = .tea
                                showingDrinkPicker = true
                            }
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
        .onAppear {
            // Check if hydration goal needs to be set
            if hydrationManager.dailyGoalOunces == 0 {
                showingGoalSettings = true
            }

            // Show HealthKit nudge for first-time users who skipped onboarding
            // Following Lose It pattern - contextual reminder on first tracker access
            showHealthKitNudge = nudgeManager.shouldShowNudge(for: .hydration)
            if showHealthKitNudge {
                print("📱 HydrationTrackingView: Showing HealthKit nudge for first-time user")
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    // DIRECT AUTHORIZATION: Unified experience - same pattern as WeightTrackingView
                    // Request hydration permissions immediately when user wants to sync
                    print("📱 HydrationTrackingView: Requesting hydration authorization directly")
                    HealthKitManager.shared.requestHydrationAuthorization { success, error in
                        DispatchQueue.main.async {
                            if success {
                                print("✅ HydrationTrackingView: Hydration authorization granted - enabling sync")
                                // Sync existing data to HealthKit
                                hydrationManager.syncToHealthKit()
                            } else {
                                print("❌ HydrationTrackingView: Hydration authorization denied")
                            }
                        }
                    }
                }) {
                    Label("Sync with Apple Health", systemImage: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.cyan)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: HydrationHistoryView(hydrationManager: hydrationManager)) {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.cyan)
                }
            }
        }
        .sheet(isPresented: $showingGoalSettings) {
            HydrationGoalSettingsView(hydrationManager: hydrationManager)
        }
        .sheet(isPresented: $showingDrinkPicker) {
            DrinkAmountPickerView(
                drinkType: selectedDrinkType,
                hydrationManager: hydrationManager
            )
        }
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

    // PHASE 1: Unit preferences integration for goal settings
    // Following Apple's reactive UI pattern for settings changes
    // Reference: https://developer.apple.com/documentation/swiftui/observedobject
    @StateObject private var appSettings = AppSettings.shared

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Daily Hydration Goal")) {
                    HStack {
                        TextField("Goal (\(hydrationManager.currentUnitAbbreviation))", text: $goalInput)
                            .keyboardType(.numberPad)
                            .onAppear {
                                goalInput = String(Int(hydrationManager.dailyGoalInPreferredUnit()))
                            }
                        Text(hydrationManager.currentUnitAbbreviation)
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Text("Recommended daily water intake is \(Int(appSettings.hydrationUnit.fromOunces(64))) \(appSettings.hydrationUnit.abbreviation) (8 glasses). Adjust based on your activity level and climate.")
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
                            hydrationManager.updateDailyGoalFromPreferredUnit(newGoal)
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Drink Amount Picker View

struct DrinkAmountPickerView: View {
    let drinkType: DrinkType
    @ObservedObject var hydrationManager: HydrationManager
    @Environment(\.dismiss) var dismiss

    @State private var selectedAmount: Double = 8.0
    @State private var customAmount: String = ""
    @State private var useCustomAmount: Bool = false

    // Preset options in ounces
    private let presetAmounts: [Double] = [4, 8, 12, 16, 20, 24, 32]

    var drinkColor: Color {
        switch drinkType {
        case .water: return .cyan
        case .coffee: return .brown
        case .tea: return .green
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 20)

                // Drink Icon
                Image(systemName: drinkType.icon)
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .frame(width: 100, height: 100)
                    .background(drinkColor)
                    .cornerRadius(20)

                Text(drinkType.rawValue)
                    .font(.title2)
                    .fontWeight(.bold)

                Divider()
                    .padding(.horizontal)

                // Preset Amounts
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Amount")
                        .font(.headline)
                        .padding(.horizontal)

                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(presetAmounts, id: \.self) { amount in
                                Button(action: {
                                    selectedAmount = amount
                                    useCustomAmount = false
                                }) {
                                    HStack {
                                        Text("\(Int(amount)) oz")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)

                                        Spacer()

                                        if !useCustomAmount && selectedAmount == amount {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(drinkColor)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        (!useCustomAmount && selectedAmount == amount) ?
                                        drinkColor.opacity(0.15) : Color(.systemGray6)
                                    )
                                    .cornerRadius(12)
                                }
                            }

                            // Custom Amount
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Custom Amount")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)

                                HStack {
                                    TextField("Enter amount", text: $customAmount)
                                        .keyboardType(.decimalPad)
                                        .padding()
                                        .background(
                                            useCustomAmount ?
                                            drinkColor.opacity(0.15) : Color(.systemGray6)
                                        )
                                        .cornerRadius(12)
                                        .onChange(of: customAmount) { _, newValue in
                                            if !newValue.isEmpty {
                                                useCustomAmount = true
                                            }
                                        }

                                    Text(hydrationManager.currentUnitAbbreviation)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer()

                // Add Button
                Button(action: {
                    let amount = useCustomAmount ?
                        (Double(customAmount) ?? selectedAmount) : selectedAmount
                    hydrationManager.addDrink(type: drinkType, amount: amount)
                    dismiss()
                }) {
                    Text("Add \(drinkType.rawValue)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(drinkColor)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Log Drink")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
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
