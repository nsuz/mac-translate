/// How many tokens one translation may generate, so that the prompt and the output together
/// always fit the context.
struct LengthBudget: Equatable, Sendable {
    /// Prompts longer than this are refused. A conservative start for a small model: tanakh's
    /// measurements show the 0.8B dropping sentences from long inputs, and a refusal is more
    /// honest than a broken translation.
    static let inputLimit = 2048
    /// Smaller than the training length (32,768), which keeps the KV cache light.
    static let contextSize = 8192

    /// The maximum number of tokens to generate.
    let output: Int

    init(output: Int) {
        self.output = output
    }

    init(promptTokens: Int) throws(TranslationError) {
        guard promptTokens <= Self.inputLimit else {
            throw .inputTooLong(tokens: promptTokens, limit: Self.inputLimit)
        }
        // Translations run at 0.5–1.5× the input; ×2 leaves room for the expansive pairs.
        output = min(promptTokens * 2 + 64, Self.contextSize - promptTokens - 1)
    }
}
