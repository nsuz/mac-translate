import AppKit
import SwiftUI

/// The app's two ordinary windows, brought forward on demand. They are AppKit windows
/// because they open from the shortcut path, outside any SwiftUI view. The window outlives
/// its content so it keeps its place; the content is rebuilt on every show so it reflects the
/// current state, and dropped on close so nothing keeps polling behind a closed window.
final class AppWindows: NSObject, NSWindowDelegate {
    private enum Kind {
        case onboarding, models
    }

    private let model: AppModel
    private var windows: [Kind: NSWindow] = [:]

    init(model: AppModel) {
        self.model = model
    }

    func showOnboarding() {
        show(.onboarding, title: "Welcome to Translate") {
            OnboardingView(model: model, openModels: { [self] in showModels() }, done: { [self] in close(.onboarding) })
        }
    }

    func showModels() {
        show(.models, title: "Models") {
            ModelsView(model: model, done: { [self] in close(.models) })
        }
    }

    private func show(_ kind: Kind, title: String, content: () -> some View) {
        let isNew = windows[kind] == nil
        let window = windows[kind] ?? makeWindow(kind, title: title)
        let host = NSHostingController(rootView: content())
        window.contentViewController = host
        window.setContentSize(host.view.fittingSize)
        if isNew { window.center() }
        // Activation is a request the system may decline; the window must show either way.
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    private func makeWindow(_ kind: Kind, title: String) -> NSWindow {
        let window = NSWindow(contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = title
        window.isReleasedWhenClosed = false
        window.delegate = self
        windows[kind] = window
        return window
    }

    private func close(_ kind: Kind) {
        windows[kind]?.close()
    }

    func windowWillClose(_ notification: Notification) {
        (notification.object as? NSWindow)?.contentViewController = nil
    }
}
