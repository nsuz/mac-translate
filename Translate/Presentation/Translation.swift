import Observation

/// One translation as the popover shows it: the text so far and where the work stands.
@Observable
final class Translation {
    enum Status {
        case loadingModel
        case translating
        case finished
        /// The output hit its limit or looped; the text is a partial translation.
        case truncated
        case failed(any Error)
    }

    var text = ""
    var status = Status.loadingModel
}
