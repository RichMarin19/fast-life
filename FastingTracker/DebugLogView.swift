import SwiftUI

/// Hidden debug screen for controlling log levels in runtime
/// Access: Tap version number 5 times in Settings/About
struct DebugLogView: View {
    @Environment(\.dismiss) var dismiss

    @State private var selectedLevel: LogLevel

    init() {
        _selectedLevel = State(initialValue: Log.getRuntimeLevel())
    }

    var body: some View {
        NavigationView {
            Form {
                Section(
                    header: Text("Runtime Log Level"),
                    footer: Text(
                        "Controls which logs appear in Console.app and Instruments. Changes take effect immediately. Default levels:\n• DEBUG build: .debug (all logs)\n• TESTFLIGHT build: .info\n• RELEASE build: .notice"
                    )
                ) {
                    Picker("Log Level", selection: self.$selectedLevel) {
                        Text("🔍 Debug (Verbose)").tag(LogLevel.debug)
                        Text("ℹ️ Info").tag(LogLevel.info)
                        Text("📢 Notice (Default)").tag(LogLevel.notice)
                        Text("⚠️ Warning").tag(LogLevel.warning)
                        Text("❌ Error").tag(LogLevel.error)
                        Text("💥 Fault (Critical)").tag(LogLevel.fault)
                    }
                    .pickerStyle(.inline)
                    .onChange(of: self.selectedLevel) { _, newValue in
                        Log.setRuntimeLevel(newValue)
                    }
                }

                Section(header: Text("Current Configuration")) {
                    HStack {
                        Text("Build Type")
                        Spacer()
                        #if DEBUG
                            Text("DEBUG").foregroundColor(.orange)
                        #elseif TESTFLIGHT
                            Text("TESTFLIGHT").foregroundColor(.blue)
                        #else
                            Text("RELEASE").foregroundColor(.green)
                        #endif
                    }

                    HStack {
                        Text("Active Log Level")
                        Spacer()
                        Text(self.logLevelName(self.selectedLevel))
                            .foregroundColor(.secondary)
                    }
                }

                Section(
                    header: Text("Log Categories"),
                    footer: Text("All categories use the selected log level above.")
                ) {
                    ForEach([
                        ("HealthKit", LogCategory.healthkit),
                        ("Weight", LogCategory.weight),
                        ("Sleep", LogCategory.sleep),
                        ("Hydration", LogCategory.hydration),
                        ("Fasting", LogCategory.fasting),
                        ("Charts", LogCategory.charts),
                        ("Notifications", LogCategory.notifications),
                        ("Onboarding", LogCategory.onboarding),
                        ("Settings", LogCategory.settings),
                        ("Storage", LogCategory.storage),
                        ("Performance", LogCategory.performance),
                        ("General", LogCategory.general),
                    ], id: \.0) { name, category in
                        HStack {
                            Text(name)
                            Spacer()
                            Text(category.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section(header: Text("How to View Logs")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("**Console.app (Mac)**")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(
                            "1. Connect device to Mac\n2. Open Console.app\n3. Select device in sidebar\n4. Filter: subsystem:ai.fastlife.app"
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)

                        Divider()

                        Text("**Instruments (Performance)**")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(
                            "1. Open Xcode → Product → Profile\n2. Choose 'os_signpost' template\n3. View chart rendering & sync performance"
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }

                Section {
                    Button(action: {
                        // Reset to default
                        #if DEBUG
                            Log.setRuntimeLevel(.debug)
                        #elseif TESTFLIGHT
                            Log.setRuntimeLevel(.info)
                        #else
                            Log.setRuntimeLevel(.notice)
                        #endif
                        self.selectedLevel = Log.getRuntimeLevel()
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset to Default")
                        }
                    }
                }
            }
            .navigationTitle("Debug Logging")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        self.dismiss()
                    }
                }
            }
        }
        .onAppear {
            // Log that debug screen was opened
            Log.notice("Debug log screen opened", category: .settings)
        }
    }

    private func logLevelName(_ level: LogLevel) -> String {
        switch level {
        case .debug: return "Debug"
        case .info: return "Info"
        case .notice: return "Notice"
        case .warning: return "Warning"
        case .error: return "Error"
        case .fault: return "Fault"
        }
    }
}

#Preview {
    DebugLogView()
}
