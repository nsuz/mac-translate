import AppKit
import SwiftUI

/// Shows one `NSPopover` at a time anywhere on screen, anchored to an invisible panel that
/// takes keyboard focus without activating the app.
final class Popover: NSObject, NSPopoverDelegate {
    var onClose: (() -> Void)?
    private var panel: AnchorPanel?
    private var popover: NSPopover?

    var isShown: Bool { popover != nil }

    /// `anchor` is in screen coordinates; the popover opens below it.
    func show(_ content: some View, at anchor: CGRect) {
        popover?.close()
        panel?.orderOut(nil)

        let panel = AnchorPanel(frame: anchor)
        let host = NSHostingController(rootView: content)
        host.sizingOptions = .preferredContentSize
        let popover = NSPopover()
        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = host
        popover.contentSize = host.view.fittingSize
        panel.orderFrontRegardless()
        panel.makeKey()
        popover.show(relativeTo: panel.contentView!.bounds, of: panel.contentView!, preferredEdge: .minY)
        self.panel = panel
        self.popover = popover
    }

    func close() {
        popover?.performClose(nil)
    }

    func popoverDidClose(_ notification: Notification) {
        guard (notification.object as? NSPopover) === popover else { return }
        panel?.orderOut(nil)
        panel = nil
        popover = nil
        onClose?()
    }
}

private final class AnchorPanel: NSPanel {
    init(frame: CGRect) {
        super.init(
            contentRect: CGRect(origin: frame.origin, size: CGSize(width: max(frame.width, 1), height: max(frame.height, 1))),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
    }

    override var canBecomeKey: Bool { true }
}
