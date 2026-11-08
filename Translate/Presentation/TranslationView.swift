import AppKit
import SwiftUI
import TranslateCore

struct TranslationView: View {
    let translation: Translation
    let width: CGFloat
    let maxHeight: CGFloat
    let onClose: () -> Void
    /// A click on the copy button changes nothing on screen by itself, so the icon answers.
    @State private var copied = false

    var body: some View {
        Group {
            if case .failed(let error) = translation.status {
                ContentUnavailableView {
                    Label("Couldn’t Translate", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message(for: error))
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    TranslationText(text: translation.text)
                    HStack {
                        footer
                        Spacer()
                        Button(action: copy) {
                            // Both symbols reserve their space, so swapping them never moves the layout.
                            ZStack {
                                Image(systemName: "document.on.document").hidden()
                                Image(systemName: "checkmark").hidden()
                                Image(systemName: copied ? "checkmark" : "document.on.document")
                                    .contentTransition(.symbolEffect(.replace, options: .speed(2)))
                            }
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.secondary)
                        .help("Copy")
                        .accessibilityLabel(copied ? "Copied" : "Copy Translation")
                        .task(id: copied) {
                            guard copied else { return }
                            try? await Task.sleep(for: .seconds(1.5))
                            withAnimation { copied = false }
                        }
                    }
                }
            }
        }
        .padding()
        .frame(width: width)
        .frame(maxHeight: maxHeight)
        .onExitCommand(perform: onClose)
    }

    @ViewBuilder private var footer: some View {
        switch translation.status {
        case .loadingModel:
            ProgressView().controlSize(.small)
            Text("Loading model…").font(.callout).foregroundStyle(.secondary)
        case .translating:
            ProgressView().controlSize(.small)
        case .truncated:
            Text("Only part of the text was translated.").font(.callout).foregroundStyle(.secondary)
        case .finished, .failed:
            EmptyView()
        }
    }

    private func copy() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(translation.text, forType: .string)
        withAnimation { copied = true }
        AccessibilityNotification.Announcement(String(localized: "Copied")).post()
    }

    private func message(for error: any Error) -> LocalizedStringKey {
        switch error {
        case TranslationError.inputTooLong:
            "The selection is too long. Select a shorter passage."
        case TranslationError.modelUnavailable:
            "The model isn’t available."
        default:
            "Try again with a different selection."
        }
    }
}

struct NoticeView: View {
    let text: LocalizedStringKey

    init(_ text: LocalizedStringKey) {
        self.text = text
    }

    var body: some View {
        Text(text).padding().fixedSize()
    }
}

/// A read-only `NSTextView` because `Text` cannot take keyboard focus, select by keyboard, or
/// copy without formatting.
private struct TranslationText: NSViewRepresentable {
    let text: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = TranslatedTextView.scrollableTextView()
        scrollView.drawsBackground = false
        let textView = scrollView.documentView as! TranslatedTextView
        textView.isEditable = false
        textView.isRichText = false
        textView.drawsBackground = false
        textView.font = Self.font
        textView.textContainerInset = .zero
        return scrollView
    }

    /// Streaming appends to the storage, which leaves the selection and the scroll position
    /// alone; replacing the string would drop both. A replacement only happens when a loop
    /// cut the text back, and then the selection is clamped to what is left.
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! TranslatedTextView
        let current = textView.string
        guard text != current else { return }
        let wasAtEnd = scrollView.documentVisibleRect.maxY >= textView.frame.maxY - 1
        if (text as NSString).hasPrefix(current), let storage = textView.textStorage {
            let appended = (text as NSString).substring(from: current.utf16.count)
            storage.append(NSAttributedString(string: appended, attributes: textView.typingAttributes))
        } else {
            let selected = textView.selectedRange()
            textView.string = text
            let location = min(selected.location, text.utf16.count)
            textView.setSelectedRange(NSRange(location: location, length: min(selected.length, text.utf16.count - location)))
        }
        if wasAtEnd { textView.scrollToEndOfDocument(nil) }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView scrollView: NSScrollView, context: Context) -> CGSize? {
        guard let width = proposal.width else { return nil }
        let padding = (scrollView.documentView as! NSTextView).textContainer?.lineFragmentPadding ?? 0
        let measured = NSAttributedString(string: text, attributes: [.font: Self.font]).boundingRect(
            with: CGSize(width: width - 2 * padding, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        )
        let height = max(ceil(measured.height), ceil(Self.font.ascender - Self.font.descender + Self.font.leading))
        return CGSize(width: width, height: min(height, proposal.height ?? .infinity))
    }

    private static let font = NSFont.preferredFont(forTextStyle: .body)
}

private final class TranslatedTextView: NSTextView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    /// ⌘C with nothing selected copies the whole translation. The menu item is validated
    /// before it is performed, and `NSTextView` disables Copy without a selection.
    override func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        item.action == #selector(copy(_:)) || super.validateUserInterfaceItem(item)
    }

    override func copy(_ sender: Any?) {
        guard selectedRange().length == 0 else { return super.copy(sender) }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }
}
