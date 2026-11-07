public struct TranslationRequest: Sendable {
    public var text: String
    public var target: Language
    /// Only meaningful when `target` is `.ja`.
    public var form: JapaneseForm?

    public init(text: String, target: Language, form: JapaneseForm? = nil) {
        self.text = text
        self.target = target
        self.form = form
    }
}
