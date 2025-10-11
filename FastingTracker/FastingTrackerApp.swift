import SwiftUI

@main
struct FastLifeApp: App {
    @State private var selectedTab: Int = 0 // Always start at Timer tab (index 0)
    @State private var shouldPopToRoot = false // Trigger navigation pop
    @State private var shouldResetToOnboarding = false // Trigger full app reset
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
            if self.isOnboardingComplete, !self.shouldResetToOnboarding {
                self.mainTabView
            } else {
                OnboardingView(isOnboardingComplete: self.$isOnboardingComplete)
                    .onAppear {
                        // Reset the flag when onboarding appears
                        self.shouldResetToOnboarding = false
                    }
            }
        }
    }

    private var mainTabView: some View {
        MainTabView(
            shouldPopToRoot: self.$shouldPopToRoot,
            shouldResetToOnboarding: self.$shouldResetToOnboarding,
            isOnboardingComplete: self.$isOnboardingComplete,
            selectedTab: self.$selectedTab,
            tabBinding: self.tabBinding
        )
    }

    // Custom binding to reset More tab navigation to root when switching tabs
    private var tabBinding: Binding<Int> {
        Binding(
            get: { self.selectedTab },
            set: { newValue in
                // Reset More tab to root view whenever switching TO it
                // This ensures Advanced Features is always shown first
                if newValue == 3 {
                    self.shouldPopToRoot = true
                }
                self.selectedTab = newValue
            }
        )
    }
}

// MARK: - Main Tab View (Separate to defer FastingManager initialization)

struct MainTabView: View {
    @StateObject private var fastingManager = FastingManager()

    @Binding var shouldPopToRoot: Bool
    @Binding var shouldResetToOnboarding: Bool
    @Binding var isOnboardingComplete: Bool
    @Binding var selectedTab: Int
    let tabBinding: Binding<Int>

    var body: some View {
        TabView(selection: self.tabBinding) {
            // Timer tab - Always loaded (default tab)
            ContentView()
                .environmentObject(self.fastingManager)
                .tabItem {
                    Label("Timer", systemImage: "clock")
                }
                .tag(0)

            // Insights tab - Lazy loaded when user first navigates to it
            LazyView(InsightsView())
                .tabItem {
                    Label("Insights", systemImage: "lightbulb.fill")
                }
                .tag(1)

            // Analytics tab - Lazy loaded (cross-tracker insights coming soon)
            LazyView(AnalyticsView())
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.xaxis")
                }
                .tag(2)

            // More tab - Lazy loaded (navigation stack)
            LazyView(
                AdvancedView(
                    shouldPopToRoot: self.$shouldPopToRoot,
                    shouldResetToOnboarding: self.$shouldResetToOnboarding,
                    isOnboardingComplete: self.$isOnboardingComplete,
                    selectedTab: self.$selectedTab
                )
                .environmentObject(self.fastingManager)
            )
            .tabItem {
                Label("More", systemImage: "ellipsis.circle")
            }
            .tag(3)
        }
        .onAppear {
            // Load fasting history asynchronously after UI renders
            // This prevents blocking app launch with heavy data loading
            // History loads in background and displays inline in Timer tab (like Weight Tracker pattern)
            self.fastingManager.loadHistoryAsync()
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
        self.build()
    }
}
