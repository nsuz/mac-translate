import Foundation
import NaturalLanguage
import TranslateCore

extension Language {
    /// Text in the primary language goes to the secondary one; anything else, including text
    /// whose language cannot be told, goes to the primary.
    static func target(for text: String, primary: Language, secondary: Language) -> Language {
        detected(in: text) == primary ? secondary : primary
    }

    static func detected(in text: String) -> Language? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        // NLLanguage spells codes like "zh-Hans"; PFML3 wants them lowercase.
        return recognizer.dominantLanguage.flatMap { Language(rawValue: $0.rawValue.lowercased()) }
    }

    /// The name in the user's language, from the system's own tables.
    var localizedName: String {
        Locale.current.localizedString(forIdentifier: rawValue) ?? rawValue
    }
}
