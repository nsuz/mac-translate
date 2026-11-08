import ApplicationServices
import SwiftUI

struct OnboardingView: View {
    let model: AppModel
    let openModels: () -> Void
    let done: () -> Void
    @State private var isTrusted = AXIsProcessTrusted()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Translate the text you select in any app, right where you are.")
                Text("Nothing leaves your Mac. Translation runs on-device with PLaMo 3 Translate, and it can be wrong.")
                Text("Press \(model.hotKey.display) on selected text to see the translation.")
            }
            step("Accessibility", done: isTrusted) {
                Text("Translate reads the selected text through Accessibility.")
                Button("Allow Access…") {
                    _ = AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt" as CFString: true] as CFDictionary)
                }
            }
            step("Model", done: model.isModelAvailable) {
                Text("Download the model once to start translating.")
                Button("Download Model…", action: openModels)
            }
            HStack {
                Spacer()
                Button("Done", action: done).keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 440)
        // Polled while shown: the grant arrives from System Settings, and so can its revocation.
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                isTrusted = AXIsProcessTrusted()
            }
        }
    }

    private func step(_ title: LocalizedStringKey, done: Bool, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(title).font(.headline)
            } icon: {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(done ? Color.accentColor : Color.secondary)
            }
            if !done { content() }
        }
    }
}
