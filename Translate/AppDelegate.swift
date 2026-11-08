import AppKit
import ApplicationServices
import TranslateCore
import os

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = AppModel()
    private lazy var windows = AppWindows(model: model)
    private var presenter: TranslationPresenter?
    private var hotKey: HotKey?
    private var hotKeyPresses: Task<Void, Never>?
    private var terminationAllowed = false
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Translate", category: "app")

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            try model.store.removeIncompleteDownloads()
        } catch {
            logger.error("removing incomplete downloads failed: \(error)")
        }
        let presenter = TranslationPresenter(model: model, windows: windows)
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
        if !AXIsProcessTrusted() {
            windows.showOnboarding()
        } else if !model.isModelAvailable {
            windows.showModels()
        }
        // ggml installs its own C++ terminate handler, which aborts without printing the
        // NSException reason the default one would, so record it before the process dies.
        NSSetUncaughtExceptionHandler { exception in
            Logger(subsystem: Bundle.main.bundleIdentifier ?? "Translate", category: "crash").fault(
                "uncaught \(exception.name.rawValue, privacy: .public): \(exception.reason ?? "", privacy: .public)\n\(exception.callStackSymbols.joined(separator: "\n"), privacy: .public)"
            )
        }
    }

    func showModels() {
        windows.showModels()
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
