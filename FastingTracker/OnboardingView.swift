import SwiftUI

struct OnboardingView: View {
    // Don't create managers or access HealthKit immediately - they're only needed at the end
    // Accessing HealthKitManager.shared causes expensive HealthKit framework initialization on main thread

    @State private var currentWeight: String = ""
    @State private var goalWeight: String = ""
    @State private var fastingGoal: Double = 16
    @State private var fastingGoalText: String = "16"
    @State private var hydrationGoal: Double = 100
    @State private var hydrationGoalText: String = "100"
    @State private var currentPage = 0
    @State private var healthKitSyncChoice: (enabled: Bool, futureOnly: Bool) = (false, false)
    @FocusState private var isWeightFocused: Bool
    @FocusState private var isGoalWeightFocused: Bool
    @FocusState private var isFastingGoalFocused: Bool
    @FocusState private var isHydrationGoalFocused: Bool
    @FocusState private var isKeyboardPrewarmFocused: Bool  // Hidden field for keyboard initialization

    @Binding var isOnboardingComplete: Bool

    init(isOnboardingComplete: Binding<Bool>) {
        self._isOnboardingComplete = isOnboardingComplete

        // Style page indicator dots to be visible against white background
        // Current page = blue (matches app theme), inactive pages = light gray
        // Per Apple UIPageControl documentation: appearance() sets global styling
        // Reference: https://developer.apple.com/documentation/uikit/uipagecontrol
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor.systemBlue
        UIPageControl.appearance().pageIndicatorTintColor = UIColor.gray.withAlphaComponent(0.3)
    }

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

            // Page 7: Notification Permission
            notificationPermissionPage
                .tag(6)
        }
        .tabViewStyle(.page)
        // Default .page style shows dots AND enables lazy page rendering (Apple optimization)
        // UIPageControl.appearance() in init() sets colors for visibility
        // Pages render on-demand (not all at once) for better launch performance
        // Per Apple: "A paged view shows page indicators at the bottom by default"
        // Reference: https://developer.apple.com/documentation/swiftui/pagetabviewstyle
    }

    // MARK: - Welcome Page

    private var welcomePage: some View {
        ZStack {
            // Hidden TextField for keyboard pre-warming (industry standard performance technique)
            // Pre-initializes keyboard on Page 1 so it appears instantly on Page 2
            // Used by major apps (Instagram, Twitter) to eliminate keyboard lag
            // Per Apple: "Prepare expensive resources early when they won't block user interaction"
            // Reference: https://developer.apple.com/documentation/xcode/improving-your-app-s-performance
            TextField("", text: .constant(""))
                .frame(width: 0, height: 0)
                .opacity(0)
                .disabled(true)
                .focused($isKeyboardPrewarmFocused)

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
                FeatureRow(icon: "bed.double.fill", title: "Sleep Tracking", description: "Monitor sleep quality and duration")
                FeatureRow(icon: "scalemass.fill", title: "Weight Goals", description: "Track progress with HealthKit integration")
            }
            .padding(.horizontal)

            Spacer()

            Button(action: {
                currentPage = 1
            }) {
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
            }  // End VStack
        }  // End ZStack
        .task {
            // Trigger keyboard pre-warming after page fully loads
            // Delay ensures page renders first, then keyboard initializes in background
            try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 second delay
            isKeyboardPrewarmFocused = true
            try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 second (just enough to init)
            isKeyboardPrewarmFocused = false  // Unfocus immediately
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
                Button(action: {
                    dismissKeyboard()
                    currentPage = 0
                }) {
                    Text("Back")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                }

                Button(action: {
                    currentPage = 2
                }) {
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
                Button(action: {
                    currentPage = 1
                }) {
                    Text("Back")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                }

                Button(action: {
                    currentPage = 3
                }) {
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
                        .onAppear {
                            // Ensure default value "16" is displayed
                            // State initialization sets this, but explicitly ensure it's visible
                            if fastingGoalText.isEmpty {
                                fastingGoalText = "16"
                            }
                        }
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

            Text("100 oz Recommended for Most People")
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
                    // Request HealthKit authorization IMMEDIATELY (not later)
                    // Access HealthKitManager.shared here (not during view init) to defer framework initialization
                    HealthKitManager.shared.requestAuthorization { success, error in
                        if success {
                            saveHealthKitPreference(syncHealthKit: true, futureOnly: false)
                            currentPage = 6
                        } else {
                            print("HealthKit authorization failed: \(String(describing: error))")
                            // Still allow user to continue even if authorization fails
                            saveHealthKitPreference(syncHealthKit: false, futureOnly: false)
                            currentPage = 6
                        }
                    }
                }) {
                    VStack(spacing: 8) {
                        Text("Sync All Historical Data")
                            .font(.headline)
                        Text("Import all weight, water, and sleep data from Apple Health")
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
                    // Request HealthKit authorization IMMEDIATELY (not later)
                    // Access HealthKitManager.shared here (not during view init) to defer framework initialization
                    HealthKitManager.shared.requestAuthorization { success, error in
                        if success {
                            saveHealthKitPreference(syncHealthKit: true, futureOnly: true)
                            currentPage = 6
                        } else {
                            print("HealthKit authorization failed: \(String(describing: error))")
                            // Still allow user to continue even if authorization fails
                            saveHealthKitPreference(syncHealthKit: false, futureOnly: false)
                            currentPage = 6
                        }
                    }
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
                    saveHealthKitPreference(syncHealthKit: false, futureOnly: false)
                    currentPage = 6
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

    // MARK: - Notification Permission Page

    private var notificationPermissionPage: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 72))
                .foregroundColor(.orange)

            Text("Stay on Track with Reminders")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Get notified when you hit milestones during your fast and when you reach your goals")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            VStack(spacing: 15) {
                Button(action: {
                    NotificationManager.shared.requestAuthorization { granted in
                        completeOnboarding()
                    }
                }) {
                    Text("Enable Notifications")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(15)
                }

                Button(action: {
                    completeOnboarding()
                }) {
                    Text("Maybe Later")
                        .font(.headline)
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                }
            }
            .padding(.horizontal, 40)

            Spacer()

            Button(action: { currentPage = 5 }) {
                Text("Back")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Helper Functions

    /// Dismisses the keyboard
    /// Per Apple HIG: "Dismiss the keyboard when users navigate away from text input"
    /// Reference: https://developer.apple.com/design/human-interface-guidelines/text-fields
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func saveHealthKitPreference(syncHealthKit: Bool, futureOnly: Bool) {
        healthKitSyncChoice = (syncHealthKit, futureOnly)
    }

    // MARK: - Complete Onboarding

    private func completeOnboarding() {
        // Create managers only when needed (at completion time, not during onboarding UI rendering)
        // This prevents lag during onboarding caused by expensive init() work
        let weightManager = WeightManager()
        let fastingManager = FastingManager()
        let hydrationManager = HydrationManager()

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

        // Sync with HealthKit if requested (authorization was already requested on HealthKit page)
        if healthKitSyncChoice.enabled {
            // Perform sync (authorization already granted on previous page)
            if self.healthKitSyncChoice.futureOnly {
                weightManager.syncFromHealthKit(startDate: Date())
            } else {
                weightManager.syncFromHealthKit()
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
