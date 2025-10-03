import SwiftUI

@main
struct FastLifeApp: App {
    @State private var selectedTab: Int = 0  // Always start at Timer tab (index 0)
    @State private var shouldPopToRoot = false  // Trigger navigation pop
    @State private var shouldResetToOnboarding = false  // Trigger full app reset
    @State private var isOnboardingComplete: Bool = UserDefaults.standard.bool(forKey: "onboardingCompleted")

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

    // Custom binding to reset More tab navigation to root when switching tabs
    private var tabBinding: Binding<Int> {
        Binding(
            get: { selectedTab },
            set: { newValue in
                // Reset More tab to root view whenever switching TO it
                // This ensures Advanced Features is always shown first
                if newValue == 3 {
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

    @Binding var shouldPopToRoot: Bool
    @Binding var shouldResetToOnboarding: Bool
    @Binding var isOnboardingComplete: Bool
    @Binding var selectedTab: Int
    let tabBinding: Binding<Int>

    var body: some View {
        TabView(selection: tabBinding) {
            // Timer tab - Always loaded (default tab)
            ContentView()
                .environmentObject(fastingManager)
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

            // History tab - Lazy loaded (expensive: charts, calendar, stats)
            LazyView(
                HistoryView()
                    .environmentObject(fastingManager)
            )
            .tabItem {
                Label("History", systemImage: "list.bullet")
            }
            .tag(2)

            // More tab - Lazy loaded (navigation stack)
            LazyView(
                AdvancedView(
                    shouldPopToRoot: $shouldPopToRoot,
                    shouldResetToOnboarding: $shouldResetToOnboarding,
                    isOnboardingComplete: $isOnboardingComplete,
                    selectedTab: $selectedTab
                )
                .environmentObject(fastingManager)
            )
            .tabItem {
                Label("More", systemImage: "ellipsis.circle")
            }
            .tag(3)
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
