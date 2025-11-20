import SwiftUI
import UniformTypeIdentifiers

struct WeightControlCenterDataManagementCard: View {
    @ObservedObject var viewModel: WeightControlCenterViewModel
    @Binding var showDeleteAllConfirmation: Bool

    @State private var exportedFileURL: URL?
    @State private var showingShareSheet = false
    @State private var showingFileImporter = false
    @State private var alertMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.cardPadding) {
            Text("Export, import, or delete your weight data with enterprise-grade security.")
                .font(DSTypography.cardBody)
                .foregroundColor(Theme.ColorToken.textSecondaryOnDark)

            actionButton(
                title: viewModel.isExportingData ? "Exporting…" : "Export Data",
                icon: "square.and.arrow.up",
                background: Theme.ColorToken.accentPrimary,
                isBusy: viewModel.isExportingData
            ) {
                exportData()
            }
            .disabled(viewModel.isExportingData)

            actionButton(
                title: viewModel.isImportingData ? "Importing…" : "Import Backup",
                icon: "square.and.arrow.down",
                background: Theme.ColorToken.accentInfo,
                isBusy: viewModel.isImportingData
            ) {
                showingFileImporter = true
            }
            .disabled(viewModel.isImportingData)

            actionButton(
                title: "Delete All Weight Data",
                icon: "trash",
                background: Theme.ColorToken.stateError.opacity(0.2),
                foreground: Theme.ColorToken.stateError
            ) {
                showDeleteAllConfirmation = true
            }

            if let status = viewModel.lastExportStatus {
                statusRow(icon: "square.and.arrow.up", text: status)
            }

            if let status = viewModel.lastImportStatus {
                statusRow(icon: "square.and.arrow.down", text: status)
            }
        }
        .sheet(isPresented: $showingShareSheet, onDismiss: cleanupExportFile) {
            if let url = exportedFileURL {
                ShareSheet(items: [url])
            }
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.commaSeparatedText, .text, .plainText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else {
                    alertMessage = "No file selected."
                    return
                }
                importData(from: url)
            case .failure:
                alertMessage = "Unable to read the selected file."
            }
        }
        .alert("Data Management", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private func exportData() {
        Task {
            do {
                let url = try await viewModel.exportWeightData()
                exportedFileURL = url
                showingShareSheet = true
            } catch {
                alertMessage = error.localizedDescription
            }
        }
    }

    private func importData(from url: URL) {
        Task {
            do {
                let summary = try await viewModel.importWeightData(from: url)
                alertMessage = "Imported \(summary.imported) entries (\(summary.skipped) skipped)."
            } catch {
                alertMessage = error.localizedDescription
            }
        }
    }

    private func cleanupExportFile() {
        if let url = exportedFileURL {
            try? FileManager.default.removeItem(at: url)
        }
        exportedFileURL = nil
    }

    private func actionButton(
        title: String,
        icon: String,
        background: Color,
        foreground: Color = Theme.ColorToken.textPrimaryOnDark,
        isBusy: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: DSSpacing.cardSmallSpacing) {
                if isBusy {
                    ProgressView()
                        .tint(foreground)
                } else {
                    Image(systemName: icon)
                        .font(DSTypography.cardTitle)
                }
                Text(title)
                    .font(DSTypography.cardTitle)
            }
            .foregroundColor(foreground)
            .frame(maxWidth: .infinity)
            .padding(DSSpacing.cardElementSpacing)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(foreground.opacity(0.3), lineWidth: background == Theme.ColorToken.accentPrimary ? 0 : 1)
                    )
            )
        }
    }

    private func statusRow(icon: String, text: String) -> some View {
        HStack(spacing: DSSpacing.cardSmallSpacing) {
            Image(systemName: icon)
                .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
            Text(text)
                .font(DSTypography.cardCaption)
                .foregroundColor(Theme.ColorToken.textSecondaryOnDark)
        }
        .padding(.top, DSSpacing.cardExtraSmallSpacing)
    }
}
