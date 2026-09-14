import AVFoundation
import FluidAudio
import Foundation
import PrototypeSupport

@main
struct SpeakTTS {
    @MainActor static func main() async {
        do { try await run() }
        catch { note("Error: \(error.localizedDescription)"); exit(1) }
    }

    @MainActor static func run() async throws {
        let options = try Options(Array(CommandLine.arguments.dropFirst()),
            valueNames: ["--text", "--output", "--repeat", "--speed"], flagNames: ["--play", "--interactive", "--help"])
        if options.flags.contains("--help") {
            print("""
            speak-tts --text 'A short sentence.' --output /path/to/new.wav [--play] [--repeat 21]
            speak-tts --interactive [--speed 1.25]
            Kokoro 82M English, af_heart voice. Models download on first use.
            Or omit --text and pipe UTF-8 text through stdin. Maximum 300 characters per trial.
            Keeps models loaded for repeats. Saves first output only; refuses to overwrite files.
            JSON lines on stdout; status on stderr. Playback is optional; synthesis is not streaming.
            --interactive keeps the model warm, reads each line aloud, and saves no audio. :quit exits.
            While speaking: :speed 1.5, :faster, :slower, :stop. Rate range: 0.5–2.0; pitch is preserved.
            --speed changes playback only; saved WAVs remain at the model's normal speed.
            """)
            return
        }
        guard let speed = Float(options.values["--speed"] ?? "1") else { throw PrototypeError("Invalid --speed.") }
        try SpeechPlayback.validate(speed)
        if options.flags.contains("--interactive") {
            guard Set(options.values.keys).subtracting(["--speed"]).isEmpty, !options.flags.contains("--play"), isatty(STDIN_FILENO) != 0 else {
                throw PrototypeError("Use --interactive [--speed NUMBER] in a terminal; it plays each line automatically.")
            }
            try await interactive(speed: speed)
            return
        }
        let repeats = try options.repeats()
        guard let outputPath = options.values["--output"] else { throw PrototypeError("--output is required.") }
        let output = URL(fileURLWithPath: outputPath)
        guard !FileManager.default.fileExists(atPath: output.path) else { throw PrototypeError("Output already exists; choose a new filename.") }
        guard FileManager.default.fileExists(atPath: output.deletingLastPathComponent().path) else { throw PrototypeError("Output parent directory does not exist.") }
        let text: String
        if let supplied = options.values["--text"] { text = supplied }
        else {
            guard isatty(STDIN_FILENO) == 0 else { throw PrototypeError("Provide --text or pipe text through stdin.") }
            var data = Data()
            while data.count <= 4096 {
                let part = try FileHandle.standardInput.read(upToCount: 4097 - data.count) ?? Data()
                if part.isEmpty { break }
                data.append(part)
            }
            guard data.count <= 4096, let decoded = String(data: data, encoding: .utf8) else { throw PrototypeError("Expected at most 4096 UTF-8 bytes on stdin.") }
            text = decoded
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 300 else { throw PrototypeError("Provide 1–300 characters. Use short sentences to measure first-audio latency.") }

        note("Loading Kokoro English (first use downloads model and pronunciation assets)…")
        let manager = KokoroAneManager()
        let loadStart = now()
        try await manager.initialize()
        try emit(["event": "model_ready", "model": "Kokoro-82M", "voice": "af_heart",
                  "runtime": "FluidAudio 0.15.7", "load_seconds": now() - loadStart])
        var timings: [Double] = []
        for index in 1...repeats {
            let start = now()
            let data = try await manager.synthesize(text: trimmed)
            let elapsed = now() - start
            let player = try AVAudioPlayer(data: data)
            guard player.duration > 0 else { throw PrototypeError("Model produced empty audio.") }
            timings.append(elapsed)
            if index == 1 { try data.write(to: output, options: .withoutOverwriting) }
            var event: [String: Any] = ["event": "synthesis", "trial": index,
                "phase": index == 1 ? "first_inference" : "warm", "audio_seconds": player.duration,
                "synthesis_seconds": elapsed, "realtime_factor": elapsed / player.duration]
            if options.flags.contains("--play") {
                player.enableRate = true
                player.rate = speed
                player.prepareToPlay()
                guard player.play() else { throw PrototypeError("Audio playback could not start.") }
                event["playback_scheduled_seconds"] = now() - start
            }
            try emit(event)
            while player.isPlaying { try await Task.sleep(for: .milliseconds(25)) }
        }
        try summary(timings)
        note("Saved first trial to \(output.path)")
    }

    @MainActor static func interactive(speed: Float) async throws {
        let playback = try SpeechPlayback(speed: speed)
        defer { playback.stop() }
        let manager = KokoroAneManager()
        note("Loading and warming Kokoro. First setup may take a minute…")
        let start = now()
        try await manager.initialize()
        _ = try await manager.synthesize(text: "Ready to speak.")
        try emit(["event": "warmed_up", "setup_seconds": now() - start])
        note("Ready. Enter a short sentence. While speaking: :speed 1.5, :faster, :slower, :stop. :quit exits.")
        while let line = await Task.detached(operation: { readLine() }).value {
            let text = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if text == ":quit" { break }
            if text == ":stop" { playback.stop(); note("Stopped."); continue }
            if text.hasPrefix(":") {
                do {
                    let parts = text.split(whereSeparator: { $0.isWhitespace })
                    let target: Float
                    if text == ":faster" { target = min(2, playback.speed + 0.1) }
                    else if text == ":slower" { target = max(0.5, playback.speed - 0.1) }
                    else if parts.count == 2, parts[0] == ":speed", let value = Float(parts[1]) { target = value }
                    else { throw PrototypeError("Use :speed 0.5–2.0, :faster, :slower, :stop, or :quit.") }
                    try playback.setSpeed(target)
                    try emit(["event": "speed_changed", "speed": target, "playing": playback.isPlaying,
                              "audio_position_seconds": playback.position])
                } catch { note(error.localizedDescription) }
                continue
            }
            guard !playback.isPlaying else { note("Still speaking. Change speed, or use :stop before entering new text."); continue }
            guard !text.isEmpty, text.count <= 300 else { note("Enter 1–300 characters."); continue }
            do {
                let submitted = now()
                let data = try await manager.synthesize(text: text)
                let synthesized = now() - submitted
                try await playback.play(data)
                try emit(["event": "interactive_synthesis", "synthesis_seconds": synthesized,
                          "playback_scheduled_seconds": now() - submitted, "speed": playback.speed])
            } catch { note("Trial failed: \(error.localizedDescription)") }
            note("Speed controls are available now. Enter another sentence after playback, or :quit.")
        }
    }
}
