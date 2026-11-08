import Foundation
import TranslateCore

/// The `UserDefaults` keys, named once so the views' `@AppStorage` and the code that reads
/// the values at translation time cannot drift apart.
enum Preferences {
    static let hotKey = "hotKey"
    static let primaryLanguage = "primaryLanguage"
    static let secondaryLanguage = "secondaryLanguage"
    static let japaneseForm = "japaneseForm"
    static let acceptedLicense = "acceptedLicense"
}

extension UserDefaults {
    /// Stored as JSON. Anything unreadable falls back to the default shortcut.
    var hotKey: KeyCombination {
        get { data(forKey: Preferences.hotKey).flatMap { try? JSONDecoder().decode(KeyCombination.self, from: $0) } ?? .optionT }
        set { set(try? JSONEncoder().encode(newValue), forKey: Preferences.hotKey) }
    }

    var primaryLanguage: Language {
        string(forKey: Preferences.primaryLanguage).flatMap(Language.init(rawValue:)) ?? .ja
    }

    var secondaryLanguage: Language {
        string(forKey: Preferences.secondaryLanguage).flatMap(Language.init(rawValue:)) ?? .en
    }

    var japaneseForm: JapaneseForm {
        string(forKey: Preferences.japaneseForm).flatMap(JapaneseForm.init(rawValue:)) ?? .polite
    }
}
