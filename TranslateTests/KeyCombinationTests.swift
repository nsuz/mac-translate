import AppKit
import Carbon
import Testing
@testable import Translate

struct KeyCombinationTests {
    @Test func modifiersComeFromTheDeviceIndependentEventFlags() {
        let modifiers = KeyCombination.Modifiers([.option, .shift, .numericPad])
        #expect(modifiers == [.option, .shift])
    }

    @Test func modifiersConvertToCarbonFlags() {
        #expect(KeyCombination.Modifiers.command.carbonFlags == UInt32(cmdKey))
        #expect(KeyCombination.Modifiers.option.carbonFlags == UInt32(optionKey))
        #expect(KeyCombination.Modifiers.control.carbonFlags == UInt32(controlKey))
        #expect(KeyCombination.Modifiers.shift.carbonFlags == UInt32(shiftKey))
        #expect(KeyCombination.Modifiers([.command, .option]).carbonFlags == UInt32(cmdKey | optionKey))
    }

    @Test func displayOrdersModifiersTheWayAppleDoes() {
        let combination = KeyCombination(keyCode: 0, modifiers: [.command, .control, .shift, .option], key: "A")
        #expect(combination.display == "⌃⌥⇧⌘A")
        #expect(KeyCombination.optionT.display == "⌥T")
    }

    @Test func survivesAUserDefaultsRoundTripAndFallsBackToTheDefault() throws {
        let defaults = try #require(UserDefaults(suiteName: "KeyCombinationTests-\(UUID().uuidString)"))
        #expect(defaults.hotKey == .optionT)

        let combination = KeyCombination(keyCode: 7, modifiers: [.command, .shift], key: "X")
        defaults.hotKey = combination
        #expect(defaults.hotKey == combination)

        defaults.set(Data("not json".utf8), forKey: Preferences.hotKey)
        #expect(defaults.hotKey == .optionT)
    }
}
