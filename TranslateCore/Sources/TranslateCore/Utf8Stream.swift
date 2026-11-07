// Ported from tanakh/plamo-translate-desktop (engine/utf8.rs), Copyright (c) 2026 Hideyuki Tanaka.
// Used under the MIT License; see THIRD-PARTY-LICENSES.md.

/// Incremental UTF-8 decoder for token pieces. A multi-byte character may be split across
/// tokens, so bytes are held until they form complete characters. Invalid sequences become
/// U+FFFD.
struct Utf8Stream: Sendable {
    private var pending: [UInt8] = []

    init() {}

    /// Appends `bytes` and returns the text that is now complete.
    mutating func push(_ bytes: some Sequence<UInt8>) -> String {
        pending.append(contentsOf: bytes)
        let complete = pending.count - Self.incompleteTailLength(of: pending)
        let text = String(decoding: pending[..<complete], as: UTF8.self)
        pending.removeFirst(complete)
        return text
    }

    /// Flushes an incomplete trailing sequence as U+FFFD.
    mutating func finish() -> String {
        defer { pending.removeAll() }
        return pending.isEmpty ? "" : "\u{FFFD}"
    }

    /// Length of a sequence at the end of `bytes` whose lead byte promises more bytes than
    /// follow it; 0 when the end is complete or invalid.
    private static func incompleteTailLength(of bytes: [UInt8]) -> Int {
        for offset in 1...min(3, max(bytes.count, 1)) where offset <= bytes.count {
            let byte = bytes[bytes.count - offset]
            if byte & 0b1100_0000 == 0b1000_0000 { continue }
            let expected: Int
            switch byte {
            case 0b1100_0000...0b1101_1111: expected = 2
            case 0b1110_0000...0b1110_1111: expected = 3
            case 0b1111_0000...0b1111_0111: expected = 4
            default: return 0
            }
            return offset < expected ? offset : 0
        }
        return 0
    }
}
