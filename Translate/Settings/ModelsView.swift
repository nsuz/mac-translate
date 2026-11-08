import SwiftUI
import TranslateCore

struct ModelsView: View {
    let model: AppModel
    let done: () -> Void
    @AppStorage(Preferences.acceptedLicense) private var acceptedLicense = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(model.variant.displayName).font(.headline)
                Spacer()
                Text(model.variant.byteCount, format: .byteCount(style: .file)).foregroundStyle(.secondary)
            }
            if model.isModelAvailable {
                Label("Downloaded", systemImage: "checkmark.circle.fill")
            } else {
                switch model.download {
                case .downloading(let bytesWritten):
                    ProgressView(value: Double(bytesWritten), total: Double(model.variant.byteCount))
                    HStack {
                        Text(bytesWritten, format: .byteCount(style: .file)).foregroundStyle(.secondary)
                        Spacer()
                        Button("Cancel", action: model.cancelDownload)
                    }
                case .verifying:
                    ProgressView()
                    Text("Verifying…").foregroundStyle(.secondary)
                case .failed(let error):
                    Label(message(for: error), systemImage: "exclamationmark.triangle")
                    Button("Try Again", action: model.downloadModel)
                case nil:
                    license
                    Button("Download", action: model.downloadModel)
                        .disabled(!acceptedLicense)
                }
            }
            if !isTransferring {
                HStack {
                    Spacer()
                    Button("Done", action: done).keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(24)
        .frame(width: 440)
    }

    private var isTransferring: Bool {
        switch model.download {
        case .downloading, .verifying: true
        case .failed, nil: false
        }
    }

    private var license: some View {
        GroupBox("PLaMo Community License") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Personal and non-commercial use, including academic use, is free with no registration.")
                Text("Commercial use with revenue of 1 billion yen or less is free after registering with PFN.")
                Text("Commercial use above that requires a separate agreement with PFN.")
                HStack {
                    Link("Full text (English)", destination: URL(string: "https://plamo.preferredai.jp/info/plamo-community-license-en")!)
                    Link("全文（日本語）", destination: URL(string: "https://plamo.preferredai.jp/info/plamo-community-license-ja")!)
                }
                Toggle("I accept the PLaMo Community License", isOn: $acceptedLicense)
            }
            .padding(4)
        }
    }

    private func message(for error: any Error) -> LocalizedStringKey {
        switch error {
        case ModelDownloadError.checksumMismatch:
            "The downloaded file didn’t match the expected checksum."
        case ModelDownloadError.unexpectedResponse(let statusCode):
            "The server answered with status \(statusCode)."
        default:
            "\(error.localizedDescription)"
        }
    }
}
