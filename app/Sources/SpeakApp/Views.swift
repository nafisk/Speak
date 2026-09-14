import AppKit
import SwiftUI
import SpeakCore

private let tide = Color(nsColor: NSColor(name: nil) { appearance in
    appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        ? NSColor(red: 0.55, green: 0.87, blue: 0.90, alpha: 1)
        : NSColor(red: 0, green: 0.42, blue: 0.46, alpha: 1)
})

struct SpeakView: View {
    @ObservedObject var model: AppModel
    @State private var settings = false
    @AppStorage("appearance") private var appearance = "system"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Label("Speak", systemImage: "waveform").font(.headline)
                Spacer()
                Button { withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) { settings.toggle() } } label: {
                    Image(systemName: settings ? "chevron.left" : "slider.horizontal.3")
                }.buttonStyle(.plain).help(settings ? "Back to reader" : "Settings")
                .accessibilityLabel(settings ? "Back to reader" : "Settings")
            }
            if settings { settingsView.transition(.opacity) }
            else { reader.transition(.opacity) }
        }
        .padding(12).frame(minWidth: 320, idealWidth: 440)
        .tint(tide)
        .preferredColorScheme(appearance == "system" ? nil : appearance == "dark" ? .dark : .light)
        .onChange(of: settings) { _, open in model.resizeWindow?(open ? 570 : 350) }
    }
    private var reader: some View {
        VStack(spacing: 9) {
            TextEditor(text: $model.readerText)
                .font(.system(size: 16)).scrollContentBackground(.hidden)
                .padding(8).frame(minHeight: 140, idealHeight: 170)
                .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.quaternary))
                .accessibilityLabel("Text to read")
                .disabled(model.reading)
            HStack { Text("On your Mac"); Spacer(); Text("Heart · English") }.font(.caption).foregroundStyle(.secondary)
            VStack(spacing: 9) {
                HStack {
                    Button(model.reading ? (model.paused ? "Resume" : "Pause") : "Listen") { model.readText() }
                        .buttonStyle(.borderedProminent)
                        .foregroundStyle(Color(nsColor: NSColor(name: nil) { appearance in
                            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                                ? NSColor(red: 0.035, green: 0.18, blue: 0.20, alpha: 1) : .white
                        }))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.readerStatus).font(.caption).lineLimit(2)
                        if model.playbackDuration > 0 {
                            ProgressView(value: min(model.playbackPosition, model.playbackDuration), total: model.playbackDuration)
                                .accessibilityLabel("Current passage progress")
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    Button { model.stopReading() } label: { Image(systemName: "stop.fill") }
                        .disabled(!model.reading).help("Stop speech").accessibilityLabel("Stop speech")
                }
                HStack {
                    Text("Speed").font(.caption)
                    Slider(value: Binding(get: { model.speed }, set: { model.setSpeed($0) }), in: 0.5...2, step: 0.1)
                        .accessibilityLabel("Reading speed")
                    Text(String(format: "%.1f×", model.speed)).monospacedDigit().font(.caption).frame(width: 36)
                }
            }.padding(10).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            if !model.transcript.isEmpty {
                GroupBox("Latest dictation") {
                    Text(model.transcript).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                    HStack { Spacer(); Button("Copy") { model.copyTranscript() } }
                }
            }
            Text("Dictate anywhere with \(model.shortcutLabel)").font(.caption).foregroundStyle(.secondary)
        }
    }
    private var settingsView: some View {
        Form {
            Section("Dictation") {
                Picker("Shortcut", selection: $model.shortcutAlternate) {
                    Text("⌃ ⌥ Space").tag(false); Text("⌃ ⇧ Space").tag(true)
                }.onChange(of: model.shortcutAlternate) { _, _ in model.configureShortcut() }
                if let error = model.shortcutError { Text(error).foregroundStyle(.red) }
                Toggle("Spoken list cues", isOn: $model.lists).onChange(of: model.lists) { _, _ in model.saveSettings() }
                Text("Preserves your wording. Lists use “start a list”, “next item”, and “end list”.").font(.caption).foregroundStyle(.secondary)
                Button("Enable microphone…") { Task { _ = await AVCaptureDevice.requestAccess(for: .audio) } }
                Button("Enable text insertion…") { InsertionTarget.requestPermission() }
            }
            Section("Reading") {
                Toggle("Remember speed", isOn: $model.rememberSpeed).onChange(of: model.rememberSpeed) { _, _ in model.saveSettings() }
                Picker("Appearance", selection: $appearance) { Text("System").tag("system"); Text("Light").tag("light"); Text("Dark").tag("dark") }
            }
            Section("Local model") {
                Text(model.dictationReady ? "Dictation model loaded" : model.status).font(.caption)
                Button("Prepare dictation model") { model.prepare() }.disabled(model.hasActiveDictation)
                Text("Models stay loaded while Speak runs. First TTS use may download missing model assets. Voice: Heart (English).").font(.caption).foregroundStyle(.secondary)
            }
        }.formStyle(.grouped).frame(minHeight: 440)
    }
}

import AVFoundation

struct DictationOverlay: View {
    @ObservedObject var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                if model.session.phase == .recording {
                    Text("Listening").font(.caption)
                    HStack(alignment: .center, spacing: 3) {
                        ForEach(0..<12) { index in
                            Capsule().fill(tide).frame(width: 3, height: 3 + model.level * Double([13, 21, 16, 27, 20, 30, 17, 25, 15, 23, 18, 10][index]))
                        }
                    }.frame(height: 30).accessibilityHidden(true)
                    Text(String(format: "%d:%02d", Int(model.seconds) / 60, Int(model.seconds) % 60)).monospacedDigit().font(.caption)
                } else if model.session.phase == .recovery {
                    Image(systemName: "exclamationmark.circle")
                    Text(model.transcript.isEmpty ? "Needs attention" : "Ready to copy").font(.caption)
                    Button("Open") { model.showWindow?() }
                } else {
                    if model.session.phase == .inserted { Image(systemName: "checkmark") }
                    else { ProgressView().controlSize(.small) }
                    Text(model.status).font(.caption).lineLimit(1)
                }
                if model.session.phase == .recording {
                    Button { model.finishDictation() } label: { Image(systemName: "stop.fill") }
                        .help("Finish dictation").accessibilityLabel("Finish dictation")
                }
                if model.session.phase != .inserted {
                    Button { model.cancelDictation() } label: { Image(systemName: "xmark") }
                        .help("Cancel dictation").accessibilityLabel("Cancel dictation")
                }
            }.buttonStyle(.plain)
            if model.session.phase == .recovery { Text(model.status).font(.caption2).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true) }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .frame(minWidth: 240, maxWidth: 350)
        .background {
            if reduceTransparency { Capsule().fill(Color(nsColor: .windowBackgroundColor)) }
            else if #available(macOS 26, *) { Capsule().fill(.clear).glassEffect(.regular, in: .capsule) }
            else { Capsule().fill(.regularMaterial) }
        }
        .overlay(Capsule().stroke(.quaternary))
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: model.session.phase)
        .animation(reduceMotion ? nil : .linear(duration: 0.06), value: model.level)
        .accessibilityElement(children: .contain)
        .onChange(of: model.session.phase) { _, phase in
            let text = phase == .recording ? "Recording started" : phase == .transcribing ? "Transcribing" : model.status
            NSAccessibility.post(element: NSApp as Any, notification: .announcementRequested, userInfo: [.announcement: text, .priority: NSAccessibilityPriorityLevel.medium.rawValue])
        }
        .padding(8)
    }
}
