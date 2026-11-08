import AppKit
import ApplicationServices
import SwiftUI
import TranslateCore

/// The one path from a shortcut press to a translation on screen.
final class TranslationPresenter {
    private let model: AppModel
    private let popover = Popover()
    private var translating: Task<Void, Never>?

    init(model: AppModel) {
        self.model = model
        popover.onClose = { [weak self] in self?.translating?.cancel() }
    }

    func translateSelection() {
        if popover.isShown {
            popover.close()
            return
        }
        guard AXIsProcessTrusted() else {
            popover.show(NoticeView("Translate needs Accessibility access to read the selection."), at: mouseAnchor())
            return
        }
        switch SelectionReader.read() {
        case .empty:
            break
        case .unavailable:
            popover.show(NoticeView("Couldn’t get the selected text."), at: mouseAnchor())
        case .selected(let selection):
            let anchor = selection.bounds ?? mouseAnchor()
            let translation = Translation()
            let view = TranslationView(
                translation: translation,
                width: width(for: selection.text),
                maxHeight: maxHeight(near: anchor),
                onClose: { [popover] in popover.close() }
            )
            popover.show(view, at: anchor)
            translating = Task { await translate(selection.text, into: translation) }
        }
    }

    private func translate(_ text: String, into translation: Translation) async {
        do {
            let translator = try await model.translator()
            translation.status = .translating
            let request = TranslationRequest(text: text, target: .automaticTarget(for: text), form: .polite)
            for try await piece in try await translator.translate(request) {
                translation.text += piece
            }
            translation.status = .finished
        } catch TranslationError.outputLimitReached {
            translation.status = .truncated
        } catch TranslationError.outputLooped(let kept) {
            translation.text = kept
            translation.status = .truncated
        } catch is CancellationError {
        } catch {
            translation.status = .failed(error)
        }
    }

    private func mouseAnchor() -> CGRect {
        CGRect(origin: NSEvent.mouseLocation, size: .zero)
    }

    private func width(for text: String) -> CGFloat {
        min(max(CGFloat(text.count) * 6, 280), 480)
    }

    private func maxHeight(near anchor: CGRect) -> CGFloat {
        let screen = NSScreen.screens.first { $0.frame.contains(anchor.origin) } ?? NSScreen.main
        return (screen?.visibleFrame.height ?? 600) * 0.6
    }
}
