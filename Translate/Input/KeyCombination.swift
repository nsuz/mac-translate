import AppKit

/// A key with modifiers, as the user pressed it. `key` is the character to show, captured
/// when recording, so the display does not depend on the current keyboard layout.
struct KeyCombination: Codable, Hashable, Sendable {
    struct Modifiers: OptionSet, Codable, Hashable, Sendable {
        let rawValue: Int

        static let control = Modifiers(rawValue: 1 << 0)
        static let option = Modifiers(rawValue: 1 << 1)
        static let shift = Modifiers(rawValue: 1 << 2)
        static let command = Modifiers(rawValue: 1 << 3)

        init(rawValue: Int) {
            self.rawValue = rawValue
        }

        init(_ flags: NSEvent.ModifierFlags) {
            var modifiers = Modifiers()
            if flags.contains(.control) { modifiers.insert(.control) }
            if flags.contains(.option) { modifiers.insert(.option) }
            if flags.contains(.shift) { modifiers.insert(.shift) }
            if flags.contains(.command) { modifiers.insert(.command) }
            self = modifiers
        }
    }

    var keyCode: UInt32
    var modifiers: Modifiers
    var key: String

    /// Apple's order for modifier symbols: control, option, shift, command.
    var display: String {
        var symbols = ""
        if modifiers.contains(.control) { symbols += "⌃" }
        if modifiers.contains(.option) { symbols += "⌥" }
        if modifiers.contains(.shift) { symbols += "⇧" }
        if modifiers.contains(.command) { symbols += "⌘" }
        return symbols + key
    }
}
