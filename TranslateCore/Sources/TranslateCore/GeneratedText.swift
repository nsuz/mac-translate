/// The text generated so far, with the boundary after each token, so that a loop can be cut at
/// a token boundary even though tokens, bytes and characters are counted differently.
struct GeneratedText: Sendable {
    private(set) var text = ""
    private var boundaries: [String.Index] = []

    /// Appends the text that one token completed (possibly none, while a multi-byte character
    /// is still pending).
    mutating func append(_ piece: String) {
        text += piece
        boundaries.append(text.endIndex)
    }

    /// The text of the first `tokens` tokens.
    func prefix(tokens: Int) -> String {
        guard tokens > 0 else { return "" }
        guard tokens < boundaries.count else { return text }
        return String(text[..<boundaries[tokens - 1]])
    }
}
