import Testing
@testable import TranslateCore

@Suite struct GeneratedTextTests {
    @Test func keepsTheTextOfTheFirstTokensOnly() {
        var text = GeneratedText()
        text.append("こん")
        text.append("にちは")
        text.append("、世界")
        #expect(text.prefix(tokens: 2) == "こんにちは")
        #expect(text.prefix(tokens: 0) == "")
    }

    @Test func aTokenThatCompletedNoCharacterStillCountsAsABoundary() {
        var text = GeneratedText()
        text.append("a")
        text.append("")
        text.append("b")
        #expect(text.prefix(tokens: 2) == "a")
        #expect(text.prefix(tokens: 3) == "ab")
    }

    @Test func wholeTextWhenAskedForMoreTokensThanAppended() {
        var text = GeneratedText()
        text.append("x")
        #expect(text.prefix(tokens: 5) == "x")
    }
}
