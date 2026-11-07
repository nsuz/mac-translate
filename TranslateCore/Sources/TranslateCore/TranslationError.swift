public enum TranslationError: Error, Equatable, Sendable {
    case inputTooLong(tokens: Int, limit: Int)
    /// Thrown after the partial translation was yielded.
    case outputLimitReached
    /// The whole output worth keeping; replaces what was yielded so far.
    case outputLooped(kept: String)
    case modelUnavailable
    /// llama.cpp refused a batch; the status is its return value.
    case decodeFailed(status: Int32)
}
