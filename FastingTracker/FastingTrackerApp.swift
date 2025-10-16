import SwiftUI

@main
struct FastLifeApp: App {
    @State private var selectedTab: Int = 2  // Always start at Hub tab (index 2 - center tab)
    @State private var shouldPopToRoot = false  // Trigger navigation pop
    @State private var shouldResetToOnboarding = false  // Trigger full app reset
    @State private var isOnboardingComplete: Bool = UserDefaults.standard.bool(forKey: "onboardingCompleted")

    init() {
        // Initialize crash reporting system for production monitoring
        // Following Firebase Crashlytics setup guide for iOS
        // Reference: https://firebase.google.com/docs/crashlytics/get-started?platform=ios
        CrashReportManager.shared.initialize()

        // Set anonymous user context for crash reports (privacy-compliant)
        let anonymousUserID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        CrashReportManager.shared.setUserIdentifier(anonymousUserID)

        // Log app launch for production debugging
        CrashReportManager.shared.logCustomMessage("App launched successfully", level: .info)
    }

    var body: some Scene {
        WindowGroup {
            if isOnboardingComplete && !shouldResetToOnboarding {
                mainTabView
            } else {
                OnboardingView(isOnboardingComplete: $isOnboardingComplete)
                    .onAppear {
                        // Reset the flag when onboarding appears
                        shouldResetToOnboarding = false
                    }
            }
        }
    }

    private var mainTabView: some View {
        MainTabView(
            shouldPopToRoot: $shouldPopToRoot,
            shouldResetToOnboarding: $shouldResetToOnboarding,
            isOnboardingComplete: $isOnboardingComplete,
            selectedTab: $selectedTab,
            tabBinding: tabBinding
        )
    }

    // Custom binding to reset navigation to root when switching tabs
    // Following Apple HIG: "Tapping a currently selected tab should return to the top-level view"
    // Reference: https://developer.apple.com/design/human-interface-guidelines/tab-bars
    private var tabBinding: Binding<Int> {
        Binding(
            get: { selectedTab },
            set: { newValue in
                // Reset Hub tab to root view whenever selected (from any tab)
                // Industry Standard: Hub acts as "home" - always returns to main dashboard
                if newValue == 2 {
                    shouldPopToRoot = true
                }

                // Reset Me tab to root view whenever switching TO it
                // This ensures Me tab is always shown first
                if newValue == 4 {
                    shouldPopToRoot = true
                }
                selectedTab = newValue
            }
        )
    }
}

// MARK: - Main Tab View (Separate to defer FastingManager initialization)

struct MainTabView: View {
    @StateObject private var fastingManager = FastingManager()
    @StateObject private var hydrationManager = HydrationManager()
    @StateObject private var weightManager = WeightManager()
    @StateObject private var sleepManager = SleepManager()
    @StateObject private var moodManager = MoodManager()
    @StateObject private var behavioralScheduler = BehavioralNotificationScheduler()

    @Binding var shouldPopToRoot: Bool
    @Binding var shouldResetToOnboarding: Bool
    @Binding var isOnboardingComplete: Bool
    @Binding var selectedTab: Int
    let tabBinding: Binding<Int>

    var body: some View {
        TabView(selection: tabBinding) {
            // Stats tab - Analytics and cross-tracker insights
            LazyView(AnalyticsView())
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.xaxis")
                }
                .tag(0)

            // Coach tab - AI coaching and guidance (placeholder for now)
            LazyView(CoachView())
                .tabItem {
                    Label("Coach", systemImage: "person.crop.circle.badge.checkmark")
                }
                .tag(1)

            // Hub tab - Central dashboard
            HubView(shouldPopToRoot: $shouldPopToRoot)
                .environmentObject(fastingManager)
                .environmentObject(hydrationManager)
                .environmentObject(weightManager)
                .environmentObject(sleepManager)
                .environmentObject(moodManager)
                .environmentObject(behavioralScheduler)
                .tabItem {
                    Label("Hub", systemImage: "waveform.path.ecg")
                }
                .tag(2)

            // Learn tab - Educational content and insights
            LazyView(InsightsView())
                .tabItem {
                    Label("Learn", systemImage: "lightbulb.fill")
                }
                .tag(3)

            // Me tab - Settings, profile, and advanced features
            LazyView(
                AdvancedView(
                    shouldPopToRoot: $shouldPopToRoot,
                    shouldResetToOnboarding: $shouldResetToOnboarding,
                    isOnboardingComplete: $isOnboardingComplete,
                    selectedTab: $selectedTab
                )
                .environmentObject(fastingManager)
                .environmentObject(behavioralScheduler)
            )
            .tabItem {
                Label("Me", systemImage: "person.circle")
            }
            .tag(4)
        }
        .onAppear {
            // Load fasting history asynchronously after UI renders
            // This prevents blocking app launch with heavy data loading
            // History loads in background and displays inline in Hub tab (central dashboard pattern)
            fastingManager.loadHistoryAsync()
        }
    }
}


// MARK: - LazyView Wrapper for Tab Content Optimization

/// Defers view rendering until first access (lazy loading)
/// Per Apple SwiftUI Performance Guidelines: "Defer expensive work until views appear"
/// Reference: https://developer.apple.com/documentation/swiftui/view-performance
struct LazyView<Content: View>: View {
    let build: () -> Content

    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }

    var body: Content {
        build()
    }
}
