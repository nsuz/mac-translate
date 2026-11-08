import Carbon

struct KeyCombination: Sendable {
    var keyCode: UInt32
    var modifiers: UInt32

    static let optionT = KeyCombination(keyCode: UInt32(kVK_ANSI_T), modifiers: UInt32(optionKey))
}

/// A system-wide shortcut that is consumed, so the frontmost app never sees it. Carbon's
/// `RegisterEventHotKey` is the only public API that does this; `NSEvent` global monitors
/// only observe.
final class HotKey {
    struct RegistrationFailed: Error {
        let status: OSStatus
    }

    let presses: AsyncStream<Void>
    private let press: AsyncStream<Void>.Continuation
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    init(_ combination: KeyCombination) throws(RegistrationFailed) {
        (presses, press) = AsyncStream.makeStream()
        var pressed = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let installed = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                MainActor.assumeIsolated {
                    _ = Unmanaged<HotKey>.fromOpaque(userData!).takeUnretainedValue().press.yield()
                }
                return noErr
            },
            1, &pressed,
            Unmanaged.passUnretained(self).toOpaque(),
            &handlerRef
        )
        guard installed == noErr else { throw RegistrationFailed(status: installed) }
        let id = EventHotKeyID(signature: OSType(0x5452_4E53), id: 1)
        let registered = RegisterEventHotKey(
            combination.keyCode, combination.modifiers, id, GetApplicationEventTarget(), 0, &hotKeyRef
        )
        guard registered == noErr else { throw RegistrationFailed(status: registered) }
    }

    isolated deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let handlerRef { RemoveEventHandler(handlerRef) }
    }
}
