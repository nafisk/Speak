import AppKit
import SwiftUI

@MainActor final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()
    private var item: NSStatusItem?
    private var window: NSWindow?
    private var panel: OverlayPanel?
    private var overlayGeneration = UUID()
    private let control = ControlServer()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let mainMenu = NSMenu()
        let applicationMenu = NSMenuItem()
        let commands = NSMenu()
        let quitItem = NSMenuItem(title: "Quit Speak", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self; commands.addItem(quitItem)
        applicationMenu.submenu = commands; mainMenu.addItem(applicationMenu); NSApp.mainMenu = mainMenu
        do { try control.start(model: model) }
        catch { model.status = error.localizedDescription }
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item?.button?.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "Speak")
        let menu = NSMenu()
        for (title, selector) in [("Open Speak", #selector(openWindow)), ("Toggle Dictation", #selector(toggleDictation)), ("Cancel Dictation", #selector(cancelDictation)), ("Stop Speaking", #selector(stopSpeaking)), ("Quit Speak", #selector(quit))] {
            let entry = NSMenuItem(title: title, action: selector, keyEquivalent: ""); entry.target = self; menu.addItem(entry)
        }
        item?.menu = menu
        model.showWindow = { [weak self] in self?.openWindow() }
        model.resizeWindow = { [weak self] height in
            guard let window = self?.window else { return }
            let frame = window.frameRect(forContentRect: NSRect(x: 0, y: 0, width: window.contentLayoutRect.width, height: height))
            window.setFrame(NSRect(x: window.frame.minX, y: window.frame.maxY - frame.height, width: frame.width, height: frame.height), display: true, animate: !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
        }
        model.showOverlay = { [weak self] in self?.presentOverlay() }
        model.hideOverlay = { [weak self] in self?.dismissOverlay() }
        model.prepare()
        openWindow()
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationWillTerminate(_ notification: Notification) { control.stop(); model.shutdown() }
    @objc func openWindow() {
        if window == nil {
            let host = NSHostingController(rootView: SpeakView(model: model))
            let next = NSWindow(contentViewController: host)
            next.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            next.title = "Speak"; next.setContentSize(NSSize(width: 440, height: 350))
            next.minSize = NSSize(width: 340, height: 330)
            next.isReleasedWhenClosed = false; next.center(); window = next
        }
        NSApp.activate(ignoringOtherApps: true); window?.makeKeyAndOrderFront(nil)
    }
    func presentOverlay() {
        overlayGeneration = UUID()
        if panel == nil {
            let next = OverlayPanel(contentRect: NSRect(x: 0, y: 0, width: 380, height: 120), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            next.isOpaque = false; next.backgroundColor = .clear; next.hasShadow = false
            next.level = .floating; next.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            next.isReleasedWhenClosed = false; next.hidesOnDeactivate = false
            next.contentView = NSHostingView(rootView: DictationOverlay(model: model)); panel = next
        }
        guard let panel else { return }
        let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main
        if let screen { panel.setFrameOrigin(NSPoint(x: screen.visibleFrame.midX - 190, y: screen.visibleFrame.minY + 18)) }
        if !panel.isVisible { panel.alphaValue = 0; panel.orderFrontRegardless() }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 0 : 0.18
            panel.animator().alphaValue = 1
        }
    }
    func dismissOverlay() {
        guard let panel else { return }
        let token = UUID(); overlayGeneration = token
        NSAnimationContext.runAnimationGroup { context in
            context.duration = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 0 : 0.18
            panel.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            MainActor.assumeIsolated { if self?.overlayGeneration == token { panel.orderOut(nil) } }
        }
    }
    @objc func toggleDictation() { model.toggleDictation() }
    @objc func cancelDictation() { model.cancelDictation() }
    @objc func stopSpeaking() { model.stopReading() }
    @objc func quit() { NSApp.terminate(nil) }
}

@main enum SpeakMain {
    @MainActor static func main() {
        let app = NSApplication.shared
        if let identifier = Bundle.main.bundleIdentifier,
           let running = NSRunningApplication.runningApplications(withBundleIdentifier: identifier).first(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) {
            running.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
            return
        }
        let delegate = AppDelegate()
        app.delegate = delegate; app.setActivationPolicy(.accessory)
        app.run()
        withExtendedLifetime(delegate) {}
    }
}
