import AppKit
import Carbon.HIToolbox

/// A process-global keyboard shortcut registered with Carbon's
/// `RegisterEventHotKey`. The shortcut fires while Agent Manager is running
/// (even when another app is frontmost) and requires no Accessibility or other
/// special permissions, because it is scoped to this application's event
/// target rather than tapping global input.
///
/// The registration can still fail if the system or another app already owns
/// the key combination (see `controlOptionSpace`); callers should treat a `nil`
/// result as "shortcut unavailable" and degrade gracefully.
final class GlobalHotKey {
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private let onFire: () -> Void

    /// Registers a hot key for the given virtual key code and Carbon modifier
    /// mask. Returns nil if installing the handler or registering the key fails.
    init?(keyCode: UInt32, modifiers: UInt32, onFire: @escaping () -> Void) {
        self.onFire = onFire

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else { return noErr }
                let hotKey = Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue()
                hotKey.onFire()
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &handlerRef
        )
        guard installStatus == noErr else { return nil }

        // Four-char signature 'AGM1' identifies our hot key.
        let hotKeyID = EventHotKeyID(signature: OSType(0x4147_4D31), id: 1)
        let registerStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        guard registerStatus == noErr else { return nil }
    }

    /// Convenience for the default Agent Manager shortcut: Control + Option +
    /// Space.
    static func controlOptionSpace(onFire: @escaping () -> Void) -> GlobalHotKey? {
        GlobalHotKey(
            keyCode: UInt32(kVK_Space),
            modifiers: UInt32(controlKey | optionKey),
            onFire: onFire
        )
    }

    deinit {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let handlerRef {
            RemoveEventHandler(handlerRef)
        }
    }
}
