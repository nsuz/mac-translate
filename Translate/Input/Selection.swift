import AppKit
import ApplicationServices
import os

struct Selection {
    let text: String
    /// Screen coordinates (AppKit, bottom-left origin); nil when the app does not report them.
    let bounds: CGRect?
}

enum SelectionResult {
    case selected(Selection)
    /// Readable, but nothing is selected.
    case empty
    /// The focused element exposes neither the AppKit nor the WebKit path.
    case unavailable

    var text: String? {
        if case .selected(let selection) = self { selection.text } else { nil }
    }

    var bounds: CGRect? {
        if case .selected(let selection) = self { selection.bounds } else { nil }
    }
}

/// Reads the selection of the focused element through the Accessibility API, trying the
/// AppKit attributes first and the WebKit text-marker attributes second.
enum SelectionReader {
    static func read() -> SelectionResult {
        guard let element = focusedElement() else {
            logger.debug("no focused element")
            return .unavailable
        }
        let marker = attribute(element, "AXSelectedTextMarkerRange")
        guard let text = attribute(element, kAXSelectedTextAttribute) as? String
            ?? marker.flatMap({ parameterized(element, "AXStringForTextMarkerRange", $0) as? String })
        else {
            logger.debug("no selection path in \(owner(of: element), privacy: .public): attributes \(names(of: element), privacy: .public)")
            return .unavailable
        }
        guard text.contains(where: { !$0.isWhitespace }) else { return .empty }

        let rangeBounds = attribute(element, kAXSelectedTextRangeAttribute)
            .flatMap { rect(parameterized(element, kAXBoundsForRangeParameterizedAttribute, $0)) }
        let markerBounds = marker.flatMap { rect(parameterized(element, "AXBoundsForTextMarkerRange", $0)) }
        logger.debug("bounds in \(owner(of: element), privacy: .public): range \(String(describing: rangeBounds), privacy: .public), marker \(String(describing: markerBounds), privacy: .public)")
        let bounds = [rangeBounds, markerBounds].compactMap { $0 }.first { !$0.isEmpty }
        return .selected(Selection(text: text, bounds: bounds.map(appKitRect)))
    }

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Translate", category: "selection")

    private static func focusedElement() -> AXUIElement? {
        guard let focused = attribute(AXUIElementCreateSystemWide(), kAXFocusedUIElementAttribute),
              CFGetTypeID(focused) == AXUIElementGetTypeID()
        else { return nil }
        return (focused as! AXUIElement)
    }

    private static func owner(of element: AXUIElement) -> String {
        var pid: pid_t = 0
        AXUIElementGetPid(element, &pid)
        let role = attribute(element, kAXRoleAttribute) as? String ?? "?"
        return "\(NSRunningApplication(processIdentifier: pid)?.bundleIdentifier ?? "?") \(role)"
    }

    /// Attribute names only, never values: enough to see which paths an app offers.
    private static func names(of element: AXUIElement) -> String {
        var attributes: CFArray?
        var parameterized: CFArray?
        AXUIElementCopyAttributeNames(element, &attributes)
        AXUIElementCopyParameterizedAttributeNames(element, &parameterized)
        return ((attributes as? [String] ?? []) + (parameterized as? [String] ?? []).map { $0 + "(…)" }).joined(separator: " ")
    }

    private static func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }

    private static func parameterized(_ element: AXUIElement, _ name: String, _ parameter: CFTypeRef) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(element, name as CFString, parameter, &value) == .success
        else { return nil }
        return value
    }

    private static func rect(_ value: CFTypeRef?) -> CGRect? {
        guard let value, CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        var rect = CGRect.zero
        guard AXValueGetValue(value as! AXValue, .cgRect, &rect) else { return nil }
        return rect
    }

    /// Accessibility reports top-left-origin coordinates relative to the primary display.
    private static func appKitRect(_ rect: CGRect) -> CGRect {
        guard let primary = NSScreen.screens.first else { return rect }
        return CGRect(x: rect.minX, y: primary.frame.height - rect.maxY, width: rect.width, height: rect.height)
    }
}
