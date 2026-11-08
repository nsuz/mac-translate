import AppKit

/// Plain text with list markers as characters, made from the HTML an app puts on the
/// pasteboard. The model carries such markers through a translation and the popover shows
/// them as they are; nothing else about the markup needs to survive.
enum StructuredText {
    static func plain(fromHTML html: String) -> String? {
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue,
        ]
        guard let attributed = try? NSAttributedString(data: Data(html.utf8), options: options, documentAttributes: nil) else {
            return nil
        }
        var lines: [String] = []
        let string = attributed.string as NSString
        string.enumerateSubstrings(in: NSRange(location: 0, length: string.length), options: .byParagraphs) { paragraph, range, _, _ in
            guard let paragraph else { return }
            let style = attributed.attribute(.paragraphStyle, at: range.location, effectiveRange: nil) as? NSParagraphStyle
            lines.append(line(paragraph, in: style?.textLists ?? []))
        }
        let text = lines.joined(separator: "\n")
        return text.contains(where: { !$0.isWhitespace }) ? text : nil
    }

    // The HTML importer writes each list item as "\t<marker>\t<text>"; the marker becomes
    // "• ", "◦ " or "1. " at an indent of two spaces per nesting level.
    private static func line(_ paragraph: String, in lists: [NSTextList]) -> String {
        guard let list = lists.last, paragraph.hasPrefix("\t") else { return paragraph }
        let parts = paragraph.dropFirst().split(separator: "\t", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2 else { return paragraph }
        let marker = parts[0] + (list.isOrdered ? "." : "")
        return String(repeating: "  ", count: lists.count - 1) + marker + " " + parts[1]
    }
}
