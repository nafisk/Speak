import AVFoundation
import FluidAudio
import Foundation
import PrototypeSupport

actor SpeechEngine {
    private var asr: AsrManager?
    private var tts: KokoroAneManager?
    private var asrLoad: Task<AsrManager, Error>?
    private var ttsLoad: Task<KokoroAneManager, Error>?

    func prepareDictation() async throws {
        if asr != nil { return }
        if asrLoad == nil {
            asrLoad = Task {
                // The installed prototype already provisioned these models. No implicit ASR download.
                let models = try await AsrModels.loadFromCache(version: .v3)
                return AsrManager(models: models)
            }
        }
        do { asr = try await asrLoad!.value; asrLoad = nil }
        catch { asrLoad = nil; throw error }
    }
    func transcribe(_ url: URL) async throws -> String {
        try await prepareDictation()
        let samples = try AudioConverter().resampleAudioFile(url)
        try validateAudio(samples, sampleRate: 16000)
        var decoder = try TdtDecoderState()
        return try await asr!.transcribe(samples, decoderState: &decoder).text
    }
    func synthesize(_ text: String) async throws -> Data {
        if tts == nil {
            if ttsLoad == nil {
                ttsLoad = Task {
                    let manager = KokoroAneManager()
                    try await manager.initialize()
                    _ = try await manager.synthesize(text: "Ready to speak.")
                    return manager
                }
            }
            do { tts = try await ttsLoad!.value; ttsLoad = nil }
            catch { ttsLoad = nil; throw error }
        }
        return try await tts!.synthesize(text: text)
    }
}
