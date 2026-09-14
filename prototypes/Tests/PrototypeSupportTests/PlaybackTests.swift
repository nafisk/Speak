import AVFoundation
import Foundation
import Testing
@testable import PrototypeSupport

@Test @MainActor func speedValidation() throws {
    for rate: Float in [0, 0.49, 2.01, .nan, .infinity] {
        #expect(throws: (any Error).self) { try SpeechPlayback(speed: rate) }
    }
    let playback = try SpeechPlayback()
    try playback.setSpeed(1.5)
    #expect(playback.speed == 1.5)
    #expect(!playback.isPlaying)
}

@Test(.enabled(if: ProcessInfo.processInfo.environment["SPEAK_AUDIO_TESTS"] == "1"))
@MainActor func changingSpeedKeepsTheSameAudioMoving() async throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("speak-rate-\(UUID()).wav")
    defer { try? FileManager.default.removeItem(at: url) }
    let format = try #require(AVAudioFormat(standardFormatWithSampleRate: 24000, channels: 1))
    let buffer = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 240000))
    buffer.frameLength = buffer.frameCapacity
    let samples = try #require(buffer.floatChannelData?[0])
    for i in 0..<Int(buffer.frameLength) { samples[i] = Float(sin(Double(i) * 0.05)) * 0.01 }
    do { let file = try AVAudioFile(forWriting: url, settings: format.settings); try file.write(from: buffer) }
    let playback = try SpeechPlayback()
    defer { playback.stop() }
    try playback.play(Data(contentsOf: url), volume: 0)
    try await Task.sleep(for: .milliseconds(200))
    var position = playback.position
    for target: Float in [2, 0.5, 1.5] {
        try playback.setSpeed(target)
        for _ in 0..<25 {
            try await Task.sleep(for: .milliseconds(10))
            #expect(playback.isPlaying)
            // AVAudioPlayer's reported timestamp can jitter by sub-millisecond amounts
            // during a rate update. Allow 5 ms, but fail any seek/restart-sized jump.
            #expect(playback.position >= position - 0.005)
            position = max(position, playback.position)
        }
        #expect(abs(playback.currentRate - target) < 0.01)
    }
    try playback.setSpeed(2)
    try await Task.sleep(for: .milliseconds(30))
    try playback.setSpeed(0.75)
    try await Task.sleep(for: .milliseconds(250))
    #expect(abs(playback.currentRate - 0.75) < 0.01)
    #expect(playback.position > position)
    playback.stop()
    #expect(!playback.isPlaying)
    #expect(playback.speed == 0.75)
}
