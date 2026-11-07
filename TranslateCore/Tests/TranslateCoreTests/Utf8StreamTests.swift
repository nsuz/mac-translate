// Ported from tanakh/plamo-translate-desktop (engine/utf8.rs), Copyright (c) 2026 Hideyuki Tanaka.
// Used under the MIT License; see THIRD-PARTY-LICENSES.md.

import Testing
@testable import TranslateCore

@Suite struct Utf8StreamTests {
    @Test func joinsACharacterSplitAcrossPushes() {
        var stream = Utf8Stream()
        var out = ""
        for byte in Array("日本語".utf8) {
            out += stream.push([byte])
        }
        out += stream.finish()
        #expect(out == "日本語")
    }

    @Test func replacesInvalidBytesWithReplacementCharacter() {
        var stream = Utf8Stream()
        #expect(stream.push([0x61, 0xFF, 0x62]) == "a\u{FFFD}b")
    }

    @Test func holdsAnIncompleteTrailingSequenceUntilFinish() {
        var stream = Utf8Stream()
        #expect(stream.push([0xE6, 0x97]) == "")
        #expect(stream.finish() == "\u{FFFD}")
        #expect(stream.finish() == "")
    }

    @Test func passesCompleteTextThroughUnchanged() {
        var stream = Utf8Stream()
        #expect(stream.push(Array("hello, 世界".utf8)) == "hello, 世界")
        #expect(stream.finish() == "")
    }
}
