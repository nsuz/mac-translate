// Ported from tanakh/plamo-translate-desktop (engine/repetition.rs), Copyright (c) 2026 Hideyuki Tanaka.
// Used under the MIT License; see THIRD-PARTY-LICENSES.md.

/// A token id as llama.cpp numbers them.
typealias Token = Int32

/// Detects a generation loop: a small model decoding greedily can fall into a cycle and emit
/// the same few tokens until the context is full. Which inputs trigger it depends on near-ties
/// between candidates, so it varies with the backend and cannot be ruled out in advance.
///
/// For every period up to `maxPeriod`, the detector keeps the length of the run in which each
/// token equals the one a period earlier, updated in constant time per period and token.
struct LoopDetector: Sendable {
    /// The longest cycle detected, in tokens. Longer cycles are caught by the output limit.
    static let maxPeriod = 128
    /// A cycle must repeat at least this many times to count as a loop.
    static let minRepeats = 3
    /// The shortest repeated span that counts as a loop, for input without repetition of its own.
    static let minLoopSpan = 64

    /// A loop at the end of the generated tokens.
    struct Loop: Equatable, Sendable {
        let period: Int
        /// Index of the first token of the repeated span.
        let start: Int
        /// Number of tokens up to the end of the cycle's first occurrence.
        var firstEnd: Int { start + period }
    }

    let minSpan: Int
    private let input: [Token]
    private(set) var tokens: [Token] = []
    /// `runs[p - 1]`: how many tokens at the end equal the token `p` positions earlier.
    private var runs = [Int](repeating: 0, count: LoopDetector.maxPeriod)

    /// A detector that reports periodic spans of at least `minSpan` tokens.
    init(minSpan: Int = LoopDetector.minLoopSpan) {
        self.minSpan = minSpan
        input = []
    }

    /// A detector calibrated to the prompt: a span counts as a loop only if it is well beyond
    /// any repetition the input itself contains, such as a ruler of dashes or a refrain.
    init(input: [Token]) {
        minSpan = max(Self.minLoopSpan, 2 * Self.longestPeriodicSpan(input))
        self.input = input
    }

    /// Adds a generated token. Returns the loop if the output now ends in one.
    mutating func push(_ token: Token) -> Loop? {
        let n = tokens.count
        tokens.append(token)
        var found: Loop?
        for period in stride(from: 1, through: min(Self.maxPeriod, n), by: 1) {
            runs[period - 1] = tokens[n - period] == token ? runs[period - 1] + 1 : 0
            let span = runs[period - 1] + period
            if found == nil, span >= minSpan, span >= Self.minRepeats * period {
                found = Loop(period: period, start: n + 1 - span)
            }
        }
        return found
    }

    /// Number of generated tokens worth keeping when the output ends in `found`: the cycle's
    /// first occurrence, unless the input contains the same cycle. Text the model copies, such
    /// as repeated lines of code, legitimately repeats as often as in the input, and only the
    /// repeats beyond that are the loop.
    func keep(_ found: Loop) -> Int {
        let cycle = Array(tokens[found.start..<found.firstEnd])
        let repeats = max(Self.maxConsecutiveRepeats(of: cycle, in: input), 1)
        return min(found.start + repeats * found.period, tokens.count)
    }

    /// The longest span of `tokens` that repeats a cycle of at most `maxPeriod` tokens at least
    /// `minRepeats` times, or 0.
    static func longestPeriodicSpan(_ tokens: [Token]) -> Int {
        var runs = [Int](repeating: 0, count: maxPeriod)
        var longest = 0
        for (n, token) in tokens.enumerated() {
            for period in stride(from: 1, through: min(maxPeriod, n), by: 1) {
                runs[period - 1] = tokens[n - period] == token ? runs[period - 1] + 1 : 0
                let span = runs[period - 1] + period
                if span >= minRepeats * period {
                    longest = max(longest, span)
                }
            }
        }
        return longest
    }

    private static func maxConsecutiveRepeats(of cycle: [Token], in tokens: [Token]) -> Int {
        var best = 0
        for start in tokens.indices {
            var repeats = 0
            while tokens[(start + repeats * cycle.count)...].starts(with: cycle) {
                repeats += 1
            }
            best = max(best, repeats)
        }
        return best
    }
}
