import Foundation

/// Translates with one model and one context. Only one generation runs at a time, and a new
/// request cancels the running one.
public actor Translator {
    private var backend: Backend?
    private let budget: @Sendable (Int) throws(TranslationError) -> LengthBudget
    private var generation: Task<Void, Never>?
    private var requestCount = 0
    private var isShuttingDown = false
    private let checkpoint: (@Sendable (Checkpoint) async -> Void)?

    /// Points where a test may hold the actor's work to fix the order of a race.
    enum Checkpoint {
        /// A request has cancelled the running generation and is about to wait for it.
        case beforeWaitingForGeneration
        /// The shutdown has outlived the generation and is about to free the backend.
        case beforeFreeingBackend
    }

    public init(modelURL: URL) throws(TranslationError) {
        try self.init(modelURL: modelURL, budget: LengthBudget.init(promptTokens:))
    }

    init(
        modelURL: URL,
        budget: @escaping @Sendable (Int) throws(TranslationError) -> LengthBudget,
        checkpoint: (@Sendable (Checkpoint) async -> Void)? = nil
    ) throws(TranslationError) {
        backend = try Backend.load(modelURL)
        self.budget = budget
        self.checkpoint = checkpoint
    }

    /// Starts translating `request` once the running generation, if any, has stopped. A
    /// request that is superseded while it waits, or whose caller is cancelled, throws
    /// `CancellationError`; one that arrives during or after `shutdown` throws
    /// `modelUnavailable`. The stream's consumer stopping cancels the generation.
    public func translate(_ request: TranslationRequest) async throws -> AsyncThrowingStream<String, Error> {
        try Task.checkCancellation()
        guard !isShuttingDown else { throw TranslationError.modelUnavailable }
        requestCount += 1
        let mine = requestCount
        if let generation {
            generation.cancel()
            await checkpoint?(.beforeWaitingForGeneration)
            await generation.value
        }
        try Task.checkCancellation()
        guard mine == requestCount else { throw CancellationError() }
        guard !isShuttingDown, let backend else { throw TranslationError.modelUnavailable }

        let prompt = backend.tokens(for: Prompt(text: request.text, target: request.target, form: request.form))
        let budget = try budget(prompt.count)
        let (stream, continuation) = AsyncThrowingStream<String, Error>.makeStream()
        let task = Task { await self.generate(prompt: prompt, budget: budget, into: continuation) }
        continuation.onTermination = { _ in task.cancel() }
        generation = task
        return stream
    }

    /// Stops accepting requests, cancels the generation, waits for it, and frees the context
    /// and the model. Requests that are already waiting are refused too: the actor is
    /// reentrant while this awaits, so the refusal is decided before the first suspension.
    public func shutdown() async {
        isShuttingDown = true
        generation?.cancel()
        await generation?.value
        await checkpoint?(.beforeFreeingBackend)
        backend?.free()
        backend = nil
    }

    var specialTokens: [Prompt.SpecialToken: Token] { backend?.specialTokens ?? [:] }

    func tokens(for prompt: Prompt) -> [Token] { backend?.tokens(for: prompt) ?? [] }

    func tokenize(_ text: String, parseSpecial: Bool) -> [Token] { backend?.tokenize(text, parseSpecial: parseSpecial) ?? [] }

    private func generate(prompt: [Token], budget: LengthBudget, into continuation: AsyncThrowingStream<String, Error>.Continuation) async {
        guard let backend else {
            continuation.finish(throwing: TranslationError.modelUnavailable)
            return
        }
        defer { backend.clear() }
        do {
            for start in stride(from: 0, to: prompt.count, by: Backend.batchSize) {
                try backend.decode(Array(prompt[start..<min(start + Backend.batchSize, prompt.count)]))
                await Task.yield()
                try Task.checkCancellation()
            }

            var detector = LoopDetector(input: prompt)
            var utf8 = Utf8Stream()
            var generated = GeneratedText()
            for _ in 0..<budget.output {
                let token = backend.sample()
                if backend.isEndOfGeneration(token) {
                    let rest = utf8.finish()
                    if !rest.isEmpty { continuation.yield(rest) }
                    continuation.finish()
                    return
                }
                let piece = utf8.push(backend.piece(for: token))
                generated.append(piece)
                if let loop = detector.push(token) {
                    throw TranslationError.outputLooped(kept: generated.prefix(tokens: detector.keep(loop)))
                }
                if !piece.isEmpty { continuation.yield(piece) }
                try backend.decode([token])
                await Task.yield()
                try Task.checkCancellation()
            }
            throw TranslationError.outputLimitReached
        } catch {
            continuation.finish(throwing: error)
        }
    }
}
