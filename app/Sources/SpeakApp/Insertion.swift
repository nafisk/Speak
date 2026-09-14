import AppKit
@preconcurrency import ApplicationServices
import SpeakCore

@MainActor struct InsertionTarget {
    let element: AXUIElement
    let snapshot: FieldSnapshot

    static var trusted: Bool { AXIsProcessTrusted() }
    static func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
    private static func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }
    private static func currentElement() -> AXUIElement? {
        guard let app = NSWorkspace.shared.frontmostApplication,
              app.processIdentifier != ProcessInfo.processInfo.processIdentifier else { return nil }
        guard let value = attribute(AXUIElementCreateApplication(app.processIdentifier), kAXFocusedUIElementAttribute),
              CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return (value as! AXUIElement)
    }
    private static func read(_ element: AXUIElement) -> FieldSnapshot? {
        guard (attribute(element, kAXSubroleAttribute) as? String) != "AXSecureTextField",
              let text = attribute(element, kAXValueAttribute) as? String,
              let rangeObject = attribute(element, kAXSelectedTextRangeAttribute),
              CFGetTypeID(rangeObject) == AXValueGetTypeID() else { return nil }
        let rangeValue = rangeObject as! AXValue
        guard AXValueGetType(rangeValue) == .cfRange else { return nil }
        var range = CFRange(); var pid: pid_t = 0
        guard AXValueGetValue(rangeValue, .cfRange, &range), AXUIElementGetPid(element, &pid) == .success else { return nil }
        return FieldSnapshot(process: pid, value: text, location: range.location, length: range.length)
    }
    static func capture() -> InsertionTarget? {
        guard trusted, let element = currentElement(), let snapshot = read(element) else { return nil }
        return InsertionTarget(element: element, snapshot: snapshot)
    }
    /// Direct Accessibility insertion preserves the user's clipboard and never sends Enter.
    /// ponytail: unsupported fields get manual copy; a guarded paste fallback can follow device validation.
    func insert(_ text: String) -> Bool {
        guard Self.trusted, let focused = Self.currentElement(), CFEqual(focused, element),
              Self.read(focused) == snapshot, snapshot.replacement(text) != nil else { return false }
        return AXUIElementSetAttributeValue(element, kAXSelectedTextAttribute as CFString, text as CFString) == .success
    }
}
