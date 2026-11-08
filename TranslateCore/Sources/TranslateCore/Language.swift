/// A language PLaMo 3 Translate can translate into, spelled the way PFML3 expects in the
/// `lang` attribute. The 53 cases are the model card's supported-language table.
public enum Language: String, Sendable, Hashable, CaseIterable {
    case ja, en
    case zhHans = "zh-hans", zhHant = "zh-hant"
    case ko, ar, az, be, bg, bn, ca, ceb, de, es, et, eu, fa, fr, gu, he, hi, hr, hu, hy, id, it, jv, ka, kk, km
    case lt, lv, ml, mr, ms, my, ne, nl, pa, pl, ru, si, sk, sl, sr, sw, ta, te, th, tl, ur, uz, vi
}

/// The register of a Japanese translation, spelled the way PFML3 expects in the `form` attribute.
public enum JapaneseForm: String, Sendable, Hashable, CaseIterable {
    case polite
    case plain
}
