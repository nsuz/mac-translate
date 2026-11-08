import Carbon

extension KeyCombination {
    static let optionT = KeyCombination(keyCode: UInt32(kVK_ANSI_T), modifiers: .option, key: "T")
}

extension KeyCombination.Modifiers {
    var carbonFlags: UInt32 {
        var flags: UInt32 = 0
        if contains(.control) { flags |= UInt32(controlKey) }
        if contains(.option) { flags |= UInt32(optionKey) }
        if contains(.shift) { flags |= UInt32(shiftKey) }
        if contains(.command) { flags |= UInt32(cmdKey) }
        return flags
    }
}

/// A system-wide shortcut that is consumed, so the frontmost app never sees it. Carbon's
/// `RegisterEventHotKey` is the only public API that does this; `NSEvent` global monitors
/// only observe.
final class HotKey {
    struct RegistrationFailed: Error {
        let status: OSStatus
    }

    let combination: KeyCombination
    let presses: AsyncStream<Void>
    private let press: AsyncStream<Void>.Continuation
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    init(_ combination: KeyCombination) throws(RegistrationFailed) {
        self.combination = combination
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
            combination.keyCode, combination.modifiers.carbonFlags, id, GetApplicationEventTarget(), 0, &hotKeyRef
        )
        guard registered == noErr else { throw RegistrationFailed(status: registered) }
    }

    /// Gives the key back to the system at once and ends `presses`. Carbon refuses to register
    /// a key that is still registered, so this cannot wait for whoever reads the stream.
    func unregister() {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let handlerRef { RemoveEventHandler(handlerRef) }
        hotKeyRef = nil
        handlerRef = nil
        press.finish()
    }

    isolated deinit {
        unregister()
    }
}
