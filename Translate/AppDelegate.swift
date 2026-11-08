import AppKit
import ApplicationServices
import os

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = AppModel()
    private var presenter: TranslationPresenter?
    private var hotKey: HotKey?
    private var hotKeyPresses: Task<Void, Never>?
    private var terminationAllowed = false
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Translate", category: "app")

    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt" as CFString: true] as CFDictionary)
        let presenter = TranslationPresenter(model: model)
        self.presenter = presenter
        do {
            let hotKey = try HotKey(.optionT)
            self.hotKey = hotKey
            hotKeyPresses = Task {
                for await _ in hotKey.presses { presenter.translateSelection() }
            }
        } catch {
            logger.error("hot key registration failed: \(error)")
        }
    }

    // ggml's Metal backend aborts in a static destructor if buffers outlive the process, so the
    // model must be freed before termination proceeds; `applicationWillTerminate` cannot wait.
    // The deadline is a separate task because a stuck model load cannot be cancelled, only outrun.
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        Task {
            await model.shutdown()
            allowTermination(of: sender)
        }
        Task {
            try? await Task.sleep(for: .seconds(10))
            allowTermination(of: sender)
        }
        return .terminateLater
    }

    private func allowTermination(of application: NSApplication) {
        guard !terminationAllowed else { return }
        terminationAllowed = true
        application.reply(toApplicationShouldTerminate: true)
    }
}
