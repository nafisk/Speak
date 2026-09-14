import AVFoundation
import FluidAudio
import Foundation
import PrototypeSupport

@main
struct SpeakSTT {
    @MainActor static func main() async {
        do { try await run() }
        catch { note("Error: \(error.localizedDescription)"); exit(1) }
    }

    @MainActor static func run() async throws {
        let options = try Options(Array(CommandLine.arguments.dropFirst()),
            valueNames: ["--file", "--repeat", "--format"], flagNames: ["--mic", "--help"])
        if options.flags.contains("--help") {
            print("""
            speak-stt --file AUDIO [--repeat 21]
            speak-stt --mic [--format plain|lists]
            Parakeet v3, local English dictation. Models download on first use.
            --mic keeps models loaded: Enter starts/stops each recording; q exits between trials.
            JSON lines on stdout; status on stderr. First inference is separate from warm trials.
            File input: 0.25–120 seconds. This prototype finalizes after recording; no live partial text.
            --format lists turns "start a list ... next item ... end list" into Markdown bullets.
            Formatting is opt-in. text contains the result; raw_text always preserves the recognizer output.
            """)
            return
        }
        guard let format = DictationFormat(rawValue: options.values["--format"] ?? "plain") else {
            throw PrototypeError("--format must be plain or lists.")
        }
        let microphone = options.flags.contains("--mic")
        guard microphone != (options.values["--file"] != nil) else { throw PrototypeError("Choose exactly one of --file or --mic.") }
        let repeats = try options.repeats()
        guard !microphone || options.values["--repeat"] == nil else { throw PrototypeError("--repeat is for file benchmarks; --mic is interactive.") }
        guard !microphone || isatty(STDIN_FILENO) != 0 else { throw PrototypeError("--mic requires an interactive terminal.") }

        // Validate file before triggering any model download.
        let samples: [Float]?
        if let path = options.values["--file"] {
            let url = URL(fileURLWithPath: path)
            let file = try AVAudioFile(forReading: url)
            guard Double(file.length) / file.processingFormat.sampleRate <= 120 else { throw PrototypeError("Maximum file duration is 120 seconds.") }
            samples = try AudioConverter().resampleAudioFile(url)
            try validateAudio(samples!, sampleRate: 16000)
        } else { samples = nil }

        note("Loading Parakeet v3 (first use downloads model weights)…")
        let loadStart = now()
        let models = try await AsrModels.downloadAndLoad(version: .v3)
        let manager = AsrManager(models: models)
        try emit(["event": "model_ready", "model": "parakeet-tdt-0.6b-v3", "runtime": "FluidAudio 0.15.7",
                  "load_seconds": now() - loadStart, "cache": AsrModels.defaultCacheDirectory().path])
        var timings: [Double] = []
        if microphone {
            let allowed = await AVCaptureDevice.requestAccess(for: .audio)
            guard allowed else { throw PrototypeError("Microphone access denied. Enable your terminal under System Settings → Privacy & Security → Microphone.") }
            note("Ready. Enter starts recording; q quits. After starting, Enter stops (maximum 120 seconds).")
            while let line = await terminalLine(), line.lowercased() != "q" {
                let url = FileManager.default.temporaryDirectory.appendingPathComponent("speak-\(UUID().uuidString).wav")
                defer { try? FileManager.default.removeItem(at: url) }
                let recorder = try AVAudioRecorder(url: url, settings: [
                    AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: 16000,
                    AVNumberOfChannelsKey: 1, AVLinearPCMBitDepthKey: 16,
                    AVLinearPCMIsFloatKey: false, AVLinearPCMIsBigEndianKey: false])
                let start = now()
                guard recorder.record(forDuration: 120) else { throw PrototypeError("Microphone recording could not start.") }
                note("Recording. Press Enter to stop.")
                try emit(["event": "recording_started", "start_call_seconds": now() - start])
                _ = await terminalLine()
                let stopped = now()
                recorder.stop()
                let recorded = try AudioConverter().resampleAudioFile(url)
                do {
                    try validateAudio(recorded, sampleRate: 16000)
                    timings.append(try await transcribe(recorded, manager: manager, index: timings.count + 1, start: stopped, format: format))
                } catch { note("Trial failed: \(error.localizedDescription)") }
                note("Ready. Enter starts another recording; q quits.")
            }
        } else if let samples {
            for index in 1...repeats { timings.append(try await transcribe(samples, manager: manager, index: index, start: now(), format: format)) }
        }
        try summary(timings)
    }

    static func transcribe(_ samples: [Float], manager: AsrManager, index: Int, start: Double, format: DictationFormat) async throws -> Double {
        var state = try TdtDecoderState()
        let result = try await manager.transcribe(samples, decoderState: &state)
        let formattingStart = now()
        let text = format.apply(to: result.text)
        let formattingSeconds = now() - formattingStart
        let elapsed = now() - start
        let duration = Double(samples.count) / 16000
        try emit(["event": "transcription", "trial": index, "phase": index == 1 ? "first_inference" : "warm",
                  "text": text, "raw_text": result.text, "format": format.rawValue, "formatting_seconds": formattingSeconds,
                  "audio_seconds": duration, "processing_seconds": elapsed,
                  "realtime_factor": elapsed / duration])
        return elapsed
    }

    static func terminalLine() async -> String? { await Task.detached { readLine() }.value }
}
