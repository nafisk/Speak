import Darwin
import Foundation

public struct ControlRequest: Codable, Sendable {
    public enum Action: String, Codable, Sendable { case status, read, pause, resume, stop, speed, toggleDictation, cancelDictation, open }
    public let action: Action
    public let text: String?
    public let speed: Double?
    public init(action: Action, text: String? = nil, speed: Double? = nil) { self.action = action; self.text = text; self.speed = speed }
    public func validate() throws {
        if action == .read { guard let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, text.count <= 20000 else { throw ControlError("Read expects 1–20,000 characters.") } }
        if action == .speed { guard let speed, speed.isFinite, (0.5...2).contains(speed) else { throw ControlError("Speed must be 0.5–2.0.") } }
    }
}
public struct ControlReply: Codable, Sendable {
    public var ok: Bool
    public var message: String
    public var reading: Bool
    public var paused: Bool
    public var speed: Double
    public var dictation: String
    public init(ok: Bool, message: String, reading: Bool = false, paused: Bool = false, speed: Double = 1, dictation: String = "idle") {
        self.ok = ok; self.message = message; self.reading = reading; self.paused = paused; self.speed = speed; self.dictation = dictation
    }
}
public struct ControlError: LocalizedError, Sendable {
    public let errorDescription: String?
    public init(_ message: String) { errorDescription = message }
}

/// A user-only Unix socket. No HTTP listener, accounts, or remote network endpoint.
public enum LocalControl {
    public static let maximumMessageBytes = 256_000
    public static func path() throws -> String {
        let base = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("Speak", isDirectory: true)
        if !FileManager.default.fileExists(atPath: base.path) {
            try FileManager.default.createDirectory(at: base, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        }
        var info = stat()
        guard lstat(base.path, &info) == 0, info.st_mode & S_IFMT == S_IFDIR, info.st_uid == getuid(), info.st_mode & 0o077 == 0 else {
            throw ControlError("Speak's control directory must be owned by you with mode 700.")
        }
        return base.appendingPathComponent("control.sock").path
    }
    private static func address(_ path: String) throws -> sockaddr_un {
        var value = sockaddr_un(); value.sun_family = sa_family_t(AF_UNIX)
        value.sun_len = UInt8(MemoryLayout<sockaddr_un>.size)
        let bytes = Array(path.utf8) + [0]
        guard bytes.count <= MemoryLayout.size(ofValue: value.sun_path) else { throw ControlError("Control socket path is too long.") }
        withUnsafeMutableBytes(of: &value.sun_path) { $0.copyBytes(from: bytes) }
        return value
    }
    public static func makeSocket() throws -> Int32 {
        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { throw ControlError("Could not create local control socket.") }
        var timeout = timeval(tv_sec: 3, tv_usec: 0); var one: Int32 = 1
        setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
        setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
        setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &one, socklen_t(MemoryLayout<Int32>.size))
        return fd
    }
    private static func connectSocket(_ fd: Int32, path: String) throws -> Int32 {
        var value = try address(path)
        return withUnsafePointer(to: &value) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { connect(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size)) }
        }
    }
    public static func listenSocket(path: String) throws -> Int32 {
        let fd = try makeSocket()
        do {
            var info = stat()
            if lstat(path, &info) == 0 {
                guard info.st_mode & S_IFMT == S_IFSOCK, info.st_uid == getuid() else { throw ControlError("Refusing to replace an unexpected control file.") }
                let probe = try makeSocket(); let active = try connectSocket(probe, path: path) == 0; close(probe)
                guard !active else { throw ControlError("Speak is already running.") }
                guard unlink(path) == 0 else { throw ControlError("Could not remove a stale control socket.") }
            }
            var value = try address(path)
            let bound = withUnsafePointer(to: &value) { pointer in
                pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size)) }
            }
            guard bound == 0, chmod(path, 0o600) == 0, listen(fd, 4) == 0 else { throw ControlError("Could not start local control listener.") }
            return fd
        } catch { close(fd); throw error }
    }
    public static func readLine(_ fd: Int32) throws -> Data {
        var result = Data(); var buffer = [UInt8](repeating: 0, count: 4096)
        while result.count <= maximumMessageBytes {
            let count = recv(fd, &buffer, buffer.count, 0)
            guard count > 0 else { throw ControlError("Local control connection ended or timed out.") }
            if let newline = buffer[..<count].firstIndex(of: 10) { result.append(contentsOf: buffer[..<newline]); guard result.count <= maximumMessageBytes else { break }; return result }
            result.append(contentsOf: buffer[..<count])
        }
        throw ControlError("Control message is too large.")
    }
    public static func writeLine(_ data: Data, to fd: Int32) throws {
        guard data.count <= maximumMessageBytes else { throw ControlError("Control message is too large.") }
        var payload = data; payload.append(10)
        try payload.withUnsafeBytes { bytes in
            var sent = 0
            while sent < bytes.count {
                let count = Darwin.send(fd, bytes.baseAddress!.advanced(by: sent), bytes.count - sent, 0)
                guard count > 0 else { throw ControlError("Could not write local control message.") }
                sent += count
            }
        }
    }
    public static func send(_ request: ControlRequest, to path: String? = nil) throws -> ControlReply {
        try request.validate()
        let endpoint = try path ?? Self.path()
        let fd = try makeSocket(); defer { close(fd) }
        guard try connectSocket(fd, path: endpoint) == 0 else { throw ControlError("Open Speak first, then retry.") }
        var uid: uid_t = 0; var gid: gid_t = 0
        guard getpeereid(fd, &uid, &gid) == 0, uid == getuid() else { throw ControlError("Unexpected control socket owner.") }
        try writeLine(JSONEncoder().encode(request), to: fd)
        return try JSONDecoder().decode(ControlReply.self, from: readLine(fd))
    }
}
