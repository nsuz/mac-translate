import AppKit

/// The "Translate with Translate" item in other apps' Services menus. The text arrives on
/// the pasteboard the service system hands over, so no Accessibility access is involved.
final class ServiceProvider: NSObject {
    private let translate: (String) -> Void

    init(translate: @escaping (String) -> Void) {
        self.translate = translate
    }

    @objc func translateText(_ pasteboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        guard let text = pasteboard.string(forType: .string) else {
            error.pointee = "The selection has no text."
            return
        }
        translate(text)
    }
}
