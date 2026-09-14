import Darwin
import Foundation
import Testing
@testable import SpeakCore

@Test func invalidControlRequestsAreRejected() throws {
    for value in [0.0, 2.1, .infinity, .nan] {
        #expect(throws: (any Error).self) { try ControlRequest(action: .speed, speed: value).validate() }
    }
    #expect(throws: (any Error).self) { try ControlRequest(action: .read, text: "  ").validate() }
    #expect(throws: (any Error).self) { try ControlRequest(action: .read, text: String(repeating: "x", count: 20001)).validate() }
    try ControlRequest(action: .read, text: "Literal $(text) and `quotes` 👋").validate()
    try ControlRequest(action: .speed, speed: 1.5).validate()
}

@Test func localControlRoundTripPreservesStructuredText() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("sp-\(UUID().uuidString.prefix(8))")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
    defer { try? FileManager.default.removeItem(at: directory) }
    let path = directory.appendingPathComponent("s.sock").path
    let listener = try LocalControl.listenSocket(path: path)
    defer { close(listener) }
    let server = Task.detached { () throws -> ControlRequest in
        let client = accept(listener, nil, nil)
        guard client >= 0 else { throw ControlError("Accept failed") }
        defer { close(client) }
        let request = try JSONDecoder().decode(ControlRequest.self, from: LocalControl.readLine(client))
        try request.validate()
        try LocalControl.writeLine(JSONEncoder().encode(ControlReply(ok: true, message: "accepted")), to: client)
        return request
    }
    let sample = "Literal $(text), `quotes`, and a newline\n👋"
    let reply = try LocalControl.send(ControlRequest(action: .read, text: sample), to: path)
    #expect(reply.ok)
    let received = try await server.value
    #expect(received.text == sample)
    let attributes = try FileManager.default.attributesOfItem(atPath: path)
    #expect((attributes[.posixPermissions] as? NSNumber)?.intValue == 0o600)
}

@Test func controlDoesNotReplaceUnexpectedFiles() throws {
    let file = FileManager.default.temporaryDirectory.appendingPathComponent("sp-\(UUID().uuidString.prefix(8))")
    try Data("keep".utf8).write(to: file)
    defer { try? FileManager.default.removeItem(at: file) }
    #expect(throws: (any Error).self) { try LocalControl.listenSocket(path: file.path) }
    #expect(try String(contentsOf: file, encoding: .utf8) == "keep")
}
