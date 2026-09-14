import AVFoundation
import Foundation

/// A single playing utterance. Rate changes never replace, seek, or restart its player.
@MainActor public final class SpeechPlayback {
    private var player: AVAudioPlayer?
    private var ramp: Task<Void, Never>?
    public private(set) var speed: Float
    public var isPlaying: Bool { player?.isPlaying ?? false }
    public var position: TimeInterval { player?.currentTime ?? 0 }
    public var currentRate: Float { player?.rate ?? speed }

    public init(speed: Float = 1) throws {
        try Self.validate(speed)
        self.speed = speed
    }

    public static func validate(_ speed: Float) throws {
        guard speed.isFinite, (0.5...2).contains(speed) else {
            throw PrototypeError("Speed must be a number from 0.5 to 2.0.")
        }
    }

    public func play(_ data: Data, volume: Float = 1) throws {
        let next = try AVAudioPlayer(data: data)
        next.enableRate = true
        next.rate = speed
        next.volume = volume
        next.prepareToPlay()
        stop()
        guard next.play() else { throw PrototypeError("Audio playback could not start.") }
        player = next
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
        ramp?.cancel()
        ramp = nil
        player?.stop()
        player = nil
    }
}
