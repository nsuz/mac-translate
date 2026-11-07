// Ported from tanakh/plamo-translate-desktop (engine/repetition.rs), Copyright (c) 2026 Hideyuki Tanaka.
// Used under the MIT License; see THIRD-PARTY-LICENSES.md.

import Testing
@testable import TranslateCore

@Suite struct LoopDetectorTests {
    private func feed(_ detector: inout LoopDetector, _ tokens: some Sequence<Token>) -> LoopDetector.Loop? {
        for token in tokens {
            if let found = detector.push(token) { return found }
        }
        return nil
    }

    private func cycling(_ cycle: [Token], count: Int) -> [Token] {
        (0..<count).map { cycle[$0 % cycle.count] }
    }

    @Test func detectsAShortCycleOnceItSpans64Tokens() {
        var detector = LoopDetector(minSpan: 64)
        let found = feed(&detector, Array(100..<110) + cycling(Array(1...12), count: 200))
        #expect(found == LoopDetector.Loop(period: 12, start: 10))
        #expect(detector.tokens.count == 10 + 64)
        #expect(found?.firstEnd == 22)
    }

    @Test func detectsALongCycleAfterThreeRepeats() {
        var detector = LoopDetector(minSpan: 64)
        let found = feed(&detector, cycling(Array(1...50), count: 500))
        #expect(found == LoopDetector.Loop(period: 50, start: 0))
        #expect(detector.tokens.count == 150)
    }

    @Test func ignoresTextWithoutCycles() {
        var detector = LoopDetector(minSpan: 64)
        var x: UInt32 = 12345
        let tokens = (0..<5000).map { _ -> Token in
            x = x &* 1_103_515_245 &+ 12345
            return Token((x >> 16) % 50)
        }
        #expect(feed(&detector, tokens) == nil)
    }

    @Test func shortRepetitionIsAllowed() {
        var detector = LoopDetector(minSpan: 64)
        let tokens: [Token] = [1, 2, 1, 2, 1, 2, 1, 2, 1, 3] + Array(repeating: 7, count: 40) + Array(10..<20)
        #expect(feed(&detector, tokens) == nil)
    }

    @Test func calibratesToRepetitionInTheInput() {
        let input = (0..<100).map { Token($0 % 4) }
        #expect(LoopDetector.longestPeriodicSpan(input) == 100)
        var detector = LoopDetector(input: input)
        #expect(feed(&detector, (0..<150).map { Token($0 % 4) }) == nil)
        #expect(feed(&detector, (150..<300).map { Token($0 % 4) }) != nil)
    }

    @Test func keepsAsManyRepeatsAsTheInputHas() throws {
        let line: [Token] = [10, 11, 12, 13, 14]
        let input: [Token] = [1] + cycling(line, count: 5 * 30) + [2]

        var detector = LoopDetector(input: input)
        let found = try #require(feed(&detector, [7] + cycling(line, count: 5 * 100)))
        #expect(found.period == 5)
        #expect(detector.keep(found) == 1 + 5 * 30)

        var fresh = LoopDetector(input: input)
        let unrelated = try #require(feed(&fresh, cycling([3, 4, 5, 6], count: 400)))
        #expect(fresh.keep(unrelated) == unrelated.firstEnd)
    }

    @Test func plainInputUsesTheDefaultThreshold() {
        #expect(LoopDetector.longestPeriodicSpan([1, 2, 3, 4, 5]) == 0)
        #expect(LoopDetector(input: [1, 2, 3]).minSpan == LoopDetector.minLoopSpan)
    }
}
