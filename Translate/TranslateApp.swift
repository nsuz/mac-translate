import SwiftUI

@main
struct TranslateApp: App {
    @NSApplicationDelegateAdaptor private var delegate: AppDelegate

    var body: some Scene {
        MenuBarExtra("Translate", systemImage: "translate") {
            Button("Models…") { delegate.showModels() }
            Divider()
            Button("Quit Translate") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }
        .menuBarExtraStyle(.menu)
    }
}
