import Testing
import TranslateCore
@testable import Translate

struct TargetLanguageTests {
    @Test func textInThePrimaryLanguageGoesToTheSecondary() {
        #expect(Language.target(for: "来週の会議は月曜日に変更になりました。", primary: .ja, secondary: .en) == .en)
    }

    @Test func textInAnyOtherLanguageGoesToThePrimary() {
        #expect(Language.target(for: "The meeting has been moved to Monday.", primary: .ja, secondary: .en) == .ja)
        #expect(Language.target(for: "Das Treffen wurde auf Montag verschoben.", primary: .ja, secondary: .en) == .ja)
    }

    @Test func thePrimaryLanguageNeedNotBeJapanese() {
        #expect(Language.target(for: "会议改到周一举行。", primary: .zhHans, secondary: .en) == .en)
        #expect(Language.target(for: "The meeting has been moved to Monday.", primary: .zhHans, secondary: .en) == .zhHans)
    }

    @Test func undetectableTextGoesToThePrimary() {
        #expect(Language.target(for: "1234 5678", primary: .ja, secondary: .en) == .ja)
    }

    @Test func chineseScriptsMapToTheirOwnCodes() {
        #expect(Language.detected(in: "这是一个简体中文的句子，用来测试语言判定。") == .zhHans)
        #expect(Language.detected(in: "這是一個繁體中文的句子，用來測試語言判定。") == .zhHant)
    }
}
