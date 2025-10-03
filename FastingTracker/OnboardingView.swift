import SwiftUI

struct OnboardingView: View {
    @StateObject private var fastingManager = FastingManager()
    @StateObject private var weightManager = WeightManager()
    @StateObject private var hydrationManager = HydrationManager()
    private let healthKitManager = HealthKitManager.shared

    @State private var currentWeight: String = ""
    @State private var goalWeight: String = ""
    @State private var fastingGoal: Double = 16
    @State private var fastingGoalText: String = "16"
    @State private var hydrationGoal: Double = 90
    @State private var hydrationGoalText: String = "90"
    @State private var currentPage = 0
    @State private var showingSyncOptions = false
    @State private var isSyncing = false
    @FocusState private var isWeightFocused: Bool
    @FocusState private var isGoalWeightFocused: Bool
    @FocusState private var isFastingGoalFocused: Bool
    @FocusState private var isHydrationGoalFocused: Bool

    @Binding var isOnboardingComplete: Bool

    var body: some View {
        TabView(selection: $currentPage) {
            // Page 1: Welcome
            welcomePage
                .tag(0)

            // Page 2: Current Weight
            currentWeightPage
                .tag(1)

            // Page 3: Goal Weight
            goalWeightPage
                .tag(2)

            // Page 4: Fasting Goal
            fastingGoalPage
                .tag(3)

            // Page 5: Hydration Goal
            hydrationGoalPage
                .tag(4)

            // Page 6: HealthKit Sync
            healthKitSyncPage
                .tag(5)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }

    // MARK: - Welcome Page

    private var welcomePage: some View {
        VStack(spacing: 30) {
            Spacer()

            HStack(spacing: 0) {
                Text("Fast L")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                Text("IF")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
                Text("e")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
            }

            Text("Your Intermittent Fasting Companion")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            VStack(spacing: 20) {
                FeatureRow(icon: "timer", title: "Track Fasting", description: "Monitor your fasting windows and streaks")
                FeatureRow(icon: "drop.fill", title: "Stay Hydrated", description: "Log water, coffee, and tea intake")
                FeatureRow(icon: "scalemass.fill", title: "Weight Goals", description: "Track progress with HealthKit integration")
            }
            .padding(.horizontal)

            Spacer()

            Button(action: { currentPage = 1 }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(15)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Current Weight Page

    private var currentWeightPage: some View {
        VStack(spacing: 30) {
            Spacer()

            Text("What's Your Current Weight?")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("This helps us track your progress")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            HStack {
                TextField("Enter weight", text: $currentWeight)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 48, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .focused($isWeightFocused)

                Text("lbs")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 40)
            .onAppear {
                isWeightFocused = true
            }

            Spacer()

            HStack(spacing: 20) {
                Button(action: { currentPage = 0 }) {
                    Text("Back")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                }

                Button(action: { currentPage = 2 }) {
                    Text("Next")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(currentWeight.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(15)
                }
                .disabled(currentWeight.isEmpty)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Goal Weight Page

    private var goalWeightPage: some View {
        VStack(spacing: 30) {
            Spacer()

            Text("What's Your Goal Weight?")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("We'll help you reach your target")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            HStack {
                TextField("Enter goal", text: $goalWeight)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 48, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .focused($isGoalWeightFocused)

                Text("lbs")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 40)
            .onAppear {
                isGoalWeightFocused = true
            }

            Spacer()

            HStack(spacing: 20) {
                Button(action: { currentPage = 1 }) {
                    Text("Back")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                }

                Button(action: { currentPage = 3 }) {
                    Text("Next")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(goalWeight.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(15)
                }
                .disabled(goalWeight.isEmpty)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Fasting Goal Page

    private var fastingGoalPage: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 20)

            Text("Set Your Fasting Goal")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("How long do you want to fast?")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
                .frame(height: 10)

            Text("\(Int(fastingGoal)) Hours")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.blue)

            Picker("Fasting Goal", selection: $fastingGoal) {
                ForEach([12.0, 14.0, 16.0, 18.0, 20.0, 24.0], id: \.self) { hours in
                    Text("\(Int(hours))h").tag(hours)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 150)
            .onChange(of: fastingGoal) { _, newValue in
                fastingGoalText = String(Int(newValue))
            }

            VStack(spacing: 8) {
                Text("Or enter manually:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    TextField("Hours", text: $fastingGoalText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.title2)
                        .frame(width: 100)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .focused($isFastingGoalFocused)
                        .onChange(of: fastingGoalText) { _, newValue in
                            if let hours = Double(newValue), hours >= 1 && hours <= 48 {
                                fastingGoal = hours
                            }
                        }

                    Text("Hours")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }

            Text("16 Hours is the most popular choice")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
                .frame(height: 10)

            HStack(spacing: 20) {
                Button(action: { currentPage = 2 }) {
                    Text("Back")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                }

                Button(action: { currentPage = 4 }) {
                    Text("Next")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(15)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 110)
        }
        .onAppear {
            isFastingGoalFocused = true
        }
    }

    // MARK: - Hydration Goal Page

    private var hydrationGoalPage: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 20)

            Text("Set Your Hydration Goal")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Daily Water Intake Target")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
                .frame(height: 10)

            Text("\(Int(hydrationGoal)) oz")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.cyan)

            Picker("Hydration Goal", selection: $hydrationGoal) {
                ForEach([60.0, 70.0, 80.0, 90.0, 100.0, 110.0, 120.0], id: \.self) { oz in
                    Text("\(Int(oz)) oz").tag(oz)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 150)
            .onChange(of: hydrationGoal) { _, newValue in
                hydrationGoalText = String(Int(newValue))
            }

            VStack(spacing: 8) {
                Text("Or enter manually:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    TextField("Ounces", text: $hydrationGoalText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.title2)
                        .frame(width: 100)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .focused($isHydrationGoalFocused)
                        .onChange(of: hydrationGoalText) { _, newValue in
                            if let oz = Double(newValue), oz >= 1 && oz <= 300 {
                                hydrationGoal = oz
                            }
                        }

                    Text("oz")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }

            Text("90 oz Recommended for Most People")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
                .frame(height: 10)

            HStack(spacing: 20) {
                Button(action: { currentPage = 3 }) {
                    Text("Back")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                }

                Button(action: { currentPage = 5 }) {
                    Text("Next")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(15)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 110)
        }
        .onAppear {
            isHydrationGoalFocused = true
        }
    }

    // MARK: - HealthKit Sync Page

    private var healthKitSyncPage: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 72))
                .foregroundColor(.red)
                .onAppear {
                    isWeightFocused = false
                    isGoalWeightFocused = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }

            Text("Sync with Apple Health")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Import your weight history from Apple Health or start fresh")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            VStack(spacing: 15) {
                Button(action: {
                    completeOnboarding(syncHealthKit: true, futureOnly: false)
                }) {
                    VStack(spacing: 8) {
                        Text("Sync All Historical Data")
                            .font(.headline)
                        Text("Import all weight entries from Apple Health")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                }

                Button(action: {
                    completeOnboarding(syncHealthKit: true, futureOnly: true)
                }) {
                    VStack(spacing: 8) {
                        Text("Sync Future Data Only")
                            .font(.headline)
                        Text("Only sync new entries going forward")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.cyan)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                }

                Button(action: {
                    completeOnboarding(syncHealthKit: false, futureOnly: false)
                }) {
                    Text("Skip for Now")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                }
            }
            .padding(.horizontal, 40)

            Spacer()

            Button(action: { currentPage = 4 }) {
                Text("Back")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Complete Onboarding

    private func completeOnboarding(syncHealthKit: Bool, futureOnly: Bool) {
        // Save current weight
        if let weight = Double(currentWeight) {
            let entry = WeightEntry(date: Date(), weight: weight)
            weightManager.addWeightEntry(entry)
        }

        // Save goal weight to UserDefaults (WeightManager doesn't have goalWeight property)
        if let goal = Double(goalWeight) {
            UserDefaults.standard.set(goal, forKey: "goalWeight")
        }

        // Save fasting goal
        fastingManager.fastingGoalHours = fastingGoal

        // Save hydration goal
        hydrationManager.dailyGoalOunces = hydrationGoal

        // Sync with HealthKit if requested
        if syncHealthKit {
            healthKitManager.requestAuthorization { success, error in
                if success {
                    if futureOnly {
                        weightManager.syncFromHealthKit(startDate: Date())
                    } else {
                        weightManager.syncFromHealthKit()
                    }
                }
            }
        }

        // Mark onboarding as complete
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
        isOnboardingComplete = true
    }
}

// MARK: - Feature Row Component

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
}
