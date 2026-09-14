import Testing
@testable import PrototypeSupport

@Test func explicitListBecomesBullets() {
    #expect(DictationFormat.lists.apply(to: "Start a list. Apples. Next item. Bananas. End list.") == "- Apples.\n- Bananas.")
    #expect(DictationFormat.lists.apply(to: "Start list apples next item bananas end the list") == "- apples\n- bananas")
    #expect(DictationFormat.lists.apply(to: "Start a list, café, next item, naïve 🍎, end list.") == "- café\n- naïve 🍎")
}

@Test func plainAndIncompleteSpeechArePreserved() {
    for text in ["First we met, and second we went home.", "Start list apples next item bananas", "Start list next item apples end list", "Start list apples start list bananas end list end list"] {
        #expect(DictationFormat.lists.apply(to: text) == text)
    }
    let text = "Start list apples next item bananas end list."
    #expect(DictationFormat.plain.apply(to: text) == text)
}

@Test func proseAroundListsIsPreserved() {
    let result = DictationFormat.lists.apply(to: "Shopping. Start list apples next item pears end list. Thank you.")
    #expect(result == "Shopping.\n\n- apples\n- pears\n\nThank you.")
    let multiple = DictationFormat.lists.apply(to: "Start list apples end list. Start list pears end list.")
    #expect(multiple == "- apples\n\n- pears")
}
