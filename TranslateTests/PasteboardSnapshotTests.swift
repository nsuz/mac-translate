import AppKit
import Testing
@testable import Translate

struct PasteboardSnapshotTests {
    private let pasteboard = NSPasteboard(name: NSPasteboard.Name("PasteboardSnapshotTests-\(UUID().uuidString)"))
    private let custom = NSPasteboard.PasteboardType("dev.nsuz.translate.test")

    @Test func restoresEveryItemWithAllOfItsTypes() {
        let first = NSPasteboardItem()
        first.setString("hello", forType: .string)
        first.setData(Data([1, 2, 3]), forType: custom)
        let second = NSPasteboardItem()
        second.setString("second", forType: .string)
        pasteboard.clearContents()
        pasteboard.writeObjects([first, second])

        let snapshot = PasteboardSnapshot(of: pasteboard)
        pasteboard.clearContents()
        pasteboard.setString("overwritten", forType: .string)
        snapshot.restore()

        let items = pasteboard.pasteboardItems ?? []
        #expect(items.count == 2)
        #expect(items.first?.string(forType: .string) == "hello")
        #expect(items.first?.data(forType: custom) == Data([1, 2, 3]))
        #expect(items.last?.string(forType: .string) == "second")
    }

    @Test func restoringAnEmptyPasteboardLeavesItEmpty() {
        pasteboard.clearContents()
        let snapshot = PasteboardSnapshot(of: pasteboard)
        pasteboard.setString("overwritten", forType: .string)
        snapshot.restore()
        #expect(pasteboard.pasteboardItems?.isEmpty == true)
    }
}
