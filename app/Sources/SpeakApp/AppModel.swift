import AppKit
import AVFoundation
import Combine
import Foundation
import PrototypeSupport
import SpeakCore

@MainActor final class AppModel: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published private(set) var session = DictationSession()
    @Published var status = "Ready"
    @Published var level: Double = 0
    @Published var seconds: Double = 0
    @Published var rawTranscript = ""
    @Published var transcript = ""
    @Published var dictationReady = false
    @Published var readerText = ""
    @Published var reading = false
    @Published var paused = false
    @Published var synthesizing = false
    @Published var readerStatus = "Ready"
    @Published var speed = UserDefaults.standard.object(forKey: "speed") as? Double ?? 1
    @Published var playbackPosition = 0.0
    @Published var playbackDuration = 0.0
    @Published var shortcutError: String?
    @Published var shortcutAlternate = UserDefaults.standard.bool(forKey: "shortcutAlternate")
    @Published var lists = UserDefaults.standard.bool(forKey: "lists")
    @Published var rememberSpeed = UserDefaults.standard.object(forKey: "rememberSpeed") as? Bool ?? true
    private let engine = SpeechEngine()
    private let playback = try! SpeechPlayback()
    private let hotkey = HotKey()
    private var recorder: AVAudioRecorder?
    private var recordingDirectory: URL?
    private var target: InsertionTarget?
    private var dictationTask: Task<Void, Never>?
    private var readerTask: Task<Void, Never>?
    private var readingID: UUID?
    private var inferenceRunning = false
    private var timer: Timer?
    private var escapeMonitor: Any?
    private var localEscape: Any?
    var showOverlay: (() -> Void)?
    var hideOverlay: (() -> Void)?
    var showWindow: (() -> Void)?
    var resizeWindow: ((Double) -> Void)?
    var hasActiveDictation: Bool { [.preparing, .recording, .transcribing].contains(session.phase) }
    var shortcutLabel: String { shortcutAlternate ? "⌃ ⇧ Space" : "⌃ ⌥ Space" }

    override init() {
        super.init()
        hotkey.action = { [weak self] in self?.toggleDictation() }
        configureShortcut()
        timer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        timer?.tolerance = 0.01
        // Escape monitoring only observes; it never suppresses keys in another application.
        escapeMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { Task { @MainActor in if self?.hasActiveDictation == true { self?.cancelDictation() } } }
        }
        localEscape = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53, self?.hasActiveDictation == true { self?.cancelDictation(); return nil }
            return event
        }
    }
    func configureShortcut() {
        do { try hotkey.register(alternate: shortcutAlternate); shortcutError = nil
            UserDefaults.standard.set(shortcutAlternate, forKey: "shortcutAlternate")
        } catch { shortcutError = error.localizedDescription }
    }
    func saveSettings() {
        UserDefaults.standard.set(lists, forKey: "lists")
        UserDefaults.standard.set(rememberSpeed, forKey: "rememberSpeed")
    }
    func setSpeed(_ value: Double) {
        do { try playback.setSpeed(Float(value)); speed = value
            if rememberSpeed { UserDefaults.standard.set(value, forKey: "speed") }
        } catch { readerStatus = error.localizedDescription }
    }
    func prepare() {
        guard !hasActiveDictation else { return }
        status = "Loading local dictation model…"
        Task {
            do { try await engine.prepareDictation(); dictationReady = true; if !hasActiveDictation { status = "Ready" } }
            catch { if !hasActiveDictation { status = "Dictation model unavailable. Run the STT setup described in the app README." } }
        }
    }
    func toggleDictation() {
        if session.phase == .recording { finishDictation(); return }
        guard !hasActiveDictation, !inferenceRunning else { return }
        stopReading()
        guard let token = session.begin() else { return }
        transcript = ""; rawTranscript = ""; seconds = 0; level = 0
        target = InsertionTarget.capture()
        status = "Preparing microphone…"; showOverlay?()
        dictationTask = Task {
            do {
                let allowed = await AVCaptureDevice.requestAccess(for: .audio)
                guard session.isCurrent(token) else { return }
                guard allowed else { throw PrototypeError("Microphone access is off. Enable Speak in System Settings → Privacy & Security → Microphone.") }
                if !dictationReady { status = "Loading local model…" }
                try await engine.prepareDictation()
                guard session.isCurrent(token) else { return }
                dictationReady = true
                let directory = FileManager.default.temporaryDirectory.appendingPathComponent("Speak-\(UUID().uuidString)", isDirectory: true)
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
                recordingDirectory = directory
                let audioURL = directory.appendingPathComponent("capture.wav")
                let capture = try AVAudioRecorder(url: audioURL, settings: [AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: 16000, AVNumberOfChannelsKey: 1, AVLinearPCMBitDepthKey: 16, AVLinearPCMIsFloatKey: false, AVLinearPCMIsBigEndianKey: false])
                capture.delegate = self; capture.isMeteringEnabled = true
                guard capture.record(forDuration: 120) else { throw PrototypeError("Microphone recording could not start. Check your input device.") }
                recorder = capture
                _ = session.transition(token, to: .recording); status = "Listening"
            } catch { guard session.isCurrent(token) else { return }; recover(error.localizedDescription, token: token); removeRecording() }
        }
    }
    func finishDictation() {
        guard let token = session.id, session.phase == .recording, let recorder else { return }
        let url = recorder.url; recorder.stop(); self.recorder = nil; level = 0
        _ = session.transition(token, to: .transcribing); status = "Transcribing…"
        let format: DictationFormat = lists ? .lists : .plain
        let started = now(); inferenceRunning = true
        dictationTask = Task {
            defer { inferenceRunning = false; try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
            do {
                let raw = try await engine.transcribe(url)
                guard session.isCurrent(token) else { return }
                rawTranscript = raw; transcript = format.apply(to: raw).trimmingCharacters(in: .whitespacesAndNewlines)
                guard !transcript.isEmpty else { throw PrototypeError("No speech recognized. Try again.") }
                if target?.insert(transcript) == true {
                    _ = session.transition(token, to: .inserted); status = "Inserted · \(String(format: "%.2f", now() - started))s"
                    Task { try? await Task.sleep(for: .seconds(1)); if session.isCurrent(token), session.phase == .inserted { session.cancel(); hideOverlay?() } }
                } else {
                    recover("Ready to copy — the original field changed or does not support direct insertion.", token: token)
                }
            } catch { guard session.isCurrent(token) else { return }; recover(error.localizedDescription, token: token) }
        }
    }
    func cancelDictation() {
        session.cancel(); dictationTask?.cancel(); recorder?.stop(); recorder = nil
        // Inference may still be reading its private WAV; its completion owns cleanup.
        if !inferenceRunning { removeRecording() }
        transcript = ""; rawTranscript = ""; target = nil; level = 0
        status = "Cancelled"; hideOverlay?()
    }
    private func recover(_ message: String, token: UUID) {
        guard session.transition(token, to: .recovery) else { return }
        status = message; level = 0; showOverlay?()
    }
    func copyTranscript() {
        guard !transcript.isEmpty else { return }
        NSPasteboard.general.clearContents(); NSPasteboard.general.setString(transcript, forType: .string)
        status = "Copied. Paste into your text field."
    }
    private func removeRecording() {
        if let recordingDirectory { try? FileManager.default.removeItem(at: recordingDirectory) }
        recordingDirectory = nil
    }
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            guard self.recorder === recorder, session.phase == .recording else { return }
            if flag { finishDictation() }
            else if let token = session.id { self.recorder = nil; recover("Recording stopped unexpectedly. Check your microphone and try again.", token: token); removeRecording() }
        }
    }
    private func tick() {
        if let recorder, session.phase == .recording {
            recorder.updateMeters(); seconds = recorder.currentTime
            level = max(0, min(1, (Double(recorder.averagePower(forChannel: 0)) + 55) / 55))
        }
        let position = playback.position, duration = playback.duration
        if playbackPosition != position { playbackPosition = position }
        if playbackDuration != duration { playbackDuration = duration }
    }
    func readText() {
        guard !hasActiveDictation else { readerStatus = "Finish dictation first."; return }
        guard !reading else { togglePause(); return }
        let text = readerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, text.count <= 20000 else { readerStatus = "Enter 1–20,000 characters."; return }
        stopReading(); if !rememberSpeed { setSpeed(1) } else { setSpeed(speed) }
        let id = UUID(); readingID = id; reading = true; synthesizing = true; readerStatus = "Preparing speech…"
        readerTask = Task {
            do {
                let chunks = ReaderText.chunks(text)
                var pending = Task { try await engine.synthesize(chunks[0]) }
                defer { pending.cancel() }
                for index in chunks.indices {
                    guard readingID == id, !Task.isCancelled else { return }
                    synthesizing = true; readerStatus = index == 0 ? "Preparing speech…" : "Preparing next passage…"
                    let audio = try await pending.value
                    guard readingID == id, !Task.isCancelled else { return }
                    if index + 1 < chunks.count {
                        let next = chunks[index + 1]
                        pending = Task { try Task.checkCancellation(); return try await engine.synthesize(next) }
                    }
                    synthesizing = false
                    while paused { try await Task.sleep(for: .milliseconds(40)) }
                    try Task.checkCancellation()
                    try await playback.play(audio)
                    if paused { playback.pause() }
                    readerStatus = paused ? "Paused" : "Reading \(index + 1) of \(chunks.count)"
                    while playback.isPlaying || paused { try await Task.sleep(for: .milliseconds(40)) }
                    playback.stop()
                }
                if readingID == id { reading = false; synthesizing = false; readerStatus = "Finished" }
            } catch {
                guard readingID == id else { return }
                reading = false; paused = false; synthesizing = false; playback.stop(); readerStatus = "Speech failed: \(error.localizedDescription)"
            }
        }
    }
    func togglePause() {
        guard reading else { return }
        paused.toggle()
        if paused { playback.pause(); readerStatus = "Paused" }
        else {
            do { if !synthesizing && playback.duration > 0 { try playback.resume() }; readerStatus = synthesizing ? "Preparing speech…" : "Reading" }
            catch { stopReading(); readerStatus = error.localizedDescription }
        }
    }
    func stopReading() {
        readingID = nil; readerTask?.cancel(); playback.stop(); reading = false; paused = false; synthesizing = false; readerStatus = "Ready"
    }
    func shutdown() {
        cancelDictation(); stopReading(); hotkey.stop(); timer?.invalidate()
        if let escapeMonitor { NSEvent.removeMonitor(escapeMonitor) }
        if let localEscape { NSEvent.removeMonitor(localEscape) }
    }
}
