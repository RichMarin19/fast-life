import SwiftUI

@main
struct FastLifeApp: App {
    @StateObject private var fastingManager = FastingManager()

    init() {
        NotificationManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .environmentObject(fastingManager)
                    .tabItem {
                        Label("Timer", systemImage: "clock")
                    }

                InsightsView()
                    .tabItem {
                        Label("Insights", systemImage: "lightbulb.fill")
                    }

                HistoryView()
                    .environmentObject(fastingManager)
                    .tabItem {
                        Label("History", systemImage: "list.bullet")
                    }
            }
        }
    }
}
