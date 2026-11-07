import Foundation
import llama

/// The llama.cpp model, context and sampler behind one `Translator`. Pointers never leave the
/// actor that owns the backend.
struct Backend {
    static let batchSize = 512

    let model: OpaquePointer
    let context: OpaquePointer
    let vocab: OpaquePointer
    let sampler: UnsafeMutablePointer<llama_sampler>
    let specialTokens: [Prompt.SpecialToken: Token]

    static func load(_ modelURL: URL) throws(TranslationError) -> Backend {
        llama_log_set({ level, text, _ in
            if level == GGML_LOG_LEVEL_WARN || level == GGML_LOG_LEVEL_ERROR, let text {
                FileHandle.standardError.write(Data(String(cString: text).utf8))
            }
        }, nil)
        llama_backend_init()

        guard let model = llama_model_load_from_file(modelURL.path, llama_model_default_params()) else {
            throw .modelUnavailable
        }
        var parameters = llama_context_default_params()
        parameters.n_ctx = UInt32(LengthBudget.contextSize)
        parameters.n_batch = UInt32(batchSize)
        parameters.n_ubatch = UInt32(batchSize)
        parameters.swa_full = false
        parameters.no_perf = true
        guard let context = llama_init_from_model(model, parameters) else {
            llama_model_free(model)
            throw .modelUnavailable
        }
        let vocab = llama_model_get_vocab(model)!
        let sampler = llama_sampler_chain_init(llama_sampler_chain_default_params())!
        llama_sampler_chain_add(sampler, llama_sampler_init_greedy())

        var specialTokens: [Prompt.SpecialToken: Token] = [:]
        for special in Prompt.SpecialToken.allCases {
            let tokens = tokenize(special.rawValue, vocab: vocab, parseSpecial: true)
            guard tokens.count == 1 else {
                llama_sampler_free(sampler)
                llama_free(context)
                llama_model_free(model)
                throw .modelUnavailable
            }
            specialTokens[special] = tokens[0]
        }
        return Backend(model: model, context: context, vocab: vocab, sampler: sampler, specialTokens: specialTokens)
    }

    func free() {
        llama_sampler_free(sampler)
        llama_free(context)
        llama_model_free(model)
    }

    func tokens(for prompt: Prompt) -> [Token] {
        prompt.segments.flatMap { segment -> [Token] in
            switch segment {
            case .special(let special): [specialTokens[special]!]
            case .text(let text): plainTokens(text)
            }
        }
    }

    func tokenize(_ text: String, parseSpecial: Bool) -> [Token] {
        Self.tokenize(text, vocab: vocab, parseSpecial: parseSpecial)
    }

    /// Tokens for source text. The tokenizer matches the spelling of a control token even with
    /// `parse_special` off, so each one that appears is re-tokenized from its spelling in two
    /// halves: the bytes stay the same and the control meaning is gone.
    func plainTokens(_ text: String) -> [Token] {
        let tokens = tokenize(text, parseSpecial: false)
        guard tokens.contains(where: isControl) else { return tokens }
        return tokens.flatMap { token -> [Token] in
            guard isControl(token) else { return [token] }
            let spelling = String(decoding: piece(for: token, special: true), as: UTF8.self)
            return tokenize(String(spelling.prefix(1)), parseSpecial: false) + plainTokens(String(spelling.dropFirst()))
        }
    }

    private func isControl(_ token: Token) -> Bool {
        llama_vocab_is_control(vocab, token)
    }

    private static func tokenize(_ text: String, vocab: OpaquePointer, parseSpecial: Bool) -> [Token] {
        var tokens = [Token](repeating: 0, count: text.utf8.count + 16)
        var count = llama_tokenize(vocab, text, Int32(text.utf8.count), &tokens, Int32(tokens.count), false, parseSpecial)
        if count < 0 {
            tokens = [Token](repeating: 0, count: Int(-count))
            count = llama_tokenize(vocab, text, Int32(text.utf8.count), &tokens, Int32(tokens.count), false, parseSpecial)
        }
        return Array(tokens.prefix(Int(max(count, 0))))
    }

    /// The bytes of one token's text; not necessarily whole characters. Control tokens render
    /// as nothing unless `special` is set.
    func piece(for token: Token, special: Bool = false) -> [UInt8] {
        var buffer = [CChar](repeating: 0, count: 64)
        var count = llama_token_to_piece(vocab, token, &buffer, Int32(buffer.count), 0, special)
        if count < 0 {
            buffer = [CChar](repeating: 0, count: Int(-count))
            count = llama_token_to_piece(vocab, token, &buffer, Int32(buffer.count), 0, special)
        }
        return buffer.prefix(Int(max(count, 0))).map { UInt8(bitPattern: $0) }
    }

    /// Feeds `tokens` (at most `batchSize`) through the model, leaving logits for the last one.
    func decode(_ tokens: [Token]) throws(TranslationError) {
        var tokens = tokens
        let status = tokens.withUnsafeMutableBufferPointer { buffer in
            llama_decode(context, llama_batch_get_one(buffer.baseAddress, Int32(buffer.count)))
        }
        guard status == 0 else { throw .decodeFailed(status: status) }
    }

    func sample() -> Token {
        llama_sampler_sample(sampler, context, -1)
    }

    func isEndOfGeneration(_ token: Token) -> Bool {
        llama_vocab_is_eog(vocab, token)
    }

    func clear() {
        llama_memory_clear(llama_get_memory(context), true)
    }
}
