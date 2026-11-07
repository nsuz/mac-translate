/// A translation target, spelled the way PFML3 expects in the `lang` attribute.
public enum Language: String, Sendable, Hashable, CaseIterable {
    case ja
    case en
}

/// The register of a Japanese translation, spelled the way PFML3 expects in the `form` attribute.
public enum JapaneseForm: String, Sendable, Hashable, CaseIterable {
    case polite
    case plain
}
