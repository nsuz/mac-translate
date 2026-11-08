import AppKit
import Carbon

/// The selection as the app itself copies it, HTML included, which is the only way to learn
/// that it was a list. The pasteboard is put back afterwards as far as can be told:
/// `changeCount` only says that someone wrote, not who, so the old contents go back only
/// when the frontmost app stayed the same and nothing else wrote between the read and the restore.
enum CopiedSelection {
    struct Contents {
        var html: String?
        var string: String?

        /// List markers from the HTML when there is any; otherwise the plain string.
        var text: String? {
            html.flatMap(StructuredText.plain(fromHTML:)) ?? string
        }
    }

    /// Returns nil when nothing arrived within 200 ms, which is also what an empty selection
    /// looks like, or when the frontmost app changed meanwhile. The pasteboard is then left alone.
    static func read() async -> Contents? {
        let pasteboard = NSPasteboard.general
        let frontmost = NSWorkspace.shared.frontmostApplication?.processIdentifier
        let before = pasteboard.changeCount
        let snapshot = PasteboardSnapshot(of: pasteboard)
        postCommandC()
        for _ in 0..<20 where pasteboard.changeCount == before {
            try? await Task.sleep(for: .milliseconds(10))
        }
        let copied = pasteboard.changeCount
        guard copied != before, NSWorkspace.shared.frontmostApplication?.processIdentifier == frontmost else { return nil }
        let contents = Contents(html: pasteboard.string(forType: .html), string: pasteboard.string(forType: .string))
        if pasteboard.changeCount == copied { snapshot.restore() }
        return contents
    }

    /// Needs the Accessibility permission, the same one the Accessibility read already has.
    private static func postCommandC() {
        for keyDown in [true, false] {
            let event = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: keyDown)
            event?.flags = .maskCommand
            event?.post(tap: .cghidEventTap)
        }
    }
}

/// The items on a pasteboard with every type they carry, so they can be written back.
struct PasteboardSnapshot {
    private let pasteboard: NSPasteboard
    private let items: [[NSPasteboard.PasteboardType: Data]]

    init(of pasteboard: NSPasteboard) {
        self.pasteboard = pasteboard
        items = (pasteboard.pasteboardItems ?? []).map { item in
            Dictionary(uniqueKeysWithValues: item.types.compactMap { type in item.data(forType: type).map { (type, $0) } })
        }
    }

    func restore() {
        pasteboard.clearContents()
        pasteboard.writeObjects(items.map { types in
            let item = NSPasteboardItem()
            for (type, data) in types { item.setData(data, forType: type) }
            return item
        })
    }
}
