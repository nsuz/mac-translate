import SwiftUI

@main
struct TranslateApp: App {
    @NSApplicationDelegateAdaptor private var delegate: AppDelegate

    var body: some Scene {
        MenuBarExtra("Translate", systemImage: "translate") {
            MenuBarMenu(delegate: delegate)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(model: delegate.model)
        }
    }
}

private struct MenuBarMenu: View {
    let delegate: AppDelegate
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button("Models…") { delegate.showModels() }
        // `SettingsLink` does nothing from a menu bar extra while the app is inactive.
        Button("Settings…") {
            NSApp.activate()
            openSettings()
        }
        .keyboardShortcut(",")
        Divider()
        Button("Quit Translate") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}
