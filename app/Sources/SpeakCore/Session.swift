import Foundation

public enum DictationPhase: String, Sendable {
    case idle, preparing, recording, transcribing, inserted, recovery
}

/// Identity gates every asynchronous completion, including work cancelled during model calls.
public struct DictationSession: Sendable {
    public private(set) var id: UUID?
    public private(set) var phase: DictationPhase = .idle
    public init() {}
    public mutating func begin() -> UUID? {
        guard [.idle, .inserted, .recovery].contains(phase) else { return nil }
        let next = UUID(); id = next; phase = .preparing; return next
    }
    public func isCurrent(_ token: UUID) -> Bool { id == token }
    @discardableResult public mutating func transition(_ token: UUID, to next: DictationPhase) -> Bool {
        guard id == token else { return false }
        let allowed: Bool
        switch (phase, next) {
        case (.preparing, .recording), (.recording, .transcribing), (.transcribing, .inserted): allowed = true
        case (.preparing, .recovery), (.recording, .recovery), (.transcribing, .recovery): allowed = true
        default: allowed = false
        }
        guard allowed else { return false }
        phase = next; return true
    }
    public mutating func cancel() { id = nil; phase = .idle }
}

public enum ReaderText {
    /// Bound model input by characters without splitting grapheme clusters or dropping whitespace.
    public static func chunks(_ text: String, limit: Int = 240) -> [String] {
        guard limit > 0 else { return [] }
        var rest = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var result: [String] = []
        while !rest.isEmpty {
            if rest.count <= limit { result.append(rest); break }
            let cap = rest.index(rest.startIndex, offsetBy: limit)
            let prefix = rest[..<cap]
            let boundary = prefix.lastIndex(where: { ".!?\n".contains($0) })
                ?? prefix.lastIndex(where: { $0.isWhitespace })
            let end = boundary.map { rest.index(after: $0) } ?? cap
            result.append(String(rest[..<end]))
            rest = String(rest[end...])
        }
        return result
    }
}

public struct FieldSnapshot: Equatable, Sendable {
    public let process: Int32
    public let value: String
    public let location: Int
    public let length: Int
    public init(process: Int32, value: String, location: Int, length: Int) {
        self.process = process; self.value = value; self.location = location; self.length = length
    }
    public func replacement(_ text: String) -> String? {
        let source = value as NSString
        guard location >= 0, length >= 0, location <= source.length, length <= source.length - location else { return nil }
        return source.replacingCharacters(in: NSRange(location: location, length: length), with: text)
    }
}
