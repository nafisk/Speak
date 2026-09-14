import AVFoundation
import Foundation

/// A single playing utterance. Rate changes never replace, seek, or restart its player.
@MainActor public final class SpeechPlayback {
    private var player: AVAudioPlayer?
    private var ramp: Task<Void, Never>?
    // The worker owns the player until preparation finishes; only then does MainActor own it.
    struct PreparedAudio: @unchecked Sendable { let player: AVAudioPlayer }
    private let prepareAudio: @Sendable (Data) throws -> PreparedAudio
    private let preparationTimeout: Duration
    private var preparation: CheckedContinuation<PreparedAudio, any Error>?
    private var preparationWorkerBusy = false
    private var playbackID: UUID?
    private var timeoutTask: Task<Void, Never>?

    public private(set) var speed: Float
    public var isPlaying: Bool { player?.isPlaying ?? false }
    public var position: TimeInterval { player?.currentTime ?? 0 }
    public var currentRate: Float { player?.rate ?? speed }
    public var duration: TimeInterval { player?.duration ?? 0 }

    public init(speed: Float = 1) throws {
        try Self.validate(speed)
        self.speed = speed
        self.preparationTimeout = .seconds(5)
        self.prepareAudio = { data in
            let player = try AVAudioPlayer(data: data)
            player.enableRate = true
            guard player.prepareToPlay() else { throw PrototypeError("Audio output could not be prepared.") }
            return PreparedAudio(player: player)
        }
    }

    // Injection keeps blocked-device timeout/cancellation checks independent of real audio hardware.
    init(preparationTimeout: Duration, prepareAudio: @escaping @Sendable (Data) throws -> PreparedAudio) {
        self.speed = 1
        self.preparationTimeout = preparationTimeout
        self.prepareAudio = prepareAudio
    }

    public static func validate(_ speed: Float) throws {
        guard speed.isFinite, (0.5...2).contains(speed) else {
            throw PrototypeError("Speed must be a number from 0.5 to 2.0.")
        }
    }

    public func play(_ data: Data, volume: Float = 1) async throws {
        stop()
        guard !preparationWorkerBusy else { throw PrototypeError("Audio output is still unavailable. Check your output device and retry.") }
        try Task.checkCancellation()
        let id = UUID(); playbackID = id
        let prepared = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                preparation = continuation
                preparationWorkerBusy = true
                let prepare = prepareAudio
                // Core Audio device initialization can block; never perform it on the UI actor
                // or a Swift cooperative executor. Only one preparation may be outstanding.
                DispatchQueue.global(qos: .userInitiated).async {
                    let result = Result { try prepare(data) }
                    Task { @MainActor in
                        self.preparationWorkerBusy = false
                        self.timeoutTask?.cancel(); self.timeoutTask = nil
                        guard let waiting = self.preparation else {
                            if case .success(let abandoned) = result {
                                DispatchQueue.global(qos: .utility).async { abandoned.player.stop() }
                            }
                            return
                        }
                        self.preparation = nil
                        waiting.resume(with: result)
                    }
                }
                timeoutTask = Task {
                    do { try await Task.sleep(for: preparationTimeout) } catch { return }
                    guard let waiting = preparation else { return }
                    preparation = nil
                    waiting.resume(throwing: PrototypeError("Audio output timed out. Check your Mac’s output device, then retry."))
                }
            }
        } onCancel: {
            Task { @MainActor in if self.playbackID == id { self.cancelPreparation() } }
        }
        try Task.checkCancellation()
        guard playbackID == id else { throw CancellationError() }
        let next = prepared.player
        next.rate = speed; next.volume = volume
        guard next.play() else { throw PrototypeError("Audio playback could not start.") }
        player = next
    }

    private func cancelPreparation() {
        timeoutTask?.cancel(); timeoutTask = nil
        preparation?.resume(throwing: CancellationError()); preparation = nil
    }

    public func setSpeed(_ value: Float) throws {
        try Self.validate(value)
        speed = value
        ramp?.cancel()
        guard let player, player.isPlaying else { return }
        let initial = player.rate
        let started = now()
        // ponytail: a short main-actor ramp avoids a new DSP engine for the prototype.
        // This smooths control updates, not a sample-accurate acoustic guarantee.
        ramp = Task { @MainActor in
            while !Task.isCancelled {
                let fraction = min(1, Float((now() - started) / 0.15))
                let eased = fraction * fraction * (3 - 2 * fraction)
                player.rate = initial + (value - initial) * eased
                if fraction >= 1 { break }
                do { try await Task.sleep(for: .milliseconds(10)) }
                catch { break }
            }
        }
    }

    public func stop() {
        playbackID = nil
        cancelPreparation()
        ramp?.cancel()
        ramp = nil
        player?.stop()
        player = nil
    }

    public func pause() {
        ramp?.cancel()
        ramp = nil
        player?.pause()
    }

    public func resume() throws {
        guard let player else { throw PrototypeError("There is no speech to resume.") }
        player.rate = speed
        guard player.play() else { throw PrototypeError("Audio playback could not resume.") }
    }
}
