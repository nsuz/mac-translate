import Foundation
import TranslateCore

enum TargetPreference: String, CaseIterable {
    case automatic = "auto"
    case japanese = "ja"
    case english = "en"

    func language(for text: String) -> Language {
        switch self {
        case .automatic: .automaticTarget(for: text)
        case .japanese: .ja
        case .english: .en
        }
    }
}

/// The `UserDefaults` keys, named once so the views' `@AppStorage` and the code that reads
/// the values at translation time cannot drift apart.
enum Preferences {
    static let hotKey = "hotKey"
    static let targetLanguage = "targetLanguage"
    static let japaneseForm = "japaneseForm"
    static let acceptedLicense = "acceptedLicense"
}

extension UserDefaults {
    /// Stored as JSON. Anything unreadable falls back to the default shortcut.
    var hotKey: KeyCombination {
        get { data(forKey: Preferences.hotKey).flatMap { try? JSONDecoder().decode(KeyCombination.self, from: $0) } ?? .optionT }
        set { set(try? JSONEncoder().encode(newValue), forKey: Preferences.hotKey) }
    }

    var targetLanguage: TargetPreference {
        string(forKey: Preferences.targetLanguage).flatMap(TargetPreference.init(rawValue:)) ?? .automatic
    }

    var japaneseForm: JapaneseForm {
        string(forKey: Preferences.japaneseForm).flatMap(JapaneseForm.init(rawValue:)) ?? .polite
    }
}
