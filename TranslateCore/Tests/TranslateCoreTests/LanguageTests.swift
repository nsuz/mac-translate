import Testing
@testable import TranslateCore

struct LanguageTests {
    @Test func coversTheModelCardsFiftyThreeLanguages() {
        #expect(Language.allCases.count == 53)
    }

    @Test func codesAreSpelledAsPFML3Expects() {
        #expect(Language.ja.rawValue == "ja")
        #expect(Language.zhHans.rawValue == "zh-hans")
        #expect(Language.zhHant.rawValue == "zh-hant")
        #expect(Language(rawValue: "ceb") == .ceb)
    }
}
