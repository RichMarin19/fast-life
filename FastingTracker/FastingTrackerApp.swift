import SwiftUI

@main
struct FastLifeApp: App {
    @StateObject private var fastingManager = FastingManager()
    @State private var selectedTab: Int = 0  // Always start at Timer tab (index 0)
    @State private var shouldPopToRoot = false  // Trigger navigation pop

    init() {
        NotificationManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            TabView(selection: tabBinding) {
                ContentView()
                    .environmentObject(fastingManager)
                    .tabItem {
                        Label("Timer", systemImage: "clock")
                    }
                    .tag(0)

                InsightsView()
                    .tabItem {
                        Label("Insights", systemImage: "lightbulb.fill")
                    }
                    .tag(1)

                HistoryView()
                    .environmentObject(fastingManager)
                    .tabItem {
                        Label("History", systemImage: "list.bullet")
                    }
                    .tag(2)

                AdvancedView(shouldPopToRoot: $shouldPopToRoot)
                    .environmentObject(fastingManager)
                    .tabItem {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                    .tag(3)
            }
        }
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
