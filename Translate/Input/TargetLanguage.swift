import NaturalLanguage
import TranslateCore

extension Language {
    /// Japanese text goes to English; everything else goes to Japanese.
    static func automaticTarget(for text: String) -> Language {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.dominantLanguage == .japanese ? .en : .ja
    }
}
