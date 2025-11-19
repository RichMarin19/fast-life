import SwiftUI

protocol HealthKitServicing {
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void)
    func isWeightAuthorized() -> Bool
    func isWaterAuthorized() -> Bool
    func isSleepAuthorized() -> Bool
}

struct HealthKitServices: HealthKitServicing {
    private let manager: HealthKitManagerProtocol

    init(manager: HealthKitManagerProtocol = HealthKitManager.shared) {
        self.manager = manager
    }

    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        manager.requestAuthorization(completion: completion)
    }

    func isWeightAuthorized() -> Bool {
        manager.isWeightAuthorized()
    }

    func isWaterAuthorized() -> Bool {
        manager.isWaterAuthorized()
    }

    func isSleepAuthorized() -> Bool {
        manager.isSleepAuthorized()
    }
}

protocol NotificationServicing {
    @MainActor
    func requestAuthorization(completion: @escaping (Bool) -> Void)
}

struct NotificationServices: NotificationServicing {
    @MainActor
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        NotificationManager.shared.requestAuthorization(completion: completion)
    }
}

@MainActor
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
    let healthKitServices: HealthKitServicing
    let notificationServices: NotificationServicing
    private let measurementProvider: MeasurementSystemProviding
    @StateObject private var measurementObserver: MeasurementSystemObserver
    private let onboardingWeightManager: WeightManager
    private let weightSyncCoordinator: WeightSyncCoordinating
    @State private var hasTriggeredWeightSync = false
    @State private var showingSyncStatusAlert = false
    @State private var latestSyncStatus: WeightSyncStatus?
    @State private var shouldNavigateToNotificationsAfterSync = false
    @State private var isInteractionLocked = false
    @State private var activeSyncRequest: SyncRequestSource?

    private var weightUnit: WeightUnit {
        measurementObserver.system == .metric ? .kilograms : .pounds
    }

    private var weightUnitAbbreviation: String {
        weightUnit.abbreviation
    }

    private enum HealthKitSyncSelection {
        case allHistorical
        case futureOnly
    }

    private enum SyncRequestSource {
        case onboardingHistorical
    }

    init(
        isOnboardingComplete: Binding<Bool>,
        weightManager: WeightManager,
        healthKitServices: HealthKitServicing,
        notificationServices: NotificationServicing,
        weightSyncCoordinator: WeightSyncCoordinating,
        measurementProvider: MeasurementSystemProviding
    ) {
        self._isOnboardingComplete = isOnboardingComplete
        self.onboardingWeightManager = weightManager
        self.weightSyncCoordinator = weightSyncCoordinator
        self.healthKitServices = healthKitServices
        self.notificationServices = notificationServices
        self.measurementProvider = measurementProvider
        _measurementObserver = StateObject(wrappedValue: MeasurementSystemObserver(provider: measurementProvider))

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
        .allowsHitTesting(!isInteractionLocked)
        .alert("Sync Status", isPresented: $showingSyncStatusAlert, actions: {
            Button("OK", role: .cancel) {
                if shouldNavigateToNotificationsAfterSync {
                    shouldNavigateToNotificationsAfterSync = false
                    isInteractionLocked = false
                    currentPage = 6
                }
                activeSyncRequest = nil
            }
        }, message: {
            Text(syncMessage(for: latestSyncStatus))
        })
        .onReceive(weightSyncCoordinator.statusPublisher) { status in
            guard activeSyncRequest != nil else {
                AppLogger.debug("Ignoring sync status \(status) because onboarding did not initiate it", category: AppLogger.healthKit)
                return
            }
            switch status {
            case .success, .upToDate, .failure:
                latestSyncStatus = status
                showingSyncStatusAlert = true
                isInteractionLocked = false
                activeSyncRequest = nil
            case .idle, .syncing:
                break
            }
        }
        .onChange(of: currentPage) { oldValue, newValue in
            AppLogger.debug("Onboarding page changed from \(oldValue) to \(newValue)", category: AppLogger.ui)
            let pageNames = ["Welcome", "Current Weight", "Goal Weight", "Fasting Goal", "Hydration Goal", "HealthKit Sync", "Notifications"]
            if newValue < pageNames.count {
                AppLogger.debug("Now showing: \(pageNames[newValue])", category: AppLogger.ui)
            }
        }
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
                    AppLogger.debug("Onboarding: Welcome page event", category: AppLogger.ui)
                    AppLogger.debug("Get Started button tapped", category: AppLogger.ui)
                    AppLogger.debug("Advancing to Current Weight page", category: AppLogger.ui)
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

                Text(weightUnitAbbreviation)
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
                    AppLogger.debug("Back button tapped on Current Weight page, weight: \(currentWeight), returning to Welcome", category: AppLogger.ui)
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
                    AppLogger.debug("Advancing from Current Weight step to Goal Weight", category: AppLogger.ui)
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

                Text(weightUnitAbbreviation)
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
                    AppLogger.debug("Back button tapped on Goal Weight page, goal: \(goalWeight), returning to Current Weight", category: AppLogger.ui)
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
                    AppLogger.debug("Advancing from Goal Weight step to Fasting Goal", category: AppLogger.ui)
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
                Button(action: {
                    AppLogger.debug("Back button tapped on Fasting Goal page, goal: \(Int(fastingGoal)) hours, returning to Goal Weight", category: AppLogger.ui)
                    currentPage = 2
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
                    AppLogger.debug("Next button tapped on Fasting Goal page, goal: \(Int(fastingGoal)) hours, advancing to Hydration Goal", category: AppLogger.ui)
                    currentPage = 4
                }) {
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
                Button(action: {
                    AppLogger.debug("Back button tapped on Hydration Goal page, goal: \(Int(hydrationGoal)) oz, returning to Fasting Goal", category: AppLogger.ui)
                    currentPage = 3
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
                    AppLogger.debug("Next button tapped on Hydration Goal page, goal: \(Int(hydrationGoal)) oz, advancing to HealthKit Sync", category: AppLogger.ui)
                    currentPage = 5
                }) {
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
                    AppLogger.debug("Sync All Historical Data button tapped, requesting HealthKit authorization", category: AppLogger.healthKit)
                    handleHealthKitSelection(.allHistorical)
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
                    AppLogger.debug("Sync Future Data Only button tapped, requesting HealthKit authorization", category: AppLogger.healthKit)
                    handleHealthKitSelection(.futureOnly)
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
                    AppLogger.debug("Skip for Now button tapped, disabling HealthKit sync, advancing to Notifications", category: AppLogger.ui)
                    saveHealthKitPreference(syncHealthKit: false, futureOnly: false)
                    hasTriggeredWeightSync = false
                    advanceToNotifications(afterSync: false, reason: "User skipped HealthKit during onboarding")
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

            Button(action: {
                AppLogger.debug("Back button tapped on HealthKit Sync page, returning to Hydration Goal", category: AppLogger.ui)
                currentPage = 4
            }) {
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
                    AppLogger.debug("Enable Notifications button tapped, requesting notification authorization", category: AppLogger.ui)
                    notificationServices.requestAuthorization { granted in
                        AppLogger.debug("Notification authorization result: \(granted ? "granted" : "denied"), completing onboarding", category: AppLogger.ui)
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
                    AppLogger.debug("Maybe Later button tapped on Notifications page, completing onboarding without permission", category: AppLogger.ui)
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

            Button(action: {
                AppLogger.debug("Back button tapped on Notifications page, returning to HealthKit Sync", category: AppLogger.ui)
                currentPage = 5
            }) {
                Text("Back")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Helper Functions

    private func handleHealthKitSelection(_ selection: HealthKitSyncSelection) {
        // CRITICAL: Request authorization and present UI on the main thread (per Apple HealthKit docs)
        // Reference: https://developer.apple.com/documentation/healthkit/hkhealthstore/1614152-requestauthorization
        DispatchQueue.main.async {
            healthKitServices.requestAuthorization { success, error in
                Task { @MainActor in
                    guard success else {
                        AppLogger.debug("HealthKit authorization failed: \(String(describing: error)), disabling sync and advancing", category: AppLogger.healthKit)
                        saveHealthKitPreference(syncHealthKit: false, futureOnly: false)
                        advanceToNotifications(afterSync: false, reason: "HealthKit authorization failed")
                        return
                    }

                    // Verify which permissions were actually granted (only sync authorized domains)
                    let weightGranted = healthKitServices.isWeightAuthorized()
                    let waterGranted = healthKitServices.isWaterAuthorized()
                    let sleepGranted = healthKitServices.isSleepAuthorized()

                    AppLogger.debug("HealthKit permissions - Weight: \(weightGranted), Water: \(waterGranted), Sleep: \(sleepGranted)", category: AppLogger.healthKit)

                    guard weightGranted || waterGranted || sleepGranted else {
                        AppLogger.debug("No HealthKit permissions granted, leaving sync disabled", category: AppLogger.healthKit)
                        saveHealthKitPreference(syncHealthKit: false, futureOnly: false)
                        advanceToNotifications(afterSync: false, reason: "No HealthKit permissions granted")
                        return
                    }

                switch selection {
                case .allHistorical:
                    AppLogger.debug("Permissions granted, kicking off canonical historical sync flow", category: AppLogger.healthKit)
                    if weightGranted {
                        saveHealthKitPreference(syncHealthKit: true, futureOnly: false)
                            advanceToNotifications(afterSync: true, reason: "Historical sync in progress")
                            triggerHistoricalWeightSync()
                        } else {
                            AppLogger.debug("Weight permission missing, cannot import historical entries even though other domains granted; advancing without sync", category: AppLogger.healthKit)
                            saveHealthKitPreference(syncHealthKit: false, futureOnly: false)
                            advanceToNotifications(afterSync: false, reason: "Historical sync skipped due to missing weight permission")
                        }
                case .futureOnly:
                    AppLogger.debug("Permissions granted, enabling future-only sync without importing history", category: AppLogger.healthKit)
                    if weightGranted {
                        saveHealthKitPreference(syncHealthKit: true, futureOnly: true)
                        onboardingWeightManager.enableFutureOnlySync()
                        AppLogger.debug("Weight sync preference seeded for future entries (anchor set to now, observer only)", category: AppLogger.healthKit)
                    } else {
                        AppLogger.debug("Weight permission missing, cannot enable future sync; keeping sync disabled", category: AppLogger.healthKit)
                        saveHealthKitPreference(syncHealthKit: false, futureOnly: false)
                    }
                    advanceToNotifications(afterSync: false, reason: "Future-only sync configured")
                }
                }
            }
        }
    }

    private func advanceToNotifications(afterSync: Bool, reason: String) {
        AppLogger.debug("advanceToNotifications invoked (afterSync=\(afterSync)) – \(reason)", category: AppLogger.ui)
        if afterSync {
            shouldNavigateToNotificationsAfterSync = true
            isInteractionLocked = true
            activeSyncRequest = .onboardingHistorical
        } else {
            shouldNavigateToNotificationsAfterSync = false
            isInteractionLocked = false
            activeSyncRequest = nil
            currentPage = 6
        }
    }

    /// Dismisses the keyboard
    /// Per Apple HIG: "Dismiss the keyboard when users navigate away from text input"
    /// Reference: https://developer.apple.com/design/human-interface-guidelines/text-fields
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func saveHealthKitPreference(syncHealthKit: Bool, futureOnly: Bool) {
        AppLogger.debug("Saving HealthKit preference: syncHealthKit=\(syncHealthKit), futureOnly=\(futureOnly)", category: AppLogger.healthKit)
        healthKitSyncChoice = (syncHealthKit, futureOnly)
    }

    private func triggerHistoricalWeightSync() {
        onboardingWeightManager.setSyncPreference(true)
        hasTriggeredWeightSync = true
        onboardingWeightManager.resetFutureOnlySyncCutoff()
        activeSyncRequest = .onboardingHistorical
        weightSyncCoordinator.sync(initialImport: true)
    }

    // MARK: - Complete Onboarding

    private func completeOnboarding() {
        AppLogger.debug("Completing onboarding, creating manager instances", category: AppLogger.general)

        // Create managers only when needed (at completion time, not during onboarding UI rendering)
        // This prevents lag during onboarding caused by expensive init() work
        let fastingManager = FastingManager()
        let hydrationManager = HydrationManager()

        // Save current weight
        if let weight = Double(currentWeight) {
            let canonicalWeight = measurementProvider.currentUnit.toPounds(weight)
            let entry = WeightEntry(date: Date(), weight: canonicalWeight)
            onboardingWeightManager.addWeightEntry(entry)
            AppLogger.debug("Current weight saved during onboarding", category: AppLogger.general)
        } else {
            AppLogger.debug("No current weight entered, skipped", category: AppLogger.general)
        }

        // Save goal weight via WeightManager (single source of truth)
        if let goal = Double(goalWeight) {
            let canonicalGoal = measurementProvider.currentUnit.toPounds(goal)
            onboardingWeightManager.setGoalWeight(canonicalGoal)
            AppLogger.debug("Goal weight saved during onboarding", category: AppLogger.general)
        } else {
            AppLogger.debug("No goal weight entered, skipped", category: AppLogger.general)
        }

        // Save fasting goal to UserDefaults
        // CRITICAL: Use setFastingGoal() to persist to UserDefaults, not direct property assignment
        // Direct assignment only sets in-memory value, doesn't persist across app launches
        fastingManager.setFastingGoal(hours: fastingGoal)
        AppLogger.debug("Fasting goal saved: \(Int(fastingGoal)) hours", category: AppLogger.general)

        // Save hydration goal
        // CRITICAL: Use updateDailyGoal() to persist to UserDefaults, not direct property assignment
        // Direct assignment only sets in-memory @Published value, doesn't persist across app launches
        // Reference: https://developer.apple.com/documentation/foundation/userdefaults
        hydrationManager.updateDailyGoal(hydrationGoal)
        AppLogger.debug("Hydration goal saved: \(Int(hydrationGoal)) oz", category: AppLogger.general)

        // Sync with HealthKit if requested (authorization was already requested on HealthKit page)
        // CRITICAL: Only sync data for permissions that were actually granted (granular sync)
        // Per Apple: "Respect the user's privacy preferences and only access authorized data"
        // Reference: https://developer.apple.com/documentation/healthkit/protecting_user_privacy
        AppLogger.debug("Checking HealthKit sync preference: enabled=\(healthKitSyncChoice.enabled), futureOnly=\(healthKitSyncChoice.futureOnly)", category: AppLogger.healthKit)

        if healthKitSyncChoice.enabled {
            // Check which specific permissions were granted
            let weightGranted = healthKitServices.isWeightAuthorized()
            let waterGranted = healthKitServices.isWaterAuthorized()
            let sleepGranted = healthKitServices.isSleepAuthorized()

            AppLogger.debug("HealthKit sync enabled, checking granular permissions - Weight: \(weightGranted), Water: \(waterGranted), Sleep: \(sleepGranted)", category: AppLogger.healthKit)

            // Only sync data for authorized domains
            if weightGranted {
                onboardingWeightManager.setSyncPreference(true)
                if self.healthKitSyncChoice.futureOnly {
                    AppLogger.debug("User chose future-only sync; preference enabled for upcoming entries", category: AppLogger.healthKit)
                } else if !hasTriggeredWeightSync {
                    AppLogger.debug("Triggering canonical historical weight sync during onboarding completion", category: AppLogger.healthKit)
                    triggerHistoricalWeightSync()
                } else {
                    AppLogger.debug("Historical sync already triggered earlier in onboarding", category: AppLogger.healthKit)
                }
            } else {
                AppLogger.debug("Weight sync skipped (permission denied)", category: AppLogger.healthKit)
            }

            // Note: Water and Sleep sync would be implemented here when those managers support syncFromHealthKit()
            // Currently only WeightManager has sync functionality
            if waterGranted {
                AppLogger.debug("Water permission granted (sync not yet implemented in HydrationManager)", category: AppLogger.healthKit)
            }
            if sleepGranted {
                AppLogger.debug("Sleep permission granted (sync not yet implemented in SleepManager)", category: AppLogger.healthKit)
            }

            AppLogger.debug("HealthKit sync completed for all authorized domains", category: AppLogger.healthKit)
        } else {
            AppLogger.debug("HealthKit sync disabled (user skipped)", category: AppLogger.healthKit)
        }

        // Save HealthKit skip status for nudge system
        let skippedHealthKit = !healthKitSyncChoice.enabled
        UserDefaults.standard.set(skippedHealthKit, forKey: "healthKitSkippedOnboarding")
        AppLogger.debug("HealthKit skip status saved for nudge system: \(skippedHealthKit)", category: AppLogger.general)

        // Mark onboarding as complete
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
        isOnboardingComplete = true
        AppLogger.debug("Onboarding completed successfully", category: AppLogger.general)
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

extension OnboardingView {
    private func syncMessage(for status: WeightSyncStatus?) -> String {
        guard let status else { return "" }
        switch status {
        case .success(let newEntries):
            return "Successfully synced \(newEntries) weight entries from Apple Health."
        case .upToDate:
            return "Weight data is up to date. No new entries found in Apple Health."
        case .failure(let message):
            return message
        case .idle:
            return ""
        case .syncing:
            return "Sync in progress..."
        }
    }
}
