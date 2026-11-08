import AppKit
import ApplicationServices
import SwiftUI
import TranslateCore

/// The one path from a shortcut press to a translation on screen.
final class TranslationPresenter {
    private let model: AppModel
    private let windows: AppWindows
    private let popover = Popover()
    private var translating: Task<Void, Never>?
    /// A copy in flight cannot be taken back, so a second press must not start another.
    private var isCopying = false

    init(model: AppModel, windows: AppWindows) {
        self.model = model
        self.windows = windows
        popover.onClose = { [weak self] in self?.translating?.cancel() }
    }

    func translateSelection() {
        if popover.isShown {
            popover.close()
            return
        }
        guard !isCopying else { return }
        guard AXIsProcessTrusted() else { return windows.showOnboarding() }
        switch SelectionReader.read() {
        case .empty:
            break
        case .unavailable:
            isCopying = true
            Task {
                defer { isCopying = false }
                if let text = await CopiedSelection.read(), text.contains(where: { !$0.isWhitespace }) {
                    present(text, at: mouseAnchor())
                } else {
                    popover.show(NoticeView("Couldn’t get the selected text."), at: mouseAnchor())
                }
            }
        case .selected(let selection):
            present(selection.text, at: selection.bounds ?? mouseAnchor())
        }
    }

    private func present(_ text: String, at anchor: CGRect) {
        guard model.isModelAvailable else { return windows.showModels() }
        let translation = Translation()
        let view = TranslationView(
            translation: translation,
            width: width(for: text),
            maxHeight: maxHeight(near: anchor),
            onClose: { [popover] in popover.close() }
        )
        popover.show(view, at: anchor)
        translating = Task { await translate(text, into: translation) }
    }

    private func translate(_ text: String, into translation: Translation) async {
        do {
            let translator = try await model.translator()
            translation.status = .translating
            let defaults = UserDefaults.standard
            let target = Language.target(for: text, primary: defaults.primaryLanguage, secondary: defaults.secondaryLanguage)
            let request = TranslationRequest(text: text, target: target, form: defaults.japaneseForm)
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
