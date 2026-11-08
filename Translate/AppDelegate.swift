import AppKit
import ApplicationServices
import TranslateCore
import os

final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()
    private lazy var windows = AppWindows(model: model)
    private lazy var presenter = TranslationPresenter(model: model, windows: windows)
    private var serviceProvider: ServiceProvider?
    private var hotKey: HotKey?
    private var hotKeyChanges: Task<Void, Never>?
    private var terminationAllowed = false
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Translate", category: "app")

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            try model.store.removeIncompleteDownloads()
        } catch {
            logger.error("removing incomplete downloads failed: \(error)")
        }
        hotKeyChanges = Task {
            for await (combination, isRecording) in Observations({ (self.model.hotKey, self.model.isRecordingShortcut) }) {
                hotKey?.unregister()
                hotKey = nil
                if !isRecording { registerHotKey(combination) }
            }
        }
        let serviceProvider = ServiceProvider { [presenter] text in presenter.translate(text) }
        self.serviceProvider = serviceProvider
        NSApp.servicesProvider = serviceProvider
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

    func translateClipboard() {
        presenter.translateClipboard()
    }

    private func registerHotKey(_ combination: KeyCombination) {
        do {
            let hotKey = try HotKey(combination)
            self.hotKey = hotKey
            Task {
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
