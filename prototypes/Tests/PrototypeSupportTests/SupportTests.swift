import Testing
@testable import PrototypeSupport

@Test func latencyUsesNearestRank() {
    #expect(percentile([4, 1, 3, 2], 0.5) == 2)
    #expect(percentile(Array(1...20).map(Double.init), 0.95) == 19)
}

@Test func invalidOptionsFail() throws {
    #expect(throws: (any Error).self) { try Options(["--repeat"], valueNames: ["--repeat"], flagNames: []) }
    #expect(throws: (any Error).self) { try Options(["--wat"], valueNames: [], flagNames: []) }
    #expect(throws: (any Error).self) { try Options(["--mic", "--mic"], valueNames: [], flagNames: ["--mic"]) }
    let options = try Options(["--repeat", "0"], valueNames: ["--repeat"], flagNames: [])
    #expect(throws: (any Error).self) { try options.repeats() }
}

@Test func invalidAudioNeverReachesModel() {
    #expect(throws: (any Error).self) { try validateAudio([], sampleRate: 16000) }
    #expect(throws: (any Error).self) { try validateAudio(Array(repeating: 0, count: 16000), sampleRate: 16000) }
    #expect(throws: (any Error).self) { try validateAudio(Array(repeating: Float.nan, count: 16000), sampleRate: 16000) }
    #expect(throws: Never.self) { try validateAudio(Array(repeating: 0.1, count: 16000), sampleRate: 16000) }
}
