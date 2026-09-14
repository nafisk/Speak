import Foundation
import Testing
@testable import SpeakCore

@Test func cancelledAndReplacedSessionsCannotInsert() {
    var session = DictationSession()
    let first = session.begin()!
    let result1 = session.begin() == nil
    #expect(result1)
    let result2 = !session.transition(first, to: .inserted)
    #expect(result2)
    let result3 = session.transition(first, to: .recording)
    #expect(result3)
    let result4 = session.transition(first, to: .transcribing)
    #expect(result4)
    session.cancel()
    let second = session.begin()!
    let result5 = !session.transition(first, to: .inserted)
    #expect(result5)
    #expect(session.isCurrent(second))
    #expect(session.phase == .preparing)
}
@Test func oneInsertionPerSession() {
    var session = DictationSession(); let token = session.begin()!
    let result6 = session.transition(token, to: .recording)
    #expect(result6)
    let result7 = session.transition(token, to: .transcribing)
    #expect(result7)
    let result8 = session.transition(token, to: .inserted)
    #expect(result8)
    let result9 = !session.transition(token, to: .inserted)
    #expect(result9)
}
@Test func chunkingPreservesTextAndBounds() {
    for text in [String(repeating: "hello world. ", count: 100), String(repeating: "👨‍👩‍👦", count: 500), String(repeating: "a", count: 501), "One.\nTwo. Three!"] {
        let chunks = ReaderText.chunks(text)
        #expect(chunks.allSatisfy { !$0.isEmpty && $0.count <= 240 })
        #expect(chunks.joined() == text.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    #expect(ReaderText.chunks("   ").isEmpty)
}
@Test func insertionRangeUsesUTF16AndRejectsInvalidRanges() {
    let field = FieldSnapshot(process: 1, value: "Hi 👋 friend", location: 3, length: 2)
    #expect(field.replacement("there") == "Hi there friend")
    #expect(FieldSnapshot(process: 1, value: "hello", location: 6, length: 0).replacement("x") == nil)
    #expect(FieldSnapshot(process: 1, value: "hello", location: 4, length: 2).replacement("x") == nil)
    #expect(field != FieldSnapshot(process: 2, value: field.value, location: 3, length: 2))
}
