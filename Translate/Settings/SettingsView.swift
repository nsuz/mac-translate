import SwiftUI
import TranslateCore

struct SettingsView: View {
    @Bindable var model: AppModel
    @AppStorage(Preferences.targetLanguage) private var targetLanguage = TargetPreference.automatic
    @AppStorage(Preferences.japaneseForm) private var japaneseForm = JapaneseForm.polite

    var body: some View {
        Form {
            LabeledContent("Shortcut") {
                ShortcutRecorder(combination: $model.hotKey, isRecording: $model.isRecordingShortcut)
            }
            Picker("Translate to", selection: $targetLanguage) {
                Text("Automatic").tag(TargetPreference.automatic)
                Text("Japanese").tag(TargetPreference.japanese)
                Text("English").tag(TargetPreference.english)
            }
            Picker("Japanese style", selection: $japaneseForm) {
                Text("Polite").tag(JapaneseForm.polite)
                Text("Plain").tag(JapaneseForm.plain)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
    }
}
