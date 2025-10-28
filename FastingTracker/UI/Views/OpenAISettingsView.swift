//
// OpenAISettingsView.swift
// FastingTracker
//
// Created for Phase 6: LLM Intelligence Integration
// API key configuration UI for AInstein intelligence
//

import SwiftUI
import os.log

struct OpenAISettingsView: View {

    // MARK: - Properties

    @AppStorage("openai_api_key") private var apiKey: String = ""
    @State private var isKeyVisible: Bool = false
    @State private var isTestingConnection: Bool = false
    @State private var testResult: String?
    @State private var testError: String?

    private let logger = Logger(subsystem: "com.fastlife.FastingTracker", category: "Settings")

    // MARK: - Body

    var body: some View {
        Form {
            // API Key Input Section
            Section(header: Text("OpenAI API Key")) {
                HStack {
                    if isKeyVisible {
                        TextField("sk-...", text: $apiKey)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .font(Theme.Font.body(15))
                    } else {
                        SecureField("sk-...", text: $apiKey)
                            .font(Theme.Font.body(15))
                    }

                    Button(action: { isKeyVisible.toggle() }) {
                        Image(systemName: isKeyVisible ? "eye.slash" : "eye")
                            .foregroundColor(Theme.ColorToken.textSecondary)
                    }
                }
            }

            // Test Connection Section
            Section {
                Button(action: testConnection) {
                    HStack {
                        if isTestingConnection {
                            ProgressView()
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: "network")
                                .foregroundColor(Theme.ColorToken.accentPrimary)
                        }

                        Text("Test Connection")
                            .font(Theme.Font.body(17))
                            .foregroundColor(Theme.ColorToken.textPrimary)

                        Spacer()
                    }
                }
                .disabled(apiKey.isEmpty || isTestingConnection)

                // Test Result
                if let result = testResult {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Connection Successful")
                                .font(Theme.Font.headline(15))
                                .foregroundColor(.green)
                        }

                        Text(result)
                            .font(Theme.Font.body(14))
                            .foregroundColor(Theme.ColorToken.textSecondary)
                            .lineLimit(3)
                    }
                    .padding(.top, 8)
                }

                // Test Error
                if let error = testError {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                            Text("Connection Failed")
                                .font(Theme.Font.headline(15))
                                .foregroundColor(.red)
                        }

                        Text(error)
                            .font(Theme.Font.body(14))
                            .foregroundColor(Theme.ColorToken.textSecondary)
                            .lineLimit(3)
                    }
                    .padding(.top, 8)
                }
            }

            // Instructions Section
            Section(footer: instructionsFooter) {
                EmptyView()
            }
        }
        .navigationTitle("AInstein Intelligence")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Footer

    private var instructionsFooter: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Get your API key from platform.openai.com")
                .font(Theme.Font.body(13))
                .foregroundColor(Theme.ColorToken.textSecondary)

            Text("Your key is stored securely on device and never shared. AInstein uses GPT-4o-mini for intelligent health coaching.")
                .font(Theme.Font.body(13))
                .foregroundColor(Theme.ColorToken.textSecondary)

            Text("Cost: ~$1-3/month per user based on usage.")
                .font(Theme.Font.body(13))
                .foregroundColor(Theme.ColorToken.textSecondary)
        }
    }

    // MARK: - Actions

    /// Test OpenAI API connection
    private func testConnection() {
        logger.info("Testing OpenAI API connection")

        // Clear previous results
        testResult = nil
        testError = nil
        isTestingConnection = true

        Task {
            do {
                let response = try await OpenAIService.shared.testConnection()

                await MainActor.run {
                    testResult = response
                    testError = nil
                    isTestingConnection = false
                    logger.info("OpenAI API test successful")
                }

            } catch {
                await MainActor.run {
                    testResult = nil
                    testError = error.localizedDescription
                    isTestingConnection = false
                    logger.error("OpenAI API test failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("API Key Empty") {
    NavigationStack {
        OpenAISettingsView()
    }
}

#Preview("API Key Entered") {
    NavigationStack {
        OpenAISettingsView()
    }
    .onAppear {
        UserDefaults.standard.set("sk-test-key-12345", forKey: "openai_api_key")
    }
}
