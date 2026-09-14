import Foundation

public enum DictationFormat: String {
    case plain
    case lists

    public func apply(to transcript: String) -> String {
        guard self == .lists else { return transcript }
        // ponytail: explicit reserved phrases avoid an extra inference model and prose rewriting.
        // Only complete, non-nested lists are changed. Natural-language inference is deferred.
        let pattern = #"(?i)\b(start (?:a )?list|next item|end (?:the )?list)\b[\s.,:;!?]*"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let source = transcript as NSString
        let matches = regex.matches(in: transcript, range: NSRange(location: 0, length: source.length))
        var start: Int?
        var contentStart = 0
        var items: [String] = []
        var replacements: [(NSRange, String)] = []
        var invalid = false
        let whitespace = CharacterSet.whitespacesAndNewlines
        let itemTrim = whitespace.union(CharacterSet(charactersIn: ",:;"))

        for match in matches {
            let cue = source.substring(with: match.range(at: 1)).lowercased()
            if cue.hasPrefix("start") {
                if start != nil { invalid = true; continue }
                start = match.range.location
                contentStart = NSMaxRange(match.range)
                items = []
                invalid = false
            } else if let listStart = start {
                let item = source.substring(with: NSRange(location: contentStart, length: match.range.location - contentStart))
                    .trimmingCharacters(in: itemTrim)
                if item.isEmpty { invalid = true }
                items.append(item)
                contentStart = NSMaxRange(match.range)
                if cue.hasPrefix("end") {
                    if !invalid {
                        let bullets = items.map { "- " + $0 }.joined(separator: "\n")
                        replacements.append((NSRange(location: listStart, length: contentStart - listStart), bullets))
                    }
                    start = nil
                }
            }
        }
        guard !replacements.isEmpty else { return transcript }
        var sections: [String] = []
        var cursor = 0
        for (range, bullets) in replacements {
            let prose = source.substring(with: NSRange(location: cursor, length: range.location - cursor))
                .trimmingCharacters(in: whitespace)
            if !prose.isEmpty { sections.append(prose) }
            sections.append(bullets)
            cursor = NSMaxRange(range)
        }
        let tail = source.substring(from: cursor).trimmingCharacters(in: whitespace)
        if !tail.isEmpty { sections.append(tail) }
        return sections.joined(separator: "\n\n")
    }
}
