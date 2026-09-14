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
    try await playback.play(Data(contentsOf: url), volume: 0)
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
    playback.pause()
    let pausedAt = playback.position
    try await Task.sleep(for: .milliseconds(100))
    #expect(!playback.isPlaying)
    #expect(abs(playback.position - pausedAt) < 0.005)
    try playback.setSpeed(1.25)
    try playback.resume()
    try await Task.sleep(for: .milliseconds(100))
    #expect(playback.isPlaying)
    #expect(playback.position > pausedAt)
    #expect(abs(playback.currentRate - 1.25) < 0.01)
    playback.stop()
    #expect(!playback.isPlaying)
    #expect(playback.speed == 1.25)
}

@Test @MainActor func blockedAudioPreparationTimesOutAndCanBeStopped() async throws {
    let playback = SpeechPlayback(preparationTimeout: .milliseconds(50)) { _ in
        Thread.sleep(forTimeInterval: 0.3)
        throw PrototypeError("Simulated unavailable output")
    }
    let started = ContinuousClock.now
    do { try await playback.play(Data()); Issue.record("Expected timeout") }
    catch { #expect(error.localizedDescription.contains("timed out")) }
    #expect(started.duration(to: .now) < .milliseconds(250))
    playback.stop()
    #expect(!playback.isPlaying)
    // Reject additional work while the original device call remains blocked.
    do { try await playback.play(Data()); Issue.record("Expected busy output") }
    catch { #expect(error.localizedDescription.contains("still unavailable")) }
    try await Task.sleep(for: .milliseconds(350))
    #expect(!playback.isPlaying) // A late worker completion cannot start sound.
}

@Test @MainActor func stoppingAudioPreparationDiscardsItsCompletion() async throws {
    let playback = SpeechPlayback(preparationTimeout: .seconds(1)) { _ in
        Thread.sleep(forTimeInterval: 0.15)
        throw PrototypeError("Simulated late completion")
    }
    let work = Task { try await playback.play(Data()) }
    try await Task.sleep(for: .milliseconds(25))
    playback.stop()
    do { try await work.value; Issue.record("Expected cancellation") }
    catch { #expect(error is CancellationError) }
    try await Task.sleep(for: .milliseconds(200))
    #expect(!playback.isPlaying)
}
