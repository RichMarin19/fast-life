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
    @State private var showHydrationSyncDialog = false

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer()
                    .frame(height: 20)

                // HealthKit Nudge for first-time users who skipped onboarding
                // Following Lose It app pattern - contextual banner with single Connect action
                if self.showHealthKitNudge, self.nudgeManager.shouldShowNudge(for: .hydration) {
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
                                        self.showHealthKitNudge = false
                                    } else {
                                        print("❌ HydrationTrackingView: Hydration authorization denied from nudge")
                                        // Still hide nudge if user denied (don't keep asking)
                                        self.nudgeManager.dismissNudge(for: .hydration)
                                        self.showHealthKitNudge = false
                                    }
                                }
                            }
                        },
                        onDismiss: {
                            // Mark nudge as dismissed - won't show again
                            self.nudgeManager.dismissNudge(for: .hydration)
                            self.showHealthKitNudge = false
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
                        .trim(from: 0, to: self.hydrationManager.todaysProgressByType(.water))
                        .stroke(Color.cyan, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .frame(width: 250, height: 250)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: self.hydrationManager.todaysProgressByType(.water))

                    // Coffee segment (brown) - starts after water
                    Circle()
                        .trim(
                            from: self.hydrationManager.todaysProgressByType(.water),
                            to: self.hydrationManager.todaysProgressByType(.water) + self.hydrationManager
                                .todaysProgressByType(.coffee)
                        )
                        .stroke(Color.brown, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .frame(width: 250, height: 250)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: self.hydrationManager.todaysProgressByType(.coffee))

                    // Tea segment (green) - starts after water + coffee
                    Circle()
                        .trim(
                            from: self.hydrationManager.todaysProgressByType(.water) + self.hydrationManager
                                .todaysProgressByType(.coffee),
                            to: self.hydrationManager.todaysProgress()
                        )
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .frame(width: 250, height: 250)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: self.hydrationManager.todaysProgressByType(.tea))

                    VStack(spacing: 12) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.cyan)

                        // Current Progress
                        VStack(spacing: 4) {
                            Text("Today")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(
                                "\(Int(self.hydrationManager.todaysTotalInPreferredUnit())) \(self.hydrationManager.currentUnitAbbreviation)"
                            )
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        }

                        // Goal
                        VStack(spacing: 4) {
                            Text("Goal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(
                                "\(Int(self.hydrationManager.dailyGoalInPreferredUnit())) \(self.hydrationManager.currentUnitAbbreviation)"
                            )
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundColor(.cyan)
                        }
                    }
                }

                // Progress Percentage
                Text("\(self.hydrationManager.todaysProgressPercentage())%")
                    .font(.title2)
                    .foregroundColor(.secondary)

                // Goal Settings Button
                Button(action: {
                    self.showingGoalSettings = true
                }) {
                    HStack {
                        Text(
                            "Daily Goal: \(Int(self.hydrationManager.dailyGoalInPreferredUnit())) \(self.hydrationManager.currentUnitAbbreviation)"
                        )
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
                                self.selectedDrinkType = .water
                                self.showingDrinkPicker = true
                            }
                        )

                        // Coffee Button
                        DrinkButton(
                            type: .coffee,
                            color: .brown,
                            action: {
                                self.selectedDrinkType = .coffee
                                self.showingDrinkPicker = true
                            }
                        )

                        // Tea Button
                        DrinkButton(
                            type: .tea,
                            color: .green,
                            action: {
                                self.selectedDrinkType = .tea
                                self.showingDrinkPicker = true
                            }
                        )
                    }
                    .padding(.horizontal, 40)
                }
                .padding(.bottom, 20)

                // Today's Drinks History
                if !self.hydrationManager.todaysDrinks().isEmpty {
                    VStack(spacing: 12) {
                        Text("Today's Drinks")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 40)

                        ForEach(self.hydrationManager.todaysDrinks()) { drink in
                            DrinkHistoryRow(drink: drink, onDelete: {
                                self.hydrationManager.deleteDrinkEntry(drink)
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
            if self.hydrationManager.dailyGoalOunces == 0 {
                self.showingGoalSettings = true
            }

            // Show HealthKit nudge for first-time users who skipped onboarding
            // Following Lose It pattern - contextual reminder on first tracker access
            self.showHealthKitNudge = self.nudgeManager.shouldShowNudge(for: .hydration)
            if self.showHealthKitNudge {
                print("📱 HydrationTrackingView: Showing HealthKit nudge for first-time user")
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    // DIRECT AUTHORIZATION: Unified experience - same pattern as WeightTrackingView
                    // Request hydration permissions immediately when user wants to sync
                    print("📱 HydrationTrackingView: Requesting hydration authorization directly")
                    // Following Weight tracker successful pattern - show user choice dialog
                    self.showHydrationSyncDialog = true
                }) {
                    Label("Sync with Apple Health", systemImage: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.cyan)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: HydrationHistoryView(hydrationManager: self.hydrationManager)) {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.cyan)
                }
            }
        }
        .sheet(isPresented: self.$showingGoalSettings) {
            HydrationGoalSettingsView(hydrationManager: self.hydrationManager)
        }
        .sheet(isPresented: self.$showingDrinkPicker) {
            DrinkAmountPickerView(
                drinkType: self.selectedDrinkType,
                hydrationManager: self.hydrationManager
            )
        }
        .alert("Import Hydration Data", isPresented: self.$showHydrationSyncDialog) {
            // Following Weight tracker successful pattern - user choice for import scope
            // Industry standards (MyFitnessPal/Lose It): Always let user choose import type
            Button("Import All Historical Data") {
                // Request authorization and import complete hydration history
                HealthKitManager.shared.requestHydrationAuthorization { success, error in
                    DispatchQueue.main.async {
                        if success {
                            print("✅ HydrationTrackingView: Hydration authorization granted - syncing all data")
                            self.hydrationManager.syncFromHealthKit()
                        } else {
                            print("❌ HydrationTrackingView: Hydration authorization denied")
                        }
                    }
                }
            }
            Button("Future Data Only") {
                // Request authorization and sync only future entries
                HealthKitManager.shared.requestHydrationAuthorization { success, error in
                    DispatchQueue.main.async {
                        if success {
                            print("✅ HydrationTrackingView: Hydration authorization granted - future only sync")
                            self.hydrationManager.syncToHealthKit()
                        } else {
                            print("❌ HydrationTrackingView: Hydration authorization denied")
                        }
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "Choose how to sync your hydration data with Apple Health. You can import all your historical hydration entries or start fresh with only future entries."
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
        Button(action: self.action) {
            VStack(spacing: 8) {
                Image(systemName: self.type.icon)
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(self.color)
                    .cornerRadius(12)

                Text(self.type.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text("\(Int(self.type.standardServing)) oz")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(self.color.opacity(0.1))
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
            Image(systemName: self.drink.type.icon)
                .font(.system(size: 20))
                .foregroundColor(self.drinkColor)
                .frame(width: 40, height: 40)
                .background(self.drinkColor.opacity(0.15))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(self.drink.type.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(self.formatTime(self.drink.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(Int(self.drink.amount)) oz")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

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

    private var drinkColor: Color {
        switch self.drink.type {
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
                        TextField("Goal (\(self.hydrationManager.currentUnitAbbreviation))", text: self.$goalInput)
                            .keyboardType(.numberPad)
                            .onAppear {
                                self.goalInput = String(Int(self.hydrationManager.dailyGoalInPreferredUnit()))
                            }
                        Text(self.hydrationManager.currentUnitAbbreviation)
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Text(
                        "Recommended daily water intake is \(Int(self.appSettings.hydrationUnit.fromOunces(64))) \(self.appSettings.hydrationUnit.abbreviation) (8 glasses). Adjust based on your activity level and climate."
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Hydration Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        self.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let newGoal = Double(goalInput), newGoal > 0 {
                            self.hydrationManager.updateDailyGoalFromPreferredUnit(newGoal)
                        }
                        self.dismiss()
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
        switch self.drinkType {
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
                Image(systemName: self.drinkType.icon)
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .frame(width: 100, height: 100)
                    .background(self.drinkColor)
                    .cornerRadius(20)

                Text(self.drinkType.rawValue)
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
                            ForEach(self.presetAmounts, id: \.self) { amount in
                                Button(action: {
                                    self.selectedAmount = amount
                                    self.useCustomAmount = false
                                }) {
                                    HStack {
                                        Text("\(Int(amount)) oz")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)

                                        Spacer()

                                        if !self.useCustomAmount, self.selectedAmount == amount {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(self.drinkColor)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        (!self.useCustomAmount && self.selectedAmount == amount) ?
                                            self.drinkColor.opacity(0.15) : Color(.systemGray6)
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
                                    TextField("Enter amount", text: self.$customAmount)
                                        .keyboardType(.decimalPad)
                                        .padding()
                                        .background(
                                            self.useCustomAmount ?
                                                self.drinkColor.opacity(0.15) : Color(.systemGray6)
                                        )
                                        .cornerRadius(12)
                                        .onChange(of: self.customAmount) { _, newValue in
                                            if !newValue.isEmpty {
                                                self.useCustomAmount = true
                                            }
                                        }

                                    Text(self.hydrationManager.currentUnitAbbreviation)
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
                    let amount = self.useCustomAmount ?
                        (Double(self.customAmount) ?? self.selectedAmount) : self.selectedAmount
                    self.hydrationManager.addDrink(type: self.drinkType, amount: amount)
                    self.dismiss()
                }) {
                    Text("Add \(self.drinkType.rawValue)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(self.drinkColor)
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
                        self.dismiss()
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
