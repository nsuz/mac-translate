import AppKit
import SwiftUI
import TranslateCore

struct SettingsView: View {
    @Bindable var model: AppModel
    @AppStorage(Preferences.primaryLanguage) private var primaryLanguage = Language.ja
    @AppStorage(Preferences.secondaryLanguage) private var secondaryLanguage = Language.en
    @AppStorage(Preferences.japaneseForm) private var japaneseForm = JapaneseForm.polite

    var body: some View {
        Form {
            LabeledContent("Shortcut") {
                ShortcutRecorder(combination: $model.hotKey, isRecording: $model.isRecordingShortcut)
            }
            Section {
                languagePicker("Primary language", selection: $primaryLanguage)
                languagePicker("Secondary language", selection: $secondaryLanguage)
            } footer: {
                Text("Text in the primary language is translated into the secondary one. Everything else is translated into the primary.")
            }
            Picker("Japanese style", selection: $japaneseForm) {
                Text("Polite").tag(JapaneseForm.polite)
                Text("Plain").tag(JapaneseForm.plain)
            }
            Section {
                Button("Acknowledgements…") { NSWorkspace.shared.open(Self.acknowledgements) }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400)
    }

    private func languagePicker(_ title: LocalizedStringKey, selection: Binding<Language>) -> some View {
        Picker(title, selection: selection) {
            ForEach(Self.languagesByName, id: \.self) { language in
                Text(language.localizedName).tag(language)
            }
        }
    }

    private static let acknowledgements = Bundle.main.url(forResource: "THIRD-PARTY-LICENSES", withExtension: "md")!

    private static let languagesByName = Language.allCases.sorted {
        $0.localizedName.localizedStandardCompare($1.localizedName) == .orderedAscending
    }
}
