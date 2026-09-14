import AppKit
import Carbon
import PrototypeSupport

@MainActor final class HotKey {
    private var reference: EventHotKeyRef?
    private var handler: EventHandlerRef?
    var action: (() -> Void)?
    init() {
        var type = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, context in
            guard let context else { return OSStatus(eventNotHandledErr) }
            MainActor.assumeIsolated {
                Unmanaged<HotKey>.fromOpaque(context).takeUnretainedValue().action?()
            }
            return noErr
        }, 1, &type, Unmanaged.passUnretained(self).toOpaque(), &handler)
    }
    func register(alternate: Bool) throws {
        if let reference { UnregisterEventHotKey(reference); self.reference = nil }
        let modifiers = UInt32(controlKey | (alternate ? shiftKey : optionKey))
        let result = RegisterEventHotKey(UInt32(kVK_Space), modifiers,
            EventHotKeyID(signature: 0x53504B31, id: 1), GetApplicationEventTarget(), 0, &reference)
        guard result == noErr else { throw PrototypeError("Shortcut is unavailable. Choose the other shortcut in Settings. (\(result))") }
    }
    func stop() {
        if let reference { UnregisterEventHotKey(reference); self.reference = nil }
        if let handler { RemoveEventHandler(handler); self.handler = nil }
    }
}
