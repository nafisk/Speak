import Foundation
import SpeakCore
import Darwin

do {
    let args = Array(CommandLine.arguments.dropFirst())
    guard let command = args.first, let action = ControlRequest.Action(rawValue: command) else {
        throw ControlError("Usage: speakctl status|read|pause|resume|stop|speed NUMBER|toggleDictation|cancelDictation|open. Pipe text into read.")
    }
    guard args.count == (action == .speed ? 2 : 1) else { throw ControlError("Unexpected arguments. Pipe text through stdin for read.") }
    var text: String?
    if action == .read {
        guard isatty(STDIN_FILENO) == 0 else { throw ControlError("Pipe text into speakctl read.") }
        var data = Data()
        while data.count <= LocalControl.maximumMessageBytes {
            let part = try FileHandle.standardInput.read(upToCount: min(4096, LocalControl.maximumMessageBytes + 1 - data.count)) ?? Data()
            if part.isEmpty { break }; data.append(part)
        }
        guard data.count <= LocalControl.maximumMessageBytes, let decoded = String(data: data, encoding: .utf8) else { throw ControlError("Expected bounded UTF-8 text.") }
        text = decoded
    }
    let request = ControlRequest(action: action, text: text, speed: action == .speed ? Double(args[1]) : nil)
    let reply = try LocalControl.send(request)
    var output = try JSONEncoder().encode(reply); output.append(10); FileHandle.standardOutput.write(output)
    if !reply.ok { exit(1) }
} catch {
    FileHandle.standardError.write(Data((error.localizedDescription + "\n").utf8)); exit(1)
}
