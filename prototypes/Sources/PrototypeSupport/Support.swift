import Foundation

public struct PrototypeError: LocalizedError {
    public let errorDescription: String?
    public init(_ message: String) { errorDescription = message }
}

public func note(_ message: String) {
    FileHandle.standardError.write(Data((message + "\n").utf8))
}

public func now() -> Double { ProcessInfo.processInfo.systemUptime }

public func emit(_ values: [String: Any]) throws {
    let data = try JSONSerialization.data(withJSONObject: values, options: [.sortedKeys])
    FileHandle.standardOutput.write(data)
    FileHandle.standardOutput.write(Data("\n".utf8))
}

public func percentile(_ values: [Double], _ fraction: Double) -> Double {
    precondition(!values.isEmpty && fraction > 0 && fraction <= 1)
    let sorted = values.sorted()
    return sorted[max(0, Int(ceil(Double(sorted.count) * fraction)) - 1)]
}

public func summary(_ seconds: [Double]) throws {
    // ponytail: first inference is kept separate; no statistical claims from one trial.
    let warm = Array(seconds.dropFirst())
    guard !warm.isEmpty else { return }
    try emit(["event": "warm_summary", "trials": warm.count,
              "median_seconds": percentile(warm, 0.5), "p95_seconds": percentile(warm, 0.95)])
}

public struct Options {
    public var values: [String: String] = [:]
    public var flags: Set<String> = []
    public init(_ arguments: [String], valueNames: Set<String>, flagNames: Set<String>) throws {
        var i = 0
        while i < arguments.count {
            let key = arguments[i]
            guard values[key] == nil && !flags.contains(key) else { throw PrototypeError("Duplicate option: \(key)") }
            if flagNames.contains(key) { flags.insert(key) }
            else if valueNames.contains(key) {
                i += 1
                guard i < arguments.count else { throw PrototypeError("Missing value for \(key)") }
                values[key] = arguments[i]
            } else { throw PrototypeError("Unknown option: \(key). Use --help.") }
            i += 1
        }
    }
    public func repeats() throws -> Int {
        guard let count = Int(values["--repeat"] ?? "1"), (1...101).contains(count) else {
            throw PrototypeError("--repeat must be 1...101 (first inference plus warm trials).")
        }
        return count
    }
}

public func validateAudio(_ samples: [Float], sampleRate: Double) throws {
    guard sampleRate > 0, samples.count >= Int(sampleRate * 0.25), samples.count <= Int(sampleRate * 120),
          samples.allSatisfy({ $0.isFinite }) else {
        throw PrototypeError("Use finite audio between 0.25 and 120 seconds long.")
    }
    guard samples.contains(where: { abs($0) > 0.0001 }) else {
        throw PrototypeError("Audio is silent or too quiet; no transcript produced.")
    }
}
