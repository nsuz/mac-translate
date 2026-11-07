/// The PFML3 prompt for one translation, as the sequence of special tokens and text the model
/// receives. Text stays separate from special tokens so the tokenizer never reads markup out of
/// the source text.
struct Prompt: Equatable, Sendable {
    enum SpecialToken: String, CaseIterable, Sendable {
        case bos = "<|plamo:bos|>"
        case tag = "<|plamo:tag|>"
        case msg = "<|plamo:msg|>"
        case key = "<|plamo:key|>"
        case val = "<|plamo:val|>"
    }

    enum Segment: Equatable, Sendable {
        case special(SpecialToken)
        case text(String)
    }

    let segments: [Segment]

    init(text: String, target: Language, form: JapaneseForm?) {
        var attributes = [("lang", target.rawValue)]
        if target == .ja, let form {
            attributes.append(("form", form.rawValue))
        }
        segments = [.special(.bos)]
            + Self.element("dataset", body: "translation")
            + Self.element("input", body: text)
            + Self.element("output", attributes: attributes)
    }

    private static func element(_ name: String, attributes: [(String, String)] = [], body: String? = nil) -> [Segment] {
        var segments: [Segment] = [.special(.tag), .text(name)]
        for (key, value) in attributes {
            segments += [.special(.key), .text(key), .special(.val), .text(value)]
        }
        segments.append(.special(.msg))
        if let body {
            segments.append(.text(body))
        }
        return segments
    }
}
