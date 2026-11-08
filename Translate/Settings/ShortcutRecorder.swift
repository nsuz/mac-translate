import AppKit
import Carbon
import SwiftUI

/// Shows the shortcut and, when clicked, takes the next key press as the new one. A press
/// needs Command, Option or Control; Escape keeps the current shortcut. `isRecording` is
/// shared so the current shortcut can be suspended while a new one is typed.
struct ShortcutRecorder: View {
    @Binding var combination: KeyCombination
    @Binding var isRecording: Bool
    @State private var monitor: Any?

    var body: some View {
        Button(isRecording ? "Type a shortcut…" : combination.display) {
            isRecording ? stopRecording() : startRecording()
        }
        .onDisappear(perform: stopRecording)
    }

    private func startRecording() {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            record(event)
            return nil
        }
    }

    private func stopRecording() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        isRecording = false
    }

    private func record(_ event: NSEvent) {
        if event.keyCode == UInt16(kVK_Escape) { return stopRecording() }
        let modifiers = KeyCombination.Modifiers(event.modifierFlags)
        guard !modifiers.isDisjoint(with: [.command, .option, .control]),
              let key = event.charactersIgnoringModifiers, key.count == 1,
              let character = key.first, character.isLetter || character.isNumber || character.isPunctuation || character.isSymbol
        else { return }
        combination = KeyCombination(keyCode: UInt32(event.keyCode), modifiers: modifiers, key: key.uppercased())
        stopRecording()
    }
}
