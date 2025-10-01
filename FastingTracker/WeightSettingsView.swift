import SwiftUI

struct WeightSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var weightManager: WeightManager
    @Binding var showGoalLine: Bool
    @Binding var weightGoal: Double

    @State private var weightGoalString: String = ""
    @State private var localSyncEnabled: Bool = true
    @State private var isSyncing: Bool = false
    @State private var showingSyncAlert: Bool = false
    @State private var syncMessage: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Apple Health Integration")) {
                    Toggle("Sync with Apple Health", isOn: $localSyncEnabled)
                        .onChange(of: localSyncEnabled) { _, newValue in
                            weightManager.setSyncPreference(newValue)
                        }

                    if localSyncEnabled {
                        Button(action: {
                            syncWithHealthKit()
                        }) {
                            HStack {
                                if isSyncing {
                                    ProgressView()
                                        .padding(.trailing, 4)
                                } else {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                }
                                Text(isSyncing ? "Syncing..." : "Sync Now")
                            }
                        }
                        .disabled(isSyncing)
                    }

                    Text("When enabled, weight entries will be synced with Apple Health automatically.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Weight Goal")) {
                    Toggle("Show Goal Line on Chart", isOn: $showGoalLine)

                    if showGoalLine {
                        HStack {
                            Text("Goal Weight")
                            TextField("Enter goal", text: $weightGoalString)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .onAppear {
                                    weightGoalString = String(format: "%.1f", weightGoal)
                                }
                            Text("lbs")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section(header: Text("About")) {
                    HStack {
                        Text("Total Entries")
                        Spacer()
                        Text("\(weightManager.weightEntries.count)")
                            .foregroundColor(.secondary)
                    }

                    if let oldest = weightManager.weightEntries.last {
                        HStack {
                            Text("Tracking Since")
                            Spacer()
                            Text(oldest.date, style: .date)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Weight Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Update weight goal if valid
                        if let newGoal = Double(weightGoalString), newGoal > 0 {
                            weightGoal = newGoal
                        }
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            localSyncEnabled = weightManager.syncWithHealthKit
            weightGoalString = String(format: "%.1f", weightGoal)
        }
        .alert("Sync Status", isPresented: $showingSyncAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(syncMessage)
        }
    }

    private func syncWithHealthKit() {
        isSyncing = true

        // Check if HealthKit is authorized
        if !HealthKitManager.shared.isAuthorized {
            // Request authorization first
            HealthKitManager.shared.requestAuthorization { success, error in
                if success {
                    // Authorization granted, now sync
                    performSync()
                } else {
                    isSyncing = false
                    syncMessage = error?.localizedDescription ?? "Failed to authorize HealthKit access. Please check Settings > Health > Data Access & Devices."
                    showingSyncAlert = true
                }
            }
        } else {
            // Already authorized, just sync
            performSync()
        }
    }

    private func performSync() {
        weightManager.syncFromHealthKit()

        // Give it a moment to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSyncing = false
            let count = weightManager.weightEntries.count
            syncMessage = count > 0 ? "Successfully synced \(count) weight entries from Apple Health." : "No weight data found in Apple Health."
            showingSyncAlert = true
        }
    }
}

#Preview {
    WeightSettingsView(
        weightManager: WeightManager(),
        showGoalLine: .constant(true),
        weightGoal: .constant(180.0)
    )
}
