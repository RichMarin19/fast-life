import SwiftUI

@main
struct FastLifeApp: App {
    @StateObject private var fastingManager = FastingManager()
    @State private var selectedTab: Int = 0  // Always start at Timer tab (index 0)

    init() {
        NotificationManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
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

                AdvancedView()
                    .environmentObject(fastingManager)
                    .tabItem {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                    .tag(3)
            }
        }
    }
}
